import 'package:face_recognition_attendance/core/utils/report_period.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _PeriodOption { thisMonth, lastMonth, custom }

/// "Download Report" dialog: THIS MONTH / LAST MONTH / CUSTOM.
/// Returns the chosen [ReportPeriod], or null if the user cancels.
/// Reusable for any list (Overtime, Leave, Permission...).
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
    );
    if (picked == null || !mounted) return;

    setState(() {
      _custom = ReportPeriod.custom(picked.start, picked.end);
      _selected = _PeriodOption.custom;
    });
  }

  void _select(_PeriodOption option) {
    if (option == _PeriodOption.custom) {
      // CUSTOM only becomes selected once a range was really picked.
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
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: RequestColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const Text(
              'Download Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _OptionRow(
            label: 'THIS MONTH',
            selected: _selected == _PeriodOption.thisMonth,
            onTap: () => _select(_PeriodOption.thisMonth),
          ),
          const _OptionDivider(),
          _OptionRow(
            label: 'LAST MONTH',
            selected: _selected == _PeriodOption.lastMonth,
            onTap: () => _select(_PeriodOption.lastMonth),
          ),
          const _OptionDivider(),
          _OptionRow(
            label: 'CUSTOM',
            subtitle: _custom?.label,
            selected: _selected == _PeriodOption.custom,
            onTap: () => _select(_PeriodOption.custom),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: RequestButton(
                    label: 'CANCEL',
                    color: RequestColors.danger,
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RequestButton(label: 'Download', onPressed: _download),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 26,
              color: selected ? RequestColors.primary : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionDivider extends StatelessWidget {
  const _OptionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 24,
      endIndent: 24,
      color: Color(0xFFE5E7EB),
    );
  }
}
