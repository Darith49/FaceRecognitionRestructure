import 'package:get/get.dart';
import '../../../core/services/language_service.dart';

class SettingsController extends GetxController {
  late final LanguageService _languageService;

  @override
  void onInit() {
    super.onInit();
    _languageService = Get.find<LanguageService>();
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
