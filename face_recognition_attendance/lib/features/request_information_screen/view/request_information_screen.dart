import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Request Information" menu: Unauthorized (pending) and Authorized (approved).
class RequestInformationScreen extends StatelessWidget {
  const RequestInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Request Information',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RequestMenuCard(
            icon: Icons.hourglass_top_rounded,
            iconBackground: const Color(0xFFD08A2E),
            title: 'Unauthorized',
            subtitle: 'Pending Request',
            onTap: () => Get.toNamed(AppRoutes.requestUnauthorized),
          ),
          const SizedBox(height: 12),
          RequestMenuCard(
            icon: Icons.fact_check_outlined,
            iconBackground: const Color(0xFF4CB84B),
            title: 'Authorized',
            subtitle: 'Completed Request',
            onTap: () => Get.toNamed(AppRoutes.requestAuthorized),
          ),
        ],
      ),
    );
  }
}
