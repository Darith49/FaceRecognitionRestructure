import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/ceo_manage/controller/ceo_manage_controller.dart';
import 'package:face_recognition_attendance/features/ceo_manage/model/ceo_report_models.dart';

class CeoEmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const CeoEmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<CeoEmployeeDetailScreen> createState() => _CeoEmployeeDetailScreenState();
}

class _CeoEmployeeDetailScreenState extends State<CeoEmployeeDetailScreen> {
  final CeoManageController controller = Get.isRegistered<CeoManageController>()
      ? Get.find<CeoManageController>()
      : Get.put(CeoManageController());

  @override
  void initState() {
    super.initState();
    controller.fetchEmployeeDetail(widget.employeeId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          widget.employeeName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
      ),
      body: Obx(() {
        if (controller.isEmployeeDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.employeeDetail.value;
        if (data == null) {
          return const Center(child: Text('Failed to load employee details.'));
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchEmployeeDetail(widget.employeeId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee Header Card
                _buildHeaderCard(data, isDark),
                const SizedBox(height: 16),

                // Rates Summary (Attendance Rate & On-Time Rate)
                Row(
                  children: [
                    Expanded(
                      child: _buildRateCard(
                        title: 'Attendance Rate',
                        rate: data.attendanceRate,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRateCard(
                        title: 'On-Time Rate',
                        rate: data.onTimeRate,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                _buildMetricsGrid(data.summary, isDark),
                const SizedBox(height: 24),

                // Daily Attendance Records
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Attendance Records',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    Text(
                      '${data.dailyRecords.length} days',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (data.dailyRecords.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text(
                      'No attendance records found for this period.',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.dailyRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final rec = data.dailyRecords[index];
                      return _buildDailyRecordCard(rec, isDark);
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(EmployeeDetailResponse data, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25252D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: data.profileUrl != null && data.profileUrl!.isNotEmpty
                    ? NetworkImage(data.profileUrl!)
                    : null,
                child: data.profileUrl == null || data.profileUrl!.isEmpty
                    ? Text(
                        data.name.isNotEmpty ? data.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _buildBadge(
                          data.role.toUpperCase(),
                          AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        _buildBadge(
                          data.departmentName,
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Branch: ${data.branchName}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                data.periodLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRateCard({
    required String title,
    required double rate,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25252D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(EmployeeReportSummary summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25252D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Present',
                  '${summary.presentDays} days',
                  const Color(0xFF10B981),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Absent',
                  '${summary.absentDays} days',
                  const Color(0xFFEF4444),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'On Leave',
                  '${summary.leaveDays} days',
                  const Color(0xFF8B5CF6),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Late',
                  '${summary.lateCount} times\n(${summary.totalLateMinutes} min)',
                  const Color(0xFFF59E0B),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Left Early',
                  '${summary.leftEarlyCount} times\n(${summary.totalEarlyMinutes} min)',
                  const Color(0xFFF97316),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Overtime',
                  '${summary.otCount} times\n(${summary.totalOtFormatted})',
                  const Color(0xFF06B6D4),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRecordCard(DailyRecordReport rec, bool isDark) {
    Color statusColor;
    switch (rec.mainStatus) {
      case 'Present':
        statusColor = const Color(0xFF10B981);
        break;
      case 'Absent':
        statusColor = const Color(0xFFEF4444);
        break;
      case 'On Leave':
        statusColor = const Color(0xFF8B5CF6);
        break;
      case 'Day Off':
      case 'Not Employed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25252D) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    rec.dateDisplay,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${rec.dayName})',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec.mainStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (rec.timeFormatted.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rec.timeFormatted,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
          ],

          if (rec.conditionDetails.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: rec.conditionDetails.split(', ').map((cond) {
                final isLate = cond.toLowerCase().contains('late');
                final isEarly = cond.toLowerCase().contains('early');
                final isOt = cond.toLowerCase().contains('ot');
                final chipColor = isLate
                    ? const Color(0xFFF59E0B)
                    : (isEarly ? const Color(0xFFF97316) : (isOt ? const Color(0xFF06B6D4) : Colors.grey));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    cond,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: chipColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
