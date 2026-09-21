import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme/app_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ============== LANGUAGE SECTION ==============
            _buildSectionHeader('settings_language'.tr),
            _buildLanguageSelector(context),

            const Divider(),

            // ============== ABOUT SECTION ==============
            _buildSectionHeader('settings_about'.tr),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Get.textTheme.titleLarge,
        ),
      ),
    );
  }


  Widget _buildLanguageSelector(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (controller) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildLanguageTile(
                title: 'settings_language_english'.tr,
                isSelected: !controller.isKhmer,
                onTap: () => controller.changeLanguageToEnglish(),
              ),
              _buildLanguageTile(
                title: 'settings_language_khmer'.tr,
                isSelected: controller.isKhmer,
                onTap: () => controller.changeLanguageToKhmer(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text('settings_version'.tr),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }


  Widget _buildLanguageTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
      selected: isSelected,
    );
  }
}
