import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Leave_screen/controller/leave_controller.dart';
import 'package:face_recognition_attendance/features/Leave_screen/model/leave_request.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/controller/overtime_controller.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum UnifiedRequestType {
  leaveEarly('Leave Early'),
  overtime('Overtime'),
  permission('Permission');

  final String label;
  const UnifiedRequestType(this.label);
}

class UnifiedRequestItem {
  final String id;
  final UnifiedRequestType type;
  final DateTime date;
  final String title;
  final String subtitle;
  final String reason;
  final String statusLabel;
  final bool isApproved;
  final dynamic originalObject;

  const UnifiedRequestItem({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.statusLabel,
    required this.isApproved,
    required this.originalObject,
  });
}

/// Unified screen for Authorized (approved) and Unauthorized (rejected) requests
/// spanning Leave Early, Overtime, and Permission requests with filter tabs.
class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key, required this.status});

  final RequestStatus status;

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final LeaveController _leaveCtrl = Get.isRegistered<LeaveController>()
      ? Get.find<LeaveController>()
      : Get.put(LeaveController());
  final OvertimeController _overtimeCtrl =
      Get.isRegistered<OvertimeController>()
      ? Get.find<OvertimeController>()
      : Get.put(OvertimeController());
  final PermissionController _permissionCtrl =
      Get.isRegistered<PermissionController>()
      ? Get.find<PermissionController>()
      : Get.put(PermissionController());

  int _selectedFilter = 0; // 0: All, 1: Leave Early, 2: Overtime, 3: Permission

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _leaveCtrl.fetchRequests(),
      _overtimeCtrl.fetchRequests(),
      _permissionCtrl.fetchRequests(),
    ]);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  List<UnifiedRequestItem> _gatherAllItems() {
    final items = <UnifiedRequestItem>[];

    // 1. Leave requests
    for (final req in _leaveCtrl.requests) {
      final matches = widget.status == RequestStatus.approved
          ? req.status == LeaveStatus.approved
          : (widget.status == RequestStatus.rejected
                ? req.status == LeaveStatus.rejected
                : req.status == LeaveStatus.pending);
      if (!matches) continue;

      String subtitle;
      if (req.earlyLeaveTime != null && req.earlyLeaveTime!.trim().isNotEmpty) {
        subtitle = 'Leave Early at ${req.earlyLeaveTime}';
      } else if (req.fromDate.year != req.toDate.year ||
          req.fromDate.month != req.toDate.month ||
          req.fromDate.day != req.toDate.day) {
        subtitle =
            '${DateText.weekdayYmd(req.fromDate)} – ${DateText.weekdayYmd(req.toDate)}';
      } else {
        subtitle = req.dayType.isNotEmpty
            ? req.dayType
            : (req.session == 1
                  ? 'Section 1 (Morning)'
                  : (req.session == 2 ? 'Section 2 (Afternoon)' : 'Full Day'));
      }

      items.add(
        UnifiedRequestItem(
          id: req.id,
          type: UnifiedRequestType.leaveEarly,
          date: req.fromDate,
          title: DateText.weekdayYmd(req.fromDate),
          subtitle: subtitle,
          reason: req.reason,
          statusLabel: req.status.label,
          isApproved: req.status == LeaveStatus.approved,
          originalObject: req,
        ),
      );
    }

    // 2. Overtime requests
    for (final req in _overtimeCtrl.requests) {
      final matches = widget.status == RequestStatus.approved
          ? req.status == OvertimeStatus.approved
          : (widget.status == RequestStatus.rejected
                ? req.status == OvertimeStatus.rejected
                : req.status == OvertimeStatus.pending);
      if (!matches) continue;

      final timeStr =
          '${_formatTime(req.fromTime)} – ${_formatTime(req.toTime)}';
      final dur = req.duration;
      final hours = dur.inHours;
      final mins = dur.inMinutes.remainder(60);
      final durStr = hours > 0
          ? (mins > 0 ? '$hours h $mins m' : '$hours h')
          : '$mins m';

      items.add(
        UnifiedRequestItem(
          id: req.id,
          type: UnifiedRequestType.overtime,
          date: req.date,
          title: DateText.weekdayYmd(req.date),
          subtitle: '$timeStr ($durStr)',
          reason: req.reason,
          statusLabel: req.status.label,
          isApproved: req.status == OvertimeStatus.approved,
          originalObject: req,
        ),
      );
    }

    // 3. Permission requests
    for (final req in _permissionCtrl.requests) {
      final matches = widget.status == RequestStatus.approved
          ? req.status == RequestStatus.approved
          : (widget.status == RequestStatus.rejected
                ? req.status == RequestStatus.rejected
                : req.status == RequestStatus.pending);
      if (!matches) continue;

      items.add(
        UnifiedRequestItem(
          id: req.id,
          type: UnifiedRequestType.permission,
          date: req.date,
          title: DateText.weekdayYmd(req.date),
          subtitle: req.schedule,
          reason: req.reason,
          statusLabel: req.status.label,
          isApproved: req.status == RequestStatus.approved,
          originalObject: req,
        ),
      );
    }

    // Sort by date descending (newest first)
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.status == RequestStatus.rejected
        ? 'Unauthorized'
        : (widget.status == RequestStatus.pending ? 'Pending' : 'Authorized');

    return RequestScaffold(
      title: title,
      body: Obx(() {
        final allItems = _gatherAllItems();

        final leaveCount = allItems
            .where((i) => i.type == UnifiedRequestType.leaveEarly)
            .length;
        final overtimeCount = allItems
            .where((i) => i.type == UnifiedRequestType.overtime)
            .length;
        final permissionCount = allItems
            .where((i) => i.type == UnifiedRequestType.permission)
            .length;

        List<UnifiedRequestItem> filteredItems;
        if (_selectedFilter == 1) {
          filteredItems = allItems
              .where((i) => i.type == UnifiedRequestType.leaveEarly)
              .toList();
        } else if (_selectedFilter == 2) {
          filteredItems = allItems
              .where((i) => i.type == UnifiedRequestType.overtime)
              .toList();
        } else if (_selectedFilter == 3) {
          filteredItems = allItems
              .where((i) => i.type == UnifiedRequestType.permission)
              .toList();
        } else {
          filteredItems = allItems;
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: RequestColors.primary,
          child: Column(
            children: [
              // Filter Tabs Row
              _buildFilterTabs(
                allCount: allItems.length,
                leaveCount: leaveCount,
                overtimeCount: overtimeCount,
                permissionCount: permissionCount,
              ),

              // Request Items List
              Expanded(
                child: filteredItems.isEmpty
                    ? _buildEmptyState(title)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _UnifiedRequestCard(item: filteredItems[index]),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterTabs({
    required int allCount,
    required int leaveCount,
    required int overtimeCount,
    required int permissionCount,
  }) {
    final filters = [
      {'label': 'All', 'count': allCount},
      {'label': 'Leave Early', 'count': leaveCount},
      {'label': 'Overtime', 'count': overtimeCount},
      {'label': 'Permission', 'count': permissionCount},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(filters.length, (index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == index;
            final label = filter['label'] as String;
            final count = filter['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? RequestColors.primary
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? RequestColors.primary
                          : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : RequestColors.textPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : RequestColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    String message;
    if (_selectedFilter == 1) {
      message = 'No ${title.toLowerCase()} leave requests';
    } else if (_selectedFilter == 2) {
      message = 'No ${title.toLowerCase()} overtime requests';
    } else if (_selectedFilter == 3) {
      message = 'No ${title.toLowerCase()} permission requests';
    } else {
      message = 'No ${title.toLowerCase()} requests found';
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: RequestColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnifiedRequestCard extends StatelessWidget {
  const _UnifiedRequestCard({required this.item});

  final UnifiedRequestItem item;

  Color _typeBadgeColor() {
    switch (item.type) {
      case UnifiedRequestType.leaveEarly:
        return RequestColors.primary;
      case UnifiedRequestType.overtime:
        return RequestColors.gold;
      case UnifiedRequestType.permission:
        return const Color(0xFF7C3AED);
    }
  }

  void _navigateToDetail() {
    switch (item.type) {
      case UnifiedRequestType.leaveEarly:
        Get.toNamed(AppRoutes.leaveDetail, arguments: item.id);
        break;
      case UnifiedRequestType.overtime:
        Get.toNamed(AppRoutes.overtimeDetail, arguments: item.id);
        break;
      case UnifiedRequestType.permission:
        Get.toNamed(AppRoutes.requestDetail, arguments: item.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeBadgeColor();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _navigateToDetail,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type Chip and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.type.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    statusLabel: item.statusLabel,
                    isApproved: item.isApproved,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title (Date)
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: RequestColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle (Schedule / Time)
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: RequestColors.textSecondary,
                ),
              ),

              // Reason
              if (item.reason.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.reason.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: RequestColors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.statusLabel, required this.isApproved});

  final String statusLabel;
  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (isApproved) {
      bg = RequestColors.approvedBackground;
      fg = RequestColors.approvedText;
    } else {
      bg = RequestColors.danger.withValues(alpha: 0.12);
      fg = RequestColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
