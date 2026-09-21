import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageService extends GetxService {
  static const String _languageKey = 'app_language';

  final _storage = GetStorage();
  final _locale = const Locale('en', 'US').obs;

  Locale get locale => _locale.value;

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  /// Load language from storage
  void _loadLanguage() {
    final savedLanguage = _storage.read(_languageKey) as String?;
    if (savedLanguage == 'km_KH') {
      _locale.value = const Locale('km', 'KH');
    } else {
      _locale.value = const Locale('en', 'US');
    }
  }

  /// Change language to English
  Future<void> setEnglish() async {
    _locale.value = const Locale('en', 'US');
    await Get.updateLocale(const Locale('en', 'US'));
    await _storage.write(_languageKey, 'en_US');
  }

  /// Change language to Khmer
  Future<void> setKhmer() async {
    _locale.value = const Locale('km', 'KH');
    await Get.updateLocale(const Locale('km', 'KH'));
    await _storage.write(_languageKey, 'km_KH');
  }

  /// Get current language code
  String get currentLanguageCode => _locale.value.languageCode;

  /// Check if Khmer is selected
  bool get isKhmer => _locale.value.languageCode == 'km';
}
