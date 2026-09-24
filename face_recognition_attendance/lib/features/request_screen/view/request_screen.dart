import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:face_recognition_attendance/features/request_screen/controller/request_screen_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key, this.showBackButton = false});

  /// false = the "Request" tab of the bottom bar (no back arrow).
  /// true  = opened on top of another page, for example from the Clock screen.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<RequestScreenController>()
        ? Get.find<RequestScreenController>()
        : Get.put(RequestScreenController());
    final permissionCtrl = Get.isRegistered<PermissionController>()
        ? Get.find<PermissionController>()
        : Get.put(PermissionController());
    final notifCtrl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);

    return Scaffold(
      backgroundColor: RequestColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: showBackButton ? 24 : 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (showBackButton) ...[
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          FluentIcons.chevron_left_24_regular,
                          size: 24,
                          color: RequestColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        'request_title'.tr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: RequestColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.notifications),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5E5EA)),
                            ),
                            child: const Icon(
                              FluentIcons.alert_24_regular,
                              size: 20,
                              color: RequestColors.textSecondary,
                            ),
                          ),
                          Obx(() {
                            if (notifCtrl.unreadCount.value == 0) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${notifCtrl.unreadCount.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // INCOMING APPROVALS (CEO / Manager / Leader)
              Obx(() {
                if (!controller.canApprove.value) return const SizedBox.shrink();
                final leaves = controller.incomingLeaves;
                final overtimes = controller.incomingOvertimes;
                final perms = controller.incomingPermissions;
                final hasAny = leaves.isNotEmpty || overtimes.isNotEmpty || perms.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PENDING APPROVALS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (hasAny)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${controller.totalPending.value} Pending',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!hasAny)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: appleCardDecoration(),
                          child: const Row(
                            children: [
                              Icon(FluentIcons.checkmark_circle_24_regular,
                                  color: RequestColors.approvedStatus, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'No requests pending your review.',
                                style: TextStyle(fontSize: 13, color: RequestColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      for (final l in leaves)
                        _buildApprovalCard(
                          context: context,
                          type: 'Leave Request',
                          icon: FluentIcons.beach_24_regular,
                          iconColor: RequestColors.gold,
                          employeeName: l['employee_name']?.toString() ?? 'Employee',
                          detail: () {
                            final sess = l['session'] as num? ?? 1;
                            final mode = l['leave_mode']?.toString() ?? 'full_section';
                            final earlyTime = l['early_leave_time']?.toString() ?? '';
                            final dateStr = l['from_date']?.toString() ?? '';
                            if (sess == 1) {
                              return mode == 'early_leave' && earlyTime.isNotEmpty
                                  ? 'Section 1 • Early leave at $earlyTime ($dateStr)'
                                  : 'Section 1 (Morning) on $dateStr';
                            } else if (sess == 2) {
                              return mode == 'early_leave' && earlyTime.isNotEmpty
                                  ? 'Section 2 • Early leave at $earlyTime ($dateStr)'
                                  : 'Section 2 (Afternoon) on $dateStr';
                            } else if (sess == 0) {
                              return 'Full Day Leave on $dateStr';
                            }
                            return '${l['day_type'] ?? l['leave_type']}: $dateStr';
                          }(),
                          reason: l['reason']?.toString() ?? '',
                          onApprove: () => controller.reviewLeave(l['id'], true, context),
                          onReject: () => controller.reviewLeave(l['id'], false, context),
                        ),
                      for (final o in overtimes)
                        _buildApprovalCard(
                          context: context,
                          type: 'Overtime Request',
                          icon: FluentIcons.clock_24_regular,
                          iconColor: const Color(0xFF7C3AED),
                          employeeName: o['employee_name']?.toString() ?? 'Employee',
                          detail: '${o['date']} (${o['start_time']} - ${o['end_time']})',
                          reason: o['reason']?.toString() ?? '',
                          onApprove: () => controller.reviewOvertime(o['id'], true, context),
                          onReject: () => controller.reviewOvertime(o['id'], false, context),
                        ),
                      for (final p in perms)
                        _buildApprovalCard(
                          context: context,
                          type: 'Permission Request',
                          icon: FluentIcons.person_available_24_regular,
                          iconColor: RequestColors.primary,
                          employeeName: p['employee_name']?.toString() ?? 'Employee',
                          detail: '${p['date']} (${p['schedule_time']})',
                          reason: p['reason']?.toString() ?? '',
                          onApprove: () => controller.reviewPermission(p['id'], true, context),
                          onReject: () => controller.reviewPermission(p['id'], false, context),
                        ),
                    ],
                  ],
                );
              }),

              const SizedBox(height: 20),

              // ─── CLOCK ATTENDANCE (Inline) ───────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CLOCK ATTENDANCE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: RequestColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.clock),
                          child: const Text(
                            'Full View',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RequestClockAttendanceCard(homeCtrl: homeCtrl),
                  const SizedBox(height: 20),
                ],
              ),

              // MANAGEMENT & SERVICES Section
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'MANAGEMENT & SERVICES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: appleCardDecoration(),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ServiceRow(
                        icon: FluentIcons.calendar_ltr_24_regular,
                        iconColor: RequestColors.primary,
                        title: 'My Schedule',
                        onTap: () => Get.toNamed(AppRoutes.schedule),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ServiceRow(
                        icon: FluentIcons.beach_24_regular,
                        iconColor: RequestColors.approvedStatus,
                        title: 'Leave Request',
                        onTap: () => Get.toNamed(AppRoutes.leave),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ServiceRow(
                        icon: FluentIcons.clock_24_regular,
                        iconColor: RequestColors.gold,
                        title: 'Overtime',
                        onTap: () => Get.toNamed(AppRoutes.overtime),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ServiceRow(
                        icon: FluentIcons.lightbulb_24_regular,
                        iconColor: RequestColors.gold,
                        title: 'Suggestion Box',
                        onTap: () => Get.toNamed(AppRoutes.suggestion),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Permission & Authorization
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Get.toNamed(AppRoutes.permission),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              FluentIcons.person_passkey_24_regular,
                              size: 26,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Permission & Authorization',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: RequestColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Request permissions or authorization changes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: RequestColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            FluentIcons.chevron_right_24_regular,
                            size: 20,
                            color: RequestColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // REQUEST ACTIVITY Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'REQUEST ACTIVITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.requestInformation),
                      child: const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: RequestColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: appleCardDecoration(),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Obx(() {
                        final pendingList = permissionCtrl.requestsWithStatus(RequestStatus.pending);
                        return _ActivityRow(
                          icon: FluentIcons.clock_24_regular,
                          iconColor: RequestColors.gold,
                          title: 'Unauthorized',
                          subtitle: 'Pending review',
                          badgeText: '${pendingList.length} Pending',
                          badgeColor: RequestColors.gold,
                          onTap: () => Get.toNamed(AppRoutes.requestUnauthorized),
                        );
                      }),
                      const Divider(height: 1, indent: 56),
                      Obx(() {
                        final approvedList = permissionCtrl.requestsWithStatus(RequestStatus.approved);
                        return _ActivityRow(
                          icon: FluentIcons.checkmark_circle_24_regular,
                          iconColor: RequestColors.approvedStatus,
                          title: 'Authorized',
                          subtitle: 'Completed & archived',
                          badgeText: '${approvedList.length} Total',
                          badgeColor: RequestColors.approvedStatus,
                          onTap: () => Get.toNamed(AppRoutes.requestAuthorized),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalCard({
    required BuildContext context,
    required String type,
    required IconData icon,
    required Color iconColor,
    required String employeeName,
    required String detail,
    required String reason,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: appleCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: RequestColors.textPrimary,
                        ),
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RequestColors.textPrimary,
              ),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: $reason',
                style: const TextStyle(
                  fontSize: 12,
                  color: RequestColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RequestColors.danger,
                    side: const BorderSide(color: RequestColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequestColors.approvedStatus,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Inline Clock Attendance Card ────────────────────────────────────────────

class _RequestClockAttendanceCard extends StatelessWidget {
  const _RequestClockAttendanceCard({required this.homeCtrl});

  final HomeController homeCtrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final state = homeCtrl.state.value;
        final isDone = state == CheckState.completed || state == CheckState.checkedOut;
        final hasFace = homeCtrl.hasFaceRegistered;

        // Determine button color & label
        Color buttonColor;
        String buttonLabel;
        IconData buttonIcon;

        if (!hasFace) {
          buttonColor = const Color(0xFF7C3AED);
          buttonLabel = 'Register Face';
          buttonIcon = FluentIcons.person_star_24_regular;
        } else if (isDone) {
          buttonColor = RequestColors.approvedStatus;
          buttonLabel = 'Completed';
          buttonIcon = FluentIcons.checkmark_24_regular;
        } else {
          switch (state) {
            case CheckState.session1NotCheckedIn:
            case CheckState.notCheckedIn:
            case CheckState.session2NotCheckedIn:
              buttonColor = RequestColors.primary;
              buttonLabel = 'Check In';
              buttonIcon = FluentIcons.fingerprint_24_regular;
              break;
            case CheckState.session1CheckedIn:
            case CheckState.checkedIn:
            case CheckState.session2CheckedIn:
              buttonColor = RequestColors.danger;
              buttonLabel = 'Check Out';
              buttonIcon = FluentIcons.sign_out_24_regular;
              break;
            default:
              buttonColor = RequestColors.primary;
              buttonLabel = 'Check In';
              buttonIcon = FluentIcons.fingerprint_24_regular;
          }
        }

        // Determine active session label
        String sessionLabel;
        switch (state) {
          case CheckState.session1NotCheckedIn:
          case CheckState.notCheckedIn:
          case CheckState.session1CheckedIn:
          case CheckState.checkedIn:
            sessionLabel = 'Session 1 • Morning';
            break;
          case CheckState.session2NotCheckedIn:
          case CheckState.session2CheckedIn:
            sessionLabel = 'Session 2 • Afternoon';
            break;
          case CheckState.completed:
          case CheckState.checkedOut:
            sessionLabel = 'All Sessions Done';
            break;
        }

        return Container(
          decoration: appleCardDecoration(radius: 20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        FluentIcons.clock_24_regular,
                        size: 28,
                        color: buttonColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Clock Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: RequestColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sessionLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: buttonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone
                            ? RequestColors.approvedStatus.withValues(alpha: 0.12)
                            : buttonColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDone ? 'Done' : (hasFace ? 'Active' : 'Setup'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDone ? RequestColors.approvedStatus : buttonColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Session tiles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    // Session 1
                    Expanded(
                      child: _MiniSessionTile(
                        label: 'SESSION 1',
                        icon: FluentIcons.weather_sunny_24_filled,
                        iconColor: const Color(0xFFF59E0B),
                        checkIn: homeCtrl.session1CheckInText,
                        checkOut: homeCtrl.session1CheckOutText,
                        isActive: homeCtrl.isSession1Active,
                        isDone: homeCtrl.isSession1Done,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Session 2
                    Expanded(
                      child: _MiniSessionTile(
                        label: 'SESSION 2',
                        icon: FluentIcons.weather_moon_24_filled,
                        iconColor: const Color(0xFF6366F1),
                        checkIn: homeCtrl.session2CheckInText,
                        checkOut: homeCtrl.session2CheckOutText,
                        isActive: homeCtrl.isSession2Active,
                        isDone: homeCtrl.isSession2Done,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          homeCtrl.totalHoursText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: homeCtrl.goalProgress >= 1.0
                                ? RequestColors.approvedStatus
                                : RequestColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${(homeCtrl.goalProgress * 100).toInt()}% of ${homeCtrl.goalHours.toStringAsFixed(0)}h',
                          style: const TextStyle(
                            fontSize: 11,
                            color: RequestColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: homeCtrl.goalProgress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE5E5EA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          homeCtrl.goalProgress >= 1.0
                              ? RequestColors.approvedStatus
                              : RequestColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Check In / Check Out button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: isDone ? null : () => homeCtrl.onMainButtonPressed(),
                    icon: Icon(buttonIcon, size: 20),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: RequestColors.approvedStatus.withValues(alpha: 0.15),
                      disabledForegroundColor: RequestColors.approvedStatus,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MiniSessionTile extends StatelessWidget {
  const _MiniSessionTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.checkIn,
    required this.checkOut,
    required this.isActive,
    required this.isDone,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String checkIn;
  final String checkOut;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    if (isDone) {
      borderColor = RequestColors.approvedStatus.withValues(alpha: 0.3);
      bgColor = RequestColors.approvedStatus.withValues(alpha: 0.04);
    } else if (isActive) {
      borderColor = RequestColors.primary.withValues(alpha: 0.35);
      bgColor = RequestColors.primary.withValues(alpha: 0.04);
    } else {
      borderColor = const Color(0xFFEBECEF);
      bgColor = const Color(0xFFF9FAFB);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isActive ? 1.4 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? RequestColors.primary : RequestColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (isDone)
                const Icon(FluentIcons.checkmark_circle_24_filled, size: 14, color: RequestColors.approvedStatus),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      checkIn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: checkIn != '-- : --'
                            ? RequestColors.textPrimary
                            : const Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OUT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      checkOut,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: checkOut != '-- : --'
                            ? RequestColors.textPrimary
                            : const Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Activity Row ────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 12),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

// ─── Service Row ─────────────────────────────────────────────────────────────

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: RequestColors.textPrimary,
                ),
              ),
            ),
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
