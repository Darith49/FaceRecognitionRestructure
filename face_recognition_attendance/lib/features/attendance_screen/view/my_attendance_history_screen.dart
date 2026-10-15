import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAttendanceHistoryScreen extends StatefulWidget {
  const MyAttendanceHistoryScreen({super.key});

  @override
  State<MyAttendanceHistoryScreen> createState() => _MyAttendanceHistoryScreenState();
}

class _MyAttendanceHistoryScreenState extends State<MyAttendanceHistoryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  List<Map<String, dynamic>> _loadUserRecords() {
    final loginController = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController(), permanent: true);
    final user = loginController.currentuser.value;

    final localDb = LocalDatabaseService();
    final allEmployees = localDb.getEmployees();
    final matchedEmp = allEmployees.firstWhereOrNull(
      (e) => (user != null && (
        e['email']?.toString().toLowerCase() == user.email.toLowerCase() ||
        e['employee_id']?.toString() == user.employeeId ||
        e['firebase_uid']?.toString() == user.uid
      )),
    );

    final targetId = matchedEmp?['id']?.toString() ?? user?.employeeId ?? '';
    final targetCode = matchedEmp?['employee_id']?.toString() ?? user?.employeeId ?? '';
    final targetName = user?.fullname ?? '';

    final allRecords = localDb.getAttendanceRecords();

    final userRecords = allRecords.where((r) {
      final rEmpId = r['employee_id']?.toString() ?? '';
      final rName = r['employee_name']?.toString() ?? '';
      return (targetId.isNotEmpty && rEmpId == targetId) ||
          (targetCode.isNotEmpty && rEmpId == targetCode) ||
          (targetName.isNotEmpty && rName == targetName);
    }).toList();

    final prefix = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    final monthRecords = userRecords.where((r) {
      final d = r['date']?.toString() ?? '';
      return d.startsWith(prefix);
    }).toList();

    monthRecords.sort((a, b) {
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      final cmp = dateB.compareTo(dateA);
      if (cmp != 0) return cmp;
      final timeA = a['check_in_time']?.toString() ?? '';
      final timeB = b['check_in_time']?.toString() ?? '';
      return timeB.compareTo(timeA);
    });

    return monthRecords;
  }

  String _formatTimeDisplay(dynamic timeValue) {
    if (timeValue == null) return '--:--';
    final str = timeValue.toString().trim();
    if (str.isEmpty) return '--:--';

    // If ISO 8601 string: 2026-10-15T08:00:00
    if (str.contains('T') || str.contains('-')) {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour < 12 ? 'AM' : 'PM';
        return '${hour.toString().padLeft(2, '0')}:$minute $period';
      }
    }

    // If HH:mm or HH:mm:ss format
    final parts = str.split(':');
    if (parts.length >= 2) {
      final hourInt = int.tryParse(parts[0]) ?? 0;
      final min = parts[1].padLeft(2, '0');
      final hour12 = hourInt % 12 == 0 ? 12 : hourInt % 12;
      final period = hourInt < 12 ? 'AM' : 'PM';
      return '${hour12.toString().padLeft(2, '0')}:$min $period';
    }

    return str;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'worked':
      case 'completed':
        return RequestColors.approvedStatus;
      case 'late':
        return const Color(0xFFD97706);
      case 'overtime':
        return const Color(0xFF7C3AED);
      case 'absent':
        return RequestColors.danger;
      default:
        return RequestColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : RequestColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    final records = _loadUserRecords();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : RequestColors.background,
      appBar: AppBar(
        title: Text(
          'My Attendance History'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            FluentIcons.arrow_left_24_regular,
            color: textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Month Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    FluentIcons.chevron_left_24_regular,
                    color: textPrimary,
                  ),
                  onPressed: _previousMonth,
                  tooltip: 'Previous Month'.tr,
                ),
                Column(
                  children: [
                    Text(
                      DateText.monthYear(_selectedMonth),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${records.length} ${records.length == 1 ? 'record' : 'records'}'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    FluentIcons.chevron_right_24_regular,
                    color: textPrimary,
                  ),
                  onPressed: _nextMonth,
                  tooltip: 'Next Month'.tr,
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : RequestColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FluentIcons.calendar_empty_24_regular,
                              size: 32,
                              color: isDark ? AppColors.darkTextSecondary : RequestColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Attendance Records'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No clock-in or check-out logs recorded for this month.'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = records[index];
                      final dateStr = item['date']?.toString() ?? '';
                      final inTimeStr = item['check_in_time'];
                      final outTimeStr = item['check_out_time'];
                      final status = item['status']?.toString() ?? 'Present';
                      final session = item['session'];
                      final statusColor = _getStatusColor(status);

                      DateTime? parsedDate;
                      if (dateStr.isNotEmpty) {
                        parsedDate = DateTime.tryParse(dateStr);
                      }
                      final dayName = parsedDate != null
                          ? DateText.weekdayShort(parsedDate.weekday)
                          : '';
                      final dayNum = parsedDate != null ? '${parsedDate.day}' : '';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                          ),
                          boxShadow: isDark
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Date Badge
                            Container(
                              width: 48,
                              height: 52,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    dayNum,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // In / Out times
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      if (session != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.darkSurface : const Color(0xFFE0E7FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'S$session',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4338CA),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        FluentIcons.arrow_enter_left_20_regular,
                                        size: 15,
                                        color: RequestColors.approvedStatus,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTimeDisplay(inTimeStr),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Icon(
                                        FluentIcons.arrow_exit_20_regular,
                                        size: 15,
                                        color: outTimeStr != null
                                            ? const Color(0xFFDC2626)
                                            : textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTimeDisplay(outTimeStr),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: outTimeStr != null ? textPrimary : textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Status Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                status.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
