import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme/app_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Face Attendance Settings',
      backLabel: '',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============== LANGUAGE SECTION ==============
            _SectionLabel('LANGUAGE / ភាសា'),
            const SizedBox(height: 8),
            Container(
              decoration: appleCardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: GetBuilder<SettingsController>(
                builder: (ctrl) => Column(
                  children: [
                    _LanguageTile(
                      title: 'settings_language_english'.tr,
                      subtitle: 'English (US)',
                      isSelected: !ctrl.isKhmer,
                      onTap: () => ctrl.changeLanguageToEnglish(),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _LanguageTile(
                      title: 'settings_language_khmer'.tr,
                      subtitle: 'ខ្មែរ (Khmer)',
                      isSelected: ctrl.isKhmer,
                      onTap: () => ctrl.changeLanguageToKhmer(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'App content and interface language',
                style: TextStyle(
                  fontSize: 12,
                  color: RequestColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ============== ABOUT SECTION ==============
            _SectionLabel('ABOUT'),
            const SizedBox(height: 8),
            Container(
              decoration: appleCardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _AboutRow(
                    title: 'settings_version'.tr,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '1.0.0 (Build 42)',
                          style: TextStyle(
                            fontSize: 14,
                            color: RequestColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: RequestColors.approvedStatus.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Latest',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.approvedStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _AboutRow(
                    title: 'Terms of Service',
                    showChevron: true,
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _AboutRow(
                    title: 'Privacy Policy',
                    showChevron: true,
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _AboutRow(
                    title: 'Support & Documentation',
                    showChevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Column(
                children: [
                  const Icon(
                    FluentIcons.qr_code_24_regular,
                    size: 26,
                    color: RequestColors.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Face Attendance Security Suite',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${DateTime.now().year} All rights reserved.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: RequestColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: RequestColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                FluentIcons.checkmark_24_regular,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.title,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final String title;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: RequestColors.textPrimary,
                ),
              ),
            ),
            ?trailing,
            if (showChevron)
              const Icon(
                FluentIcons.chevron_right_24_regular,
                size: 20,
                color: RequestColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
