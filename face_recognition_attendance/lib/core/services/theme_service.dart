import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService extends GetxService {
  static const String _themeKey = 'app_theme_mode';

  final _storage = GetStorage();
  final _themeMode = ThemeMode.system.obs;

  ThemeMode get themeMode => _themeMode.value;

  bool get isSystemMode => _themeMode.value == ThemeMode.system;
  bool get isLightMode => _themeMode.value == ThemeMode.light;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  /// Returns true if the device / OS is currently set to dark brightness.
  bool get isPlatformDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  /// Returns true if the rendered appearance is dark (either explicit Dark or System + dark platform).
  bool get isActualDark =>
      isDarkMode || (isSystemMode && isPlatformDark);

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  /// Load theme mode from local persistent storage
  void _loadTheme() {
    final savedTheme = _storage.read(_themeKey) as String?;
    if (savedTheme == 'dark') {
      _themeMode.value = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode.value = ThemeMode.light;
    } else {
      _themeMode.value = ThemeMode.system;
    }
  }

  /// Change theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    await _storage.write(_themeKey, mode.name);
    Get.changeThemeMode(mode);
    Get.forceAppUpdate();
  }

  /// Convenience setters
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// Human-readable name for display
  String get themeModeName {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
