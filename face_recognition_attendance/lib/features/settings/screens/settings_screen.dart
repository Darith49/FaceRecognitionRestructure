import 'package:face_recognition_attendance/config/routes/app_routes.dart';
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
    return GetBuilder<SettingsController>(
      key: ValueKey(
        '${Get.locale?.toString()}_${controller.currentThemeMode.name}',
      ),
      builder: (ctrl) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final dividerColor = isDark ? AppColors.darkDivider : AppColors.dividerSoft;
        final captionColor = isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary;

        return RequestScaffold(
          title: 'Face Attendance Settings'.tr,
          backLabel: '',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============== APPEARANCE / DARK MODE SECTION ==============
                const _SectionLabel('APPEARANCE / រូបរាង'),
                const SizedBox(height: 8),
                Container(
                  decoration: appleCardDecoration(context: context),
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Row(
                    children: [
                      _ThemePreviewCard(
                        title: 'System'.tr,
                        mode: ThemeMode.system,
                        isSelected: ctrl.isSystemMode,
                        onTap: () => ctrl.changeThemeToSystem(),
                      ),
                      const SizedBox(width: 10),
                      _ThemePreviewCard(
                        title: 'Light'.tr,
                        mode: ThemeMode.light,
                        isSelected: ctrl.isLightMode,
                        onTap: () => ctrl.changeThemeToLight(),
                      ),
                      const SizedBox(width: 10),
                      _ThemePreviewCard(
                        title: 'Dark'.tr,
                        mode: ThemeMode.dark,
                        isSelected: ctrl.isDarkMode,
                        onTap: () => ctrl.changeThemeToDark(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'App theme and display appearance'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: captionColor,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ============== LANGUAGE SECTION ==============
                const _SectionLabel('LANGUAGE / ភាសា'),
                const SizedBox(height: 8),
                Container(
                  decoration: appleCardDecoration(context: context),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _LanguageTile(
                        title: 'settings_language_english'.tr,
                        subtitle: 'English (US)',
                        isSelected: !ctrl.isKhmer,
                        onTap: () => ctrl.changeLanguageToEnglish(),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _LanguageTile(
                        title: 'settings_language_khmer'.tr,
                        subtitle: 'ខ្មែរ (Khmer)',
                        isSelected: ctrl.isKhmer,
                        onTap: () => ctrl.changeLanguageToKhmer(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'App content and interface language'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: captionColor,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ============== WORK & NOTIFICATIONS SECTION ==============
                _SectionLabel('WORK & NOTIFICATIONS'.tr),
                const SizedBox(height: 8),
                Container(
                  decoration: appleCardDecoration(context: context),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _SettingsActionTile(
                        icon: FluentIcons.calendar_clock_24_regular,
                        iconColor: RequestColors.primary,
                        title: 'Work Schedule'.tr,
                        subtitle: 'Weekly shifts, work hours & holidays'.tr,
                        onTap: () => Get.toNamed(AppRoutes.schedule),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _SettingsActionTile(
                        icon: FluentIcons.alert_24_regular,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Notifications'.tr,
                        subtitle: 'Activity alerts & request updates'.tr,
                        onTap: () => Get.toNamed(AppRoutes.notifications),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Manage your schedules and notification preferences'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: captionColor,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ============== ABOUT SECTION ==============
                _SectionLabel('ABOUT'.tr),
                const SizedBox(height: 8),
                Container(
                  decoration: appleCardDecoration(context: context),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _AboutRow(
                        title: 'settings_version'.tr,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '1.0.0 (Build 42)',
                              style: TextStyle(
                                fontSize: 14,
                                color: captionColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: RequestColors.approvedStatus.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Latest'.tr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: RequestColors.approvedStatus,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _AboutRow(
                        title: 'Terms of Service'.tr,
                        showChevron: true,
                        onTap: () {},
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _AboutRow(
                        title: 'Privacy Policy'.tr,
                        showChevron: true,
                        onTap: () {},
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _AboutRow(
                        title: 'Support & Documentation'.tr,
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
                      Icon(
                        FluentIcons.qr_code_24_regular,
                        size: 26,
                        color: isDark ? AppColors.primaryOnDark : RequestColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Face Attendance Security Suite'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: captionColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© ${DateTime.now().year} All rights reserved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: captionColor,
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
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text.tr,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Visual miniature phone preview card for Apple Display & Brightness style settings
class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.title,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryOnDark : AppColors.primary;
    final borderColor = isSelected
        ? primaryColor
        : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0));

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? (isSelected
                    ? primaryColor.withValues(alpha: 0.12)
                    : AppColors.darkBackground.withValues(alpha: 0.6))
                : (isSelected
                    ? primaryColor.withValues(alpha: 0.06)
                    : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Mini Device Mockup Frame
              Container(
                height: 68,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildMockupContent(context),
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? AppColors.darkText : RequestColors.textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              // Selection Indicator (Radio / Check)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8)),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupContent(BuildContext context) {
    if (mode == ThemeMode.light) {
      return _buildLightMockup();
    } else if (mode == ThemeMode.dark) {
      return _buildDarkMockup();
    } else {
      // System mode: Split mockup
      return Row(
        children: [
          Expanded(child: _buildLightMockup(isSplit: true)),
          Container(width: 1, color: const Color(0xFF64748B)),
          Expanded(child: _buildDarkMockup(isSplit: true)),
        ],
      );
    }
  }

  Widget _buildLightMockup({bool isSplit = false}) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          // Content card
          Container(
            height: 22,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 3,
                  width: isSplit ? 16 : 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 3,
                  width: isSplit ? 10 : 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom pill
          Center(
            child: Container(
              height: 3,
              width: isSplit ? 12 : 24,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkMockup({bool isSplit = false}) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          // Content card
          Container(
            height: 22,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 3,
                  width: isSplit ? 16 : 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOnDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 3,
                  width: isSplit ? 10 : 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom pill
          Center(
            child: Container(
              height: 3,
              width: isSplit ? 12 : 24,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : RequestColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary;
    final primaryColor = isDark ? AppColors.primaryOnDark : AppColors.primary;

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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                FluentIcons.checkmark_24_regular,
                color: primaryColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : RequestColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (showChevron)
              Icon(
                FluentIcons.chevron_right_24_regular,
                size: 20,
                color: textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : RequestColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              FluentIcons.chevron_right_24_regular,
              size: 20,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
