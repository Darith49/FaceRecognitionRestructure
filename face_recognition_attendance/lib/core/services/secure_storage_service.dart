import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service
/// Manages encrypted storage for sensitive authentication tokens and session data.
/// Uses Android Keystore (encryptedSharedPreferences) and iOS Keychain.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage Keys
  static const String _keyAccessToken = 'sec_access_token';
  static const String _keyRefreshToken = 'sec_refresh_token';
  static const String _keyUserUid = 'sec_user_uid';
  static const String _keyUserEmail = 'sec_user_email';
  static const String _keyUserData = 'sec_user_data';

  /// Save access and optional refresh token securely
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  /// Retrieve stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Retrieve stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Save full user session (tokens + profile) for offline & instant launch
  Future<void> saveUserSession({
    required String uid,
    required String email,
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _storage.write(key: _keyUserUid, value: uid);
    await _storage.write(key: _keyUserEmail, value: email);
    if (userData != null) {
      await _storage.write(key: _keyUserData, value: jsonEncode(userData));
    }
  }

  /// Retrieve saved user UID
  Future<String?> getSavedUid() async {
    return await _storage.read(key: _keyUserUid);
  }

  /// Retrieve saved user email
  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Retrieve cached user data map
  Future<Map<String, dynamic>?> getCachedUserData() async {
    final raw = await _storage.read(key: _keyUserData);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if user has an active saved session
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final uid = await getSavedUid();
    return token != null && token.isNotEmpty && uid != null && uid.isNotEmpty;
  }

  /// Clear all stored tokens and session data (used on logout)
  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserUid);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserData);
  }
}
