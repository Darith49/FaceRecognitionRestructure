import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Colors used across all screens — Apple Design System tokens.
class RequestColors {
  RequestColors._();

  static const Color background = Color(0xFFF5F5F7);     // Canvas parchment
  static const Color softSurface = Color(0xFFFAFAFC);    // Surface pearl
  static const Color textPrimary = Color(0xFF1D1D1F);    // Ink
  static const Color textSecondary = Color(0xFF6B7280);   // Muted gray
  static const Color primary = Color(0xFF0066CC);         // Apple Blue
  static const Color danger = Color(0xFFFF3B30);          // Apple Red
  static const Color pendingBackground = Color(0xFFFFF3CD);
  static const Color pendingText = Color(0xFF9C7F0C);
  static const Color approvedBackground = Color(0xFFD4EDDA);
  static const Color approvedText = Color(0xFF0B3D1E);
  static const Color approvedStatus = Color(0xFF34C759);  // Apple Green
  static const Color gold = Color(0xFFFF9500);            // Apple Amber
  static const Color teal = Color(0xFF3E5C76);
}

/// Standard shadows for Apple-style cards.
const List<BoxShadow> appleSoftShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
];

/// Apple-style card decoration.
BoxDecoration appleCardDecoration({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: appleSoftShadow,
);

/// Page frame used by every screen in this feature:
/// white app bar with a title + back arrow, and the light grey body.
class RequestScaffold extends StatelessWidget {
  const RequestScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.centerTitle = false,
    this.floatingActionButton,
    this.actions,
    this.backLabel,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final bool centerTitle;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : RequestColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: centerTitle,
        automaticallyImplyLeading: false,
        titleSpacing: showBackButton ? 0.0 : 16.0,
        leading: showBackButton
            ? GestureDetector(
                onTap: () => Get.back(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.chevron_left_24_regular,
                        size: 24,
                        color: RequestColors.primary,
                      ),
                      if (backLabel != null)
                        Text(
                          backLabel!.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            color: RequestColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : null,
        leadingWidth: showBackButton ? (backLabel != null ? 120 : 44) : null,
        title: Text(
          title.tr,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
          ),
        ),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// A white rounded card with a colored icon on the left, a title, a subtitle
/// and an arrow on the right. Used for menus (Request Information, Permission...).
class RequestMenuCard extends StatelessWidget {
  const RequestMenuCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(icon, color: iconBackground, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FluentIcons.chevron_right_24_regular,
                color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bold label shown above an input or a read-only field.
class RequestLabel extends StatelessWidget {
  const RequestLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.tr,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
        ),
      ),
    );
  }
}

/// Label + white read-only box (used on the request detail page).
class RequestField extends StatelessWidget {
  const RequestField({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight = FontWeight.w500,
    this.multiline = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight valueWeight;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = valueColor ?? (isDark ? AppColors.darkText : RequestColors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequestLabel(label),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: multiline ? 110.0 : 48.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: valueWeight,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width button. Apple-style pill shape.
class RequestButton extends StatelessWidget {
  const RequestButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.color,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  /// Overrides the background color (text becomes white).
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = filled
        ? AppColors.primary
        : (isDark ? AppColors.darkSurface : Colors.white);
    final backgroundColor = color ?? defaultBg;
    final foregroundColor = color != null
        ? Colors.white
        : (filled
            ? Colors.white
            : (isDark ? AppColors.darkText : RequestColors.textPrimary));

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: filled ? BorderSide.none : BorderSide(color: AppColors.hairline),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.tr),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Notification popup displayed at the top of the screen so it is never
/// covered or obscured by the floating bottom navigation bar.
class RequestSnack {
  RequestSnack._();

  /// Displays a modern, non-intrusive popup notification at the top of the screen.
  /// Fully backwards compatible with existing `RequestSnack.show(messenger, message)` calls.
  static void show(dynamic messenger, String message, {bool? isError}) {
    final lower = message.toLowerCase();
    final bool err = isError ??
        (lower.contains('failed') ||
            lower.contains('error') ||
            lower.contains('denied') ||
            lower.contains('too large') ||
            lower.contains('cancelled') ||
            lower.contains('first') ||
            lower.contains('must') ||
            lower.contains('required'));

    final bool success = !err &&
        (lower.contains('success') ||
            lower.contains('saved') ||
            lower.contains('submitted') ||
            lower.contains('updated') ||
            lower.contains('approved'));

    final Color bgColor = err
        ? const Color(0xFFDC2626)
        : (success ? const Color(0xFF16A34A) : RequestColors.textPrimary);

    final IconData icon = err
        ? FluentIcons.error_circle_24_regular
        : (success ? FluentIcons.checkmark_circle_24_regular : FluentIcons.info_24_regular);

    try {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      Get.rawSnackbar(
        messageText: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: bgColor,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
        snackStyle: SnackStyle.FLOATING,
        animationDuration: const Duration(milliseconds: 280),
        boxShadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } catch (_) {
      // Fallback if GetX overlay is unavailable in current context
      if (messenger is ScaffoldMessengerState) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message.tr),
              behavior: SnackBarBehavior.floating,
              backgroundColor: bgColor,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
      }
    }
  }
}

/// White button that opens the date picker.
/// Shows the chosen date as yyyy-MM-dd, or [placeholder] when nothing is chosen.
/// Only today and future dates (up to 1 year) can be picked.
class RequestDateField extends StatelessWidget {
  const RequestDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Select Date',
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String placeholder;

  Future<void> _pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = DateTime(today.year + 1, today.month, today.day);

    // The picker must start on a day between today and the last date.
    var initial = value == null ? today : DateUtils.dateOnly(value!);
    if (initial.isBefore(today) || initial.isAfter(lastDate)) {
      initial = today;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: lastDate,
    );

    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = value;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickDate(context),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Center(
            child: Text(
              current == null ? placeholder.tr : DateText.ymd(current),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkText : RequestColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded dropdown.
class RequestDropdownField<T> extends StatelessWidget {
  const RequestDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.fillColor = Colors.white,
    this.icon = FluentIcons.chevron_down_24_regular,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final String? hint;
  final Color fillColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedFill = isDark ? AppColors.darkSurface : fillColor;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: resolvedFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(icon, color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
          ),
          hint: hint == null
              ? null
              : Text(
                  hint!.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                  ),
                ),
          items: items,
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}

/// Big white text box for the reason.
class RequestTextArea extends StatelessWidget {
  const RequestTextArea({
    super.key,
    required this.controller,
    this.hint = 'Enter reasons for leave',
    this.lines = 5,
  });

  final TextEditingController controller;
  final String hint;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? AppColors.darkText : RequestColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint.tr,
        hintStyle: TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Apple-style segmented control (tab bar).
class AppleSegmentedControl extends StatelessWidget {
  const AppleSegmentedControl({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i].tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? RequestColors.textPrimary
                        : RequestColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Apple-style "Change" pill button.
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RequestColors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            'Change'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: RequestColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress bar used in various cards.
class AppleProgressBar extends StatelessWidget {
  const AppleProgressBar({
    super.key,
    required this.value,
    this.color = RequestColors.primary,
    this.trackColor,
    this.height = 6,
  });

  final double value;
  final Color color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: trackColor ?? color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: height,
        ),
      ),
    );
  }
}
