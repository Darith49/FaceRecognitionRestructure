import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:face_recognition_attendance/core/config/api_config.dart';
import 'package:face_recognition_attendance/core/service/firebase_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

class ApiService {
  final FirebaseService _firebaseService = FirebaseService();
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<Map<String, String>> _buildHeaders({bool isJson = true}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }

    // Attach Token (check Firebase first, fallback to SecureStorage, keep synced)
    try {
      String? token = await _firebaseService.getIdToken();
      if (token != null && token.isNotEmpty) {
        _secureStorage.saveTokens(accessToken: token);
      } else {
        token = await _secureStorage.getAccessToken();
      }

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      try {
        final token = await _secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
    }

    return headers;
  }

  /// GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
        uri = uri.replace(queryParameters: stringParams);
      }

      final headers = await _buildHeaders();
      final response = await http.get(uri, headers: headers).timeout(ApiConfig.timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Cannot connect to server. Please check your network connection.');
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  /// POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(isJson: true);
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Cannot connect to server. Please check your network connection.');
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  /// PATCH request
  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(isJson: true);
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Cannot connect to server. Please check your network connection.');
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(isJson: true);
      final response = await http.delete(uri, headers: headers).timeout(ApiConfig.timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Cannot connect to server. Please check your network connection.');
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Multipart POST request (for image uploads like face registration and attendance)
  Future<dynamic> postMultipart(
    String endpoint, {
    required File file,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Attach headers (Authorization)
      final headers = await _buildHeaders(isJson: false);
      request.headers.addAll(headers);

      // Add text fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(fileField, file.path);
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Cannot connect to server. Please check your network connection.');
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Upload error: ${e.toString()}');
    }
  }

  /// Unified response processor and error extractor
  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Extract error message
    String errorMessage = 'Request failed with status ${response.statusCode}.';
    if (body is Map) {
      if (body.containsKey('error')) {
        errorMessage = body['error'].toString();
      } else if (body.containsKey('message')) {
        errorMessage = body['message'].toString();
      } else if (body.containsKey('detail')) {
        errorMessage = body['detail'].toString();
      } else {
        // Collect first validation error message if present
        final firstKey = body.keys.firstOrNull;
        if (firstKey != null) {
          final val = body[firstKey];
          if (val is List && val.isNotEmpty) {
            errorMessage = '${firstKey.toString().replaceAll('_', ' ').toUpperCase()}: ${val.first}';
          } else {
            errorMessage = '${firstKey.toString().replaceAll('_', ' ')}: $val';
          }
        }
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      details: body,
    );
  }
}
