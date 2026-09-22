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

  Future<Map<String, String>> _buildHeaders({bool isJson = true, bool forceRefresh = false}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }

    // Attach Token (check Firebase first, fallback to SecureStorage, keep synced)
    String? token;
    try {
      token = await _firebaseService.getIdToken(forceRefresh: forceRefresh);
      if (token != null && token.isNotEmpty) {
        await _secureStorage.saveTokens(accessToken: token);
      } else {
        token = await _secureStorage.getAccessToken();
      }
    } catch (_) {
      try {
        token = await _secureStorage.getAccessToken();
      } catch (_) {}
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Sends an HTTP request and automatically attempts token refresh and retry once if 401/403 occurs.
  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function(Map<String, String> headers) requestFn, {
    bool isJson = true,
  }) async {
    var headers = await _buildHeaders(isJson: isJson);
    var response = await requestFn(headers).timeout(ApiConfig.timeoutDuration);

    if (response.statusCode == 401 || response.statusCode == 403) {
      // Force token refresh from Firebase and retry request once
      try {
        final retryHeaders = await _buildHeaders(isJson: isJson, forceRefresh: true);
        if (retryHeaders.containsKey('Authorization')) {
          response = await requestFn(retryHeaders).timeout(ApiConfig.timeoutDuration);
        }
      } catch (_) {}
    }

    return response;
  }

  /// GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
        uri = uri.replace(queryParameters: stringParams);
      }

      final response = await _sendWithRetry(
        (headers) => http.get(uri, headers: headers),
        isJson: true,
      );
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
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _sendWithRetry(
        (headers) => http.post(uri, headers: headers, body: encodedBody),
        isJson: true,
      );

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
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _sendWithRetry(
        (headers) => http.patch(uri, headers: headers, body: encodedBody),
        isJson: true,
      );

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
      final response = await _sendWithRetry(
        (headers) => http.delete(uri, headers: headers),
        isJson: true,
      );

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

      Future<http.Response> executeMultipart(Map<String, String> hdrs) async {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(hdrs);
        if (fields != null) request.fields.addAll(fields);
        final multipartFile = await http.MultipartFile.fromPath(fileField, file.path);
        request.files.add(multipartFile);
        final streamed = await request.send().timeout(const Duration(seconds: 45));
        return await http.Response.fromStream(streamed);
      }

      var headers = await _buildHeaders(isJson: false);
      var response = await executeMultipart(headers);

      if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final retryHeaders = await _buildHeaders(isJson: false, forceRefresh: true);
          if (retryHeaders.containsKey('Authorization')) {
            response = await executeMultipart(retryHeaders);
          }
        } catch (_) {}
      }

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
