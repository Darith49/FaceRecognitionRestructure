import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Set your computer's LAN IP address when testing on a physical mobile device.
  // When running on Android Emulator, use '10.0.2.2'.
  // When running on iOS Simulator or Web/Desktop, use '127.0.0.1'.
  static String serverHost = '10.0.2.2';
  static int serverPort = 8000;

  /// Returns the base URL for the Django REST API (v1).
  // static String get baseUrl => 'http://$serverHost:$serverPort/api/v1';
  static String get baseUrl => 'https://alive-ultimately-bathroom-forgotten.trycloudflare.com/api/v1';

  /// Request timeout
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Helper to auto-configure localhost based on platform if needed
  static void useLocalhost() {
    if (!kIsWeb && Platform.isAndroid) {
      serverHost = '10.0.2.2';
    } else {
      serverHost = '127.0.0.1';
    }
  }

  /// Helper to configure Android emulator
  static void useAndroidEmulator() {
    serverHost = '10.0.2.2';
  }

  /// Helper to configure iOS Simulator or Desktop
  static void useSimulator() {
    serverHost = '127.0.0.1';
  }
}
