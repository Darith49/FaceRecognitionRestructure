import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Leave_screen/view/leave_screen.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/view/request_overtime_screen.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/view/suggestion_screen.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/view/request_permission_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor: isDark ? AppColors.darkBackground : RequestColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: RequestColors.primary,
          onRefresh: () async {
            await Future.wait([
              controller.fetchIncoming(),
              controller.fetchMyRequests(),
              homeCtrl.fetchTodayAttendanceStatus(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : RequestColors.textPrimary,
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
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA)),
                            ),
                            child: Icon(
                              FluentIcons.alert_24_regular,
                              size: 20,
                              color: isDark ? AppColors.darkText : RequestColors.textSecondary,
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

              // SEGMENTED CONTROL (Only for Supervisors: CEO / Manager / Leader)
              Obx(() {
                if (!controller.canApprove.value) return const SizedBox.shrink();
                return _buildSegmentedTabBar(context, controller, isDark);
              }),

              // CONTENT AREA
              Obx(() {
                final isSupervisor = controller.canApprove.value;
                final showApprovalsTab = isSupervisor && controller.selectedTab.value == 0;

                if (showApprovalsTab) {
                  return _buildApprovalsTabContent(context, controller, isDark);
                }

                return _buildServicesTabContent(context, homeCtrl, permissionCtrl, isDark);
              }),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSegmentedTabBar(
    BuildContext context,
    RequestScreenController controller,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFEFEFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Tab 0: Approvals
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 0
                      ? (isDark ? AppColors.darkCard : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: controller.selectedTab.value == 0 && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Approvals'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: controller.selectedTab.value == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: controller.selectedTab.value == 0
                            ? (isDark ? AppColors.darkText : RequestColors.textPrimary)
                            : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                      ),
                    ),
                    if (controller.totalPending.value > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${controller.totalPending.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Tab 1: Apply & Services
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 1
                      ? (isDark ? AppColors.darkCard : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: controller.selectedTab.value == 1 && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Apply & Services'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: controller.selectedTab.value == 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: controller.selectedTab.value == 1
                          ? (isDark ? AppColors.darkText : RequestColors.textPrimary)
                          : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTabContent(
    BuildContext context,
    RequestScreenController controller,
    bool isDark,
  ) {
    final leaves = controller.incomingLeaves;
    final overtimes = controller.incomingOvertimes;
    final perms = controller.incomingPermissions;
    final hasAny = leaves.isNotEmpty || overtimes.isNotEmpty || perms.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PENDING APPROVALS'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
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
                    '${controller.totalPending.value} ${'Pending'.tr}',
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
        const SizedBox(height: 12),
        if (!hasAny)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: appleCardDecoration(context: context),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RequestColors.approvedStatus.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      FluentIcons.checkmark_circle_24_regular,
                      color: RequestColors.approvedStatus,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All Caught Up!'.tr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No requests pending your review.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          for (final l in leaves)
            _buildApprovalCard(
              context: context,
              type: 'Leave Request'.tr,
              icon: FluentIcons.beach_24_regular,
              iconColor: RequestColors.gold,
              employeeName: l['employee_name']?.toString() ?? 'Employee'.tr,
              detail: () {
                final sess = l['session'] as num? ?? 1;
                final mode = l['leave_mode']?.toString() ?? 'full_section';
                final earlyTime = l['early_leave_time']?.toString() ?? '';
                final dateStr = l['from_date']?.toString() ?? '';
                if (sess == 1) {
                  return mode == 'early_leave' && earlyTime.isNotEmpty
                      ? '${'Section 1'.tr} • ${'Early leave at'.tr} $earlyTime ($dateStr)'
                      : '${'Section 1 (Morning)'.tr} ${'on'.tr} $dateStr';
                } else if (sess == 2) {
                  return mode == 'early_leave' && earlyTime.isNotEmpty
                      ? '${'Section 2'.tr} • ${'Early leave at'.tr} $earlyTime ($dateStr)'
                      : '${'Section 2 (Afternoon)'.tr} ${'on'.tr} $dateStr';
                } else if (sess == 0) {
                  return '${'Full Day Leave'.tr} ${'on'.tr} $dateStr';
                }
                return '${(l['day_type'] ?? l['leave_type']).toString().tr}: $dateStr';
              }(),
              reason: l['reason']?.toString() ?? '',
              onApprove: () => controller.reviewLeave(l['id'], true, context),
              onReject: () => controller.reviewLeave(l['id'], false, context),
            ),
          for (final o in overtimes)
            _buildApprovalCard(
              context: context,
              type: 'Overtime Request'.tr,
              icon: FluentIcons.clock_24_regular,
              iconColor: const Color(0xFF7C3AED),
              employeeName: o['employee_name']?.toString() ?? 'Employee'.tr,
              detail: '${o['date']} (${o['start_time']} - ${o['end_time']})',
              reason: o['reason']?.toString() ?? '',
              onApprove: () => controller.reviewOvertime(o['id'], true, context),
              onReject: () => controller.reviewOvertime(o['id'], false, context),
            ),
          for (final p in perms)
            _buildApprovalCard(
              context: context,
              type: 'Permission Request'.tr,
              icon: FluentIcons.person_available_24_regular,
              iconColor: RequestColors.primary,
              employeeName: p['employee_name']?.toString() ?? 'Employee'.tr,
              detail: '${p['date']} (${p['schedule_time']})',
              reason: p['reason']?.toString() ?? '',
              onApprove: () => controller.reviewPermission(p['id'], true, context),
              onReject: () => controller.reviewPermission(p['id'], false, context),
            ),
        ],
      ],
    );
  }

  Widget _buildServicesTabContent(
    BuildContext context,
    HomeController homeCtrl,
    PermissionController permissionCtrl,
    bool isDark,
  ) {
    final controller = Get.find<RequestScreenController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // 1. QUICK REQUEST ACTIONS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'SUBMIT NEW REQUEST'.tr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildQuickActionGrid(context, isDark),
        const SizedBox(height: 22),

        // 2. UNIFIED STATUS TRACKER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY REQUEST TRACKER'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Obx(() => Text(
                '${controller.filteredMyRequests.length} ${'Items'.tr}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RequestColors.primary,
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Category Filter Chips
        _buildCategoryFilterChips(context, controller, isDark),
        const SizedBox(height: 8),

        // Status Filter Chips
        _buildStatusFilterChips(context, controller, isDark),
        const SizedBox(height: 12),

        // Live Request Tracker List
        Obx(() {
          final items = controller.filteredMyRequests;
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: appleCardDecoration(context: context),
                child: Column(
                  children: [
                    Icon(
                      FluentIcons.document_bullet_list_multiple_24_regular,
                      size: 36,
                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No requests found'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap above to submit a new request.'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: items.map((req) {
              return _buildUnifiedRequestCard(
                context: context,
                request: req,
                isDark: isDark,
              );
            }).toList(),
          );
        }),

        const SizedBox(height: 24),

        // 3. UTILITIES & SCHEDULE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'UTILITIES & ARCHIVE'.tr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: appleCardDecoration(context: context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ServiceRow(
                  icon: FluentIcons.calendar_ltr_24_regular,
                  iconColor: RequestColors.primary,
                  title: 'My Work Schedule'.tr,
                  onTap: () => Get.toNamed(AppRoutes.schedule),
                ),
                Divider(height: 1, indent: 56, color: isDark ? AppColors.darkBorder : null),
                _ServiceRow(
                  icon: FluentIcons.history_24_regular,
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Historical Records & Archive'.tr,
                  onTap: () => Get.toNamed(AppRoutes.requestInformation),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Opens any request form as an inline bottom sheet so the tracker
  /// remains visible underneath. The named routes are kept alive for
  /// deep-links/notifications.
  void _showFormSheet(BuildContext context, Widget formScreen) {
    final controller = Get.find<RequestScreenController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (sheetCtx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : RequestColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: formScreen,
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      // Refresh the tracker once the sheet is dismissed
      controller.fetchMyRequests();
    });
  }

  Widget _buildQuickActionGrid(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickRequestTile(
              title: 'Leave'.tr,
              subtitle: 'Early / Off'.tr,
              icon: FluentIcons.beach_24_regular,
              color: const Color(0xFFF59E0B),
              onTap: () => _showFormSheet(
                context,
                const LeaveScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickRequestTile(
              title: 'Overtime'.tr,
              subtitle: 'Extra work'.tr,
              icon: FluentIcons.clock_24_regular,
              color: const Color(0xFF7C3AED),
              onTap: () => _showFormSheet(
                context,
                const RequestOvertimeScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickRequestTile(
              title: 'Permission'.tr,
              subtitle: 'Exception'.tr,
              icon: FluentIcons.person_passkey_24_regular,
              color: RequestColors.primary,
              onTap: () => _showFormSheet(
                context,
                const RequestPermissionScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickRequestTile(
              title: 'Suggestion'.tr,
              subtitle: 'Feedback'.tr,
              icon: FluentIcons.lightbulb_24_regular,
              color: const Color(0xFF10B981),
              onTap: () => _showFormSheet(
                context,
                const SuggestionScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips(
    BuildContext context,
    RequestScreenController controller,
    bool isDark,
  ) {
    final categories = ['All', 'Leave', 'Overtime', 'Permission', 'Suggestion'];
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((cat) {
            final isSelected = controller.selectedCategoryFilter.value == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(
                  cat.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                  ),
                ),
                selected: isSelected,
                selectedColor: RequestColors.primary,
                backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F2F6),
                side: BorderSide(
                  color: isSelected
                      ? RequestColors.primary
                      : (isDark ? AppColors.darkBorder : Colors.transparent),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => controller.selectedCategoryFilter.value = cat,
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildStatusFilterChips(
    BuildContext context,
    RequestScreenController controller,
    bool isDark,
  ) {
    final statuses = ['All', 'Pending', 'Approved', 'Rejected'];
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: statuses.map((status) {
            final isSelected = controller.selectedStatusFilter.value == status;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(
                  status.tr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                  ),
                ),
                selected: isSelected,
                selectedColor: status == 'Approved'
                    ? RequestColors.approvedStatus
                    : (status == 'Rejected' ? RequestColors.danger : RequestColors.primary),
                backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA)),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => controller.selectedStatusFilter.value = status,
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildUnifiedRequestCard({
    required BuildContext context,
    required UnifiedRequestModel request,
    required bool isDark,
  }) {
    Color statusColor;
    Color statusBg;
    String statusLabel = request.status.capitalizeFirst ?? request.status;

    switch (request.status.toLowerCase()) {
      case 'approved':
        statusColor = RequestColors.approvedStatus;
        statusBg = RequestColors.approvedStatus.withValues(alpha: 0.12);
        break;
      case 'rejected':
        statusColor = RequestColors.danger;
        statusBg = RequestColors.danger.withValues(alpha: 0.12);
        break;
      default:
        statusColor = RequestColors.gold;
        statusBg = RequestColors.gold.withValues(alpha: 0.14);
        statusLabel = 'Pending'.tr;
    }

    IconData typeIcon;
    Color typeColor;
    switch (request.category) {
      case 'Leave':
        typeIcon = FluentIcons.beach_24_regular;
        typeColor = const Color(0xFFF59E0B);
        break;
      case 'Overtime':
        typeIcon = FluentIcons.clock_24_regular;
        typeColor = const Color(0xFF7C3AED);
        break;
      case 'Permission':
        typeIcon = FluentIcons.person_passkey_24_regular;
        typeColor = RequestColors.primary;
        break;
      default:
        typeIcon = FluentIcons.lightbulb_24_regular;
        typeColor = const Color(0xFF10B981);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          switch (request.category) {
            case 'Leave':
              Get.toNamed(AppRoutes.leave);
              break;
            case 'Overtime':
              Get.toNamed(AppRoutes.overtime);
              break;
            case 'Permission':
              Get.toNamed(AppRoutes.permission);
              break;
            case 'Suggestion':
              Get.toNamed(AppRoutes.suggestionStatus);
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: appleCardDecoration(context: context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeIcon, size: 20, color: typeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.detail,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${'Reason'.tr}: ${request.reason}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    ),
                  ),
                ),
              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: appleCardDecoration(context: context),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : RequestColors.textPrimary,
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : RequestColors.textPrimary,
              ),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${'Reason'.tr}: $reason',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
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
                  child: Text('Reject'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
                  child: Text('Approve'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickRequestTile extends StatelessWidget {
  const _QuickRequestTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEFEFF4),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                ),
              ),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                ),
              ),
            ),
            Icon(
              FluentIcons.chevron_right_24_regular,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
