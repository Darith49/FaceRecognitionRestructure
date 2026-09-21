import 'package:face_recognition_attendance/features/Overtime_screen/view/request_overtime_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overtime route: delegates to the unified Apple-designed [RequestOvertimeScreen]
/// with the Request Overtime tab pre-selected, supporting pending edit requests if passed.
class OvertimeListScreen extends StatelessWidget {
  const OvertimeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final editId = args is String ? args : null;
    return RequestOvertimeScreen(initialTab: 0, editId: editId);
  }
}
