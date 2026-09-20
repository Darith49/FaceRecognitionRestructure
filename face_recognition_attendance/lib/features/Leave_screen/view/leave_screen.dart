import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/leave_screen/controller/leave_controller.dart';
import 'package:face_recognition_attendance/features/leave_screen/model/leave_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Leave": total approved days, then All / Pending / History tabs.
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

enum _LeaveTab { all, pending, history }

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveController _controller = Get.find<LeaveController>();
  _LeaveTab _tab = _LeaveTab.all;

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Leave',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _LeaveSummary(controller: _controller),
          ),
          _LeaveTabBar(
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          Expanded(
            child: Obx(() {
              final items = _itemsFor(_tab);

              if (items.isEmpty) {
                return const _EmptyState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => _LeaveTile(
                  request: items[index],
                  // Pending -> edit form. Approved -> read-only details.
                  onTap: () => Get.toNamed(
                    items[index].status == LeaveStatus.pending
                        ? AppRoutes.requestLeave
                        : AppRoutes.leaveDetail,
                    arguments: items[index].id,
                  ),
                  onCancel: items[index].status == LeaveStatus.pending
                      ? () => _controller.cancelRequest(items[index].id)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: RequestColors.primary,
        onPressed: () => Get.toNamed(AppRoutes.requestLeave),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  List<LeaveRequest> _itemsFor(_LeaveTab tab) {
    switch (tab) {
      case _LeaveTab.all:
        return _controller.requests;
      case _LeaveTab.pending:
        return _controller.pending;
      case _LeaveTab.history:
        return _controller.history;
    }
  }
}

class _LeaveSummary extends StatelessWidget {
  const _LeaveSummary({required this.controller});

  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx(
          () => _TotalCircle(total: controller.totalApprovedDays),
        ),
        const SizedBox(width: 24),
        const Expanded(child: _NoLeaveTypeBadge()),
      ],
    );
  }
}

class _TotalCircle extends StatelessWidget {
  const _TotalCircle({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: RequestColors.textSecondary, width: 3),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$total',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: RequestColors.textPrimary,
              ),
            ),
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 12,
                color: RequestColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown until leave types (Annual, Sick, ...) are configured.
/// TODO: replace with the real leave-type breakdown once that backend exists.
class _NoLeaveTypeBadge extends StatelessWidget {
  const _NoLeaveTypeBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 40,
                color: RequestColors.textSecondary,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: RequestColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'No Leave Type',
          style: TextStyle(fontSize: 11, color: RequestColors.textSecondary),
        ),
      ],
    );
  }
}

class _LeaveTabBar extends StatelessWidget {
  const _LeaveTabBar({required this.selected, required this.onChanged});

  final _LeaveTab selected;
  final ValueChanged<_LeaveTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _tabItem(context, 'All', _LeaveTab.all),
          _tabItem(context, 'Pending', _LeaveTab.pending),
          _tabItem(context, 'History', _LeaveTab.history),
        ],
      ),
    );
  }

  Widget _tabItem(BuildContext context, String label, _LeaveTab tab) {
    final isSelected = tab == selected;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? RequestColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? RequestColors.primary
                  : RequestColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Color(0xFFC7CBD6),
                ),
                Positioned(
                  right: 4,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No records',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You have no record at the moment.',
            style: TextStyle(fontSize: 12, color: RequestColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LeaveTile extends StatelessWidget {
  const _LeaveTile({
    required this.request,
    required this.onTap,
    this.onCancel,
  });

  final LeaveRequest request;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == LeaveStatus.pending;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.dateRangeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? RequestColors.pendingBackground
                          : RequestColors.approvedBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPending
                            ? RequestColors.pendingText
                            : RequestColors.approvedText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: RequestColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    request.scheduleLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                request.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: RequestColors.textSecondary,
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: RequestColors.danger,
                    ),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        color: RequestColors.danger,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
}
