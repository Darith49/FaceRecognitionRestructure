import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Request Information" menu: Unauthorized (pending) and Authorized (approved).
class RequestInformationScreen extends StatelessWidget {
  const RequestInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Request Information'.tr,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RequestMenuCard(
            icon: FluentIcons.hourglass_half_24_regular,
            iconBackground: const Color(0xFFD08A2E),
            title: 'Unauthorized'.tr,
            subtitle: 'Pending Request'.tr,
            onTap: () => Get.toNamed(AppRoutes.requestUnauthorized),
          ),
          const SizedBox(height: 12),
          RequestMenuCard(
            icon: FluentIcons.checkmark_circle_24_regular,
            iconBackground: const Color(0xFF4CB84B),
            title: 'Authorized'.tr,
            subtitle: 'Completed Request'.tr,
            onTap: () => Get.toNamed(AppRoutes.requestAuthorized),
          ),
        ],
      ),
    );
  }
}
