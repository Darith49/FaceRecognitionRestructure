import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/theme_service.dart';

class SettingsController extends GetxController {
  late final LanguageService _languageService;
  late final ThemeService _themeService;

  @override
  void onInit() {
    super.onInit();
    _languageService = Get.find<LanguageService>();
    _themeService = Get.find<ThemeService>();
  }

  // ============== THEME ==============
  ThemeMode get currentThemeMode => _themeService.themeMode;
  bool get isSystemMode => _themeService.isSystemMode;
  bool get isLightMode => _themeService.isLightMode;
  bool get isDarkMode => _themeService.isDarkMode;
  bool get isActualDark => _themeService.isActualDark;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeService.setThemeMode(mode);
    update();
  }

  Future<void> changeThemeToSystem() async {
    await _themeService.setSystemMode();
    update();
  }

  Future<void> changeThemeToLight() async {
    await _themeService.setLightMode();
    update();
  }

  Future<void> changeThemeToDark() async {
    await _themeService.setDarkMode();
    update();
  }

  // ============== LANGUAGE ==============
  bool get isKhmer => _languageService.isKhmer;

  Future<void> changeLanguageToEnglish() async {
    await _languageService.setEnglish();
    update();
  }

  Future<void> changeLanguageToKhmer() async {
    await _languageService.setKhmer();
    update();
  }
}
