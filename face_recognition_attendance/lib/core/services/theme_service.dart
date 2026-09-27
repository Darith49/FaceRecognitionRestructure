import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../config/theme/app_theme.dart';

class ThemeService extends GetxService {
  static const String _themeKey = 'app_theme_mode';

  final _storage = GetStorage();
  final _themeMode = ThemeMode.light.obs;

  ThemeMode get themeMode => _themeMode.value;

  bool get isSystemMode => _themeMode.value == ThemeMode.system;
  bool get isLightMode => _themeMode.value == ThemeMode.light;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  /// Returns true if the device / OS is currently set to dark brightness.
  bool get isPlatformDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  /// Returns true if the rendered appearance is dark.
  /// Light mode is NEVER dark. Dark mode is ALWAYS dark. System follows platform.
  bool get isActualDark {
    if (_themeMode.value == ThemeMode.dark) return true;
    if (_themeMode.value == ThemeMode.light) return false;
    return isPlatformDark;
  }

  /// Active ThemeData corresponding to current state
  ThemeData get effectiveThemeData =>
      isActualDark ? AppTheme.darkTheme : AppTheme.lightTheme;

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
    } else if (savedTheme == 'system') {
      _themeMode.value = ThemeMode.system;
    } else {
      _themeMode.value = ThemeMode.light;
    }
  }

  /// Change theme mode, apply ThemeData immediately, and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    await _storage.write(_themeKey, mode.name);

    // Apply the active ThemeData and ThemeMode across GetX
    Get.changeTheme(effectiveThemeData);
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
