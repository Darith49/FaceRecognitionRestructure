import 'package:face_recognition_attendance/features/suggestion_screen/controller/suggestion_controller.dart';
import 'package:get/get.dart';

/// Both Suggestion pages (form + status list) share ONE controller,
/// so a submitted / edited / reviewed suggestion shows up on both right away.
class SuggestionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SuggestionController>()) {
      Get.put<SuggestionController>(SuggestionController(), permanent: true);
    }
  }
}
