import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/utils/report_period.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _PeriodOption { thisMonth, lastMonth, custom }

/// Apple-styled "Export Report" dialog: This Month / Last Month / Custom Range.
/// Returns the chosen [ReportPeriod], or null if the user cancels.
Future<ReportPeriod?> showDownloadReportDialog(BuildContext context) {
  return showDialog<ReportPeriod>(
    context: context,
    builder: (context) => const _DownloadReportDialog(),
  );
}

class _DownloadReportDialog extends StatefulWidget {
  const _DownloadReportDialog();

  @override
  State<_DownloadReportDialog> createState() => _DownloadReportDialogState();
}

class _DownloadReportDialogState extends State<_DownloadReportDialog> {
  _PeriodOption _selected = _PeriodOption.thisMonth;

  /// Only set after the user picked a range for CUSTOM.
  ReportPeriod? _custom;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final custom = _custom;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: custom == null
          ? null
          : DateTimeRange(start: custom.start, end: custom.end),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: RequestColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: RequestColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    setState(() {
      _custom = ReportPeriod.custom(picked.start, picked.end);
      _selected = _PeriodOption.custom;
    });
  }

  void _select(_PeriodOption option) {
    if (option == _PeriodOption.custom) {
      _pickCustomRange();
      return;
    }
    setState(() => _selected = option);
  }

  void _download() {
    ReportPeriod? period;
    if (_selected == _PeriodOption.thisMonth) {
      period = ReportPeriod.thisMonth();
    } else if (_selected == _PeriodOption.lastMonth) {
      period = ReportPeriod.lastMonth();
    } else {
      period = _custom;
    }
    if (period == null) return;
    Get.back(result: period);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1);

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top PDF Icon Badge (clean icon)
            const Icon(
              FluentIcons.document_pdf_24_regular,
              size: 38,
              color: RequestColors.primary,
            ),

            const SizedBox(height: 14),

            // Title
            const Text(
              'Export Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RequestColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle
            const Text(
              'Choose a time period for your overtime PDF summary',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: RequestColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            // Option 1: This Month
            _AppleOptionTile(
              icon: FluentIcons.calendar_ltr_24_regular,
              iconColor: RequestColors.primary,
              title: 'This Month',
              subtitle: DateText.monthYear(now),
              selected: _selected == _PeriodOption.thisMonth,
              onTap: () => _select(_PeriodOption.thisMonth),
            ),

            const SizedBox(height: 10),

            // Option 2: Last Month
            _AppleOptionTile(
              icon: FluentIcons.arrow_repeat_all_24_regular,
              iconColor: const Color(0xFF7C3AED),
              title: 'Last Month',
              subtitle: DateText.monthYear(lastMonthDate),
              selected: _selected == _PeriodOption.lastMonth,
              onTap: () => _select(_PeriodOption.lastMonth),
            ),

            const SizedBox(height: 10),

            // Option 3: Custom Range
            _AppleOptionTile(
              icon: FluentIcons.calendar_date_24_regular,
              iconColor: RequestColors.gold,
              title: 'Custom Range',
              subtitle: _custom != null
                  ? _custom!.label
                  : 'Select specific date range',
              selected: _selected == _PeriodOption.custom,
              trailing: _custom != null
                  ? ChangePill(onTap: _pickCustomRange)
                  : const Icon(
                      FluentIcons.chevron_right_24_regular,
                      color: RequestColors.textSecondary,
                      size: 20,
                    ),
              onTap: () => _select(_PeriodOption.custom),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFF2F2F7),
                        foregroundColor: RequestColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _download,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RequestColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleOptionTile extends StatelessWidget {
  const _AppleOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? RequestColors.primary.withValues(alpha: 0.06)
          : (isDark ? AppColors.darkSurface : RequestColors.softSurface),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? RequestColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.hairline),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: selected
                      ? RequestColors.primary
                      : const Color(0xFFC7C7CC),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
