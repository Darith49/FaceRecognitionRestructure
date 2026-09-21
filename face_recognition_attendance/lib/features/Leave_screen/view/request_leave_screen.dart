import 'package:face_recognition_attendance/features/Leave_screen/view/leave_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Request Leave route: delegates to the unified Apple-designed [LeaveScreen]
/// with the Request Leave tab pre-selected, supporting pending edit requests if passed.
class RequestLeaveScreen extends StatelessWidget {
  const RequestLeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final editId = args is String ? args : null;
    return LeaveScreen(initialTab: 0, editId: editId);
  }
}
