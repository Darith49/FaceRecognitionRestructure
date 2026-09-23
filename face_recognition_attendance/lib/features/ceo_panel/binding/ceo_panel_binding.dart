import 'package:face_recognition_attendance/features/ceo_panel/controller/ceo_panel_controller.dart';
import 'package:get/get.dart';

class CeoPanelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CeoPanelController>(() => CeoPanelController());
  }
}
