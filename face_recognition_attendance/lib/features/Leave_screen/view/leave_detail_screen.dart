import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/core/widgets/app_avatar.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Leave_screen/controller/leave_controller.dart';
import 'package:face_recognition_attendance/features/Leave_screen/model/leave_request.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveDetailScreen extends StatefulWidget {
  const LeaveDetailScreen({super.key});

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  final ApiService _apiService = ApiService();

  String? _requestId;
  LeaveRequest? _request;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _parseArguments();
    _checkUserRole();
    _fetchDetail();
  }

  void _parseArguments() {
    final args = Get.arguments;
    if (args is LeaveRequest) {
      _request = args;
      _requestId = args.id;
      _isLoading = false;
    } else if (args is String) {
      _requestId = args;
      if (Get.isRegistered<LeaveController>()) {
        final cached = Get.find<LeaveController>().findById(args);
        if (cached != null) {
          _request = cached;
          _isLoading = false;
        }
      }
    } else if (args is num) {
      _requestId = args.toString();
    }
  }

  Future<void> _checkUserRole() async {
    try {
      String role = '';
      if (Get.isRegistered<LoginController>()) {
        role =
            Get.find<LoginController>().currentuser.value?.role.name
                .toLowerCase() ??
            '';
      }
      if (role.isEmpty) {
        final user = await SecureStorageService().getCachedUserData();
        role = (user?['role']?.toString() ?? '').toLowerCase();
      }
      if (mounted) {
        setState(() {
          _currentUserRole = role;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDetail() async {
    if (_requestId == null || _requestId!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _apiService.get('/requests/leave/$_requestId/');
      if (res is Map && mounted) {
        setState(() {
          _request = LeaveRequest.fromJson(Map<String, dynamic>.from(res));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leave request detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleReview(String status, {String? notes}) async {
    if (_request == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final body = <String, dynamic>{
        'status': status,
        if (notes != null && notes.isNotEmpty) 'review_notes': notes,
      };

      final res = await _apiService.post(
        '/requests/leave/${_request!.id}/review/',
        body: body,
      );

      if (res is Map && res['error'] == null) {
        final updated = LeaveRequest.fromJson(Map<String, dynamic>.from(res));
        if (mounted) {
          setState(() {
            _request = updated;
            _isSubmitting = false;
          });
        }

        if (Get.isRegistered<LeaveController>()) {
          Get.find<LeaveController>().fetchRequests();
        }
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications(
            background: true,
          );
        }

        final isApprove = status == 'approved';
        Get.snackbar(
          isApprove ? 'Request Approved' : 'Request Rejected',
          isApprove
              ? 'Leave request for ${_request!.fullName} was approved.'
              : 'Leave request for ${_request!.fullName} was rejected.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: isApprove
              ? RequestColors.approvedStatus
              : RequestColors.danger,
          colorText: Colors.white,
          icon: Icon(
            isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white,
          ),
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: const Duration(seconds: 3),
        );
      } else {
        final errMsg = res is Map
            ? res['error']?.toString() ?? 'Failed'
            : 'Failed';
        Get.snackbar(
          'Error',
          errMsg,
          backgroundColor: RequestColors.danger,
          colorText: Colors.white,
        );
        if (mounted) setState(() => _isSubmitting = false);
      }
    } catch (e) {
      debugPrint('Error reviewing leave: $e');
      Get.snackbar(
        'Error',
        'Action failed: $e',
        backgroundColor: RequestColors.danger,
        colorText: Colors.white,
      );
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showRejectDialog() {
    final noteController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: RequestColors.danger, size: 24),
            SizedBox(width: 8),
            Text(
              'Reject Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to reject this leave request? You can optionally provide a reason.',
              style: TextStyle(
                fontSize: 13,
                color: RequestColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (optional)',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: RequestColors.textSecondary,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: RequestColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final notes = noteController.text.trim();
              Get.back();
              _handleReview('rejected', notes: notes);
            },
            child: const Text(
              'Confirm Reject',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: RequestColors.approvedStatus,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Approve Leave',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Approve ${_request!.fullName}\'s request for ${_request!.scheduleLabel}?',
          style: const TextStyle(
            fontSize: 14,
            color: RequestColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: RequestColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestColors.approvedStatus,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Get.back();
              _handleReview('approved');
            },
            child: const Text(
              'Approve',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelRequest() {
    if (_request == null || _isSubmitting) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSubmitting = true);
              try {
                if (Get.isRegistered<LeaveController>()) {
                  final ok = await Get.find<LeaveController>().cancelRequest(
                    _request!.id,
                  );
                  if (ok) {
                    Get.back();
                    Get.snackbar(
                      'Request Cancelled',
                      'Your leave request has been cancelled successfully. You can now submit a new request.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: const Color(0xFF10B981),
                      colorText: Colors.white,
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      duration: const Duration(seconds: 4),
                    );
                    return;
                  } else {
                    final err =
                        Get.find<LeaveController>()
                            .errorMessage
                            .value
                            .isNotEmpty
                        ? Get.find<LeaveController>().errorMessage.value
                        : 'Failed to cancel the leave request. Please try again.';
                    Get.snackbar(
                      'Cancellation Failed',
                      err,
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: const Color(0xFFEF4444),
                      colorText: Colors.white,
                      icon: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                      ),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      duration: const Duration(seconds: 4),
                    );
                  }
                } else {
                  await _apiService.delete('/requests/leave/${_request!.id}/');
                  Get.back();
                  Get.snackbar(
                    'Request Cancelled',
                    'Your leave request has been cancelled successfully. You can now submit a new request.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: const Color(0xFF10B981),
                    colorText: Colors.white,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                    ),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                    duration: const Duration(seconds: 4),
                  );
                  return;
                }
              } catch (e) {
                Get.snackbar(
                  'Cancellation Failed',
                  e is ApiException
                      ? e.message
                      : 'Failed to cancel the leave request. Please try again.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: const Color(0xFFEF4444),
                  colorText: Colors.white,
                  icon: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                  ),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                  duration: const Duration(seconds: 4),
                );
              } finally {
                if (mounted) {
                  setState(() => _isSubmitting = false);
                }
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case LeaveStatus.approved:
        bg = RequestColors.approvedStatus.withValues(alpha: 0.12);
        fg = RequestColors.approvedStatus;
        label = 'Approved';
        icon = Icons.check_circle_outline_rounded;
        break;
      case LeaveStatus.rejected:
        bg = RequestColors.danger.withValues(alpha: 0.12);
        fg = RequestColors.danger;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case LeaveStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Pending';
        icon = Icons.access_time_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final isPm = h >= 12;
        final h12 = h % 12 == 0 ? 12 : h % 12;
        final mStr = m.toString().padLeft(2, '0');
        return '$h12:$mStr ${isPm ? 'PM' : 'AM'}';
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _request == null) {
      return const RequestScaffold(
        title: 'Leave Details',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return const RequestScaffold(
        title: 'Leave Details',
        body: Center(
          child: Text(
            'This request could not be found.',
            style: TextStyle(fontSize: 14, color: RequestColors.textSecondary),
          ),
        ),
      );
    }

    final req = _request!;
    final isPending = req.status == LeaveStatus.pending;

    // Strict 3-tier approval hierarchy check:
    // - Employee request -> Leader ONLY
    // - Leader request -> Manager ONLY
    // - Manager request -> CEO ONLY
    final requesterRole = (req.employeeRole ?? 'employee').toLowerCase();
    final isEligibleReviewer =
        (requesterRole == 'employee' && _currentUserRole == 'leader') ||
        (requesterRole == 'leader' && _currentUserRole == 'manager') ||
        (requesterRole == 'manager' && _currentUserRole == 'ceo');
    final canReview = isEligibleReviewer && isPending;

    final currentUid = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>().currentuser.value?.uid
        : null;
    final currentEmail = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>().currentuser.value?.email
        : null;
    final isOwner =
        (currentUid != null &&
            (req.employeeUid == currentUid || req.employeeId == currentUid)) ||
        (currentEmail != null && req.employeeEmail == currentEmail);
    final canCancel = isPending && isOwner;

    final sessionName = req.session == 1
        ? 'Section 1 (Morning)'
        : (req.session == 2 ? 'Section 2 (Afternoon)' : 'Full Day');

    final isEarlyLeave = req.leaveMode == 'early_leave';
    final earlyTimeDisplay =
        isEarlyLeave &&
            req.earlyLeaveTime != null &&
            req.earlyLeaveTime!.isNotEmpty
        ? _formatTime(req.earlyLeaveTime)
        : null;

    return RequestScaffold(
      title: 'Leave Details',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Requester Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        profileUrl: req.employeeProfileUrl,
                        name: req.fullName.isNotEmpty
                            ? req.fullName
                            : 'Employee',
                        size: 54,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.fullName.isNotEmpty
                                  ? req.fullName
                                  : 'Employee',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: RequestColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (req.employeeRole != null &&
                                    req.employeeRole!.isNotEmpty)
                                  req.employeeRole!.toUpperCase(),
                                if (req.employeeDepartment != null &&
                                    req.employeeDepartment!.isNotEmpty)
                                  req.employeeDepartment!
                                else if (req.employeeBranch != null &&
                                    req.employeeBranch!.isNotEmpty)
                                  req.employeeBranch!,
                              ].join(' • '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: RequestColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (req.employeeId.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'ID: ${req.employeeId}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: RequestColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildStatusBadge(req.status),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Information Section Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _DetailFieldItem(
                        label: 'Target Date',
                        value: req.dateRangeLabel,
                      ),
                      const SizedBox(height: 14),
                      _DetailFieldItem(
                        label: 'Work Section',
                        value: sessionName,
                      ),
                      const SizedBox(height: 14),
                      _DetailFieldItem(
                        label: 'Leave Mode',
                        value: isEarlyLeave && earlyTimeDisplay != null
                            ? 'Leave Early at $earlyTimeDisplay'
                            : 'Full Section Leave',
                        valueColor: isEarlyLeave
                            ? RequestColors.primary
                            : RequestColors.textPrimary,
                        valueWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 14),
                      _DetailFieldItem(
                        label: 'Total Days',
                        value:
                            '${req.dayCount} day${req.dayCount == 1 ? '' : 's'}',
                      ),
                      const SizedBox(height: 14),
                      _DetailFieldItem(
                        label: 'Reason',
                        value: req.reason.trim().isNotEmpty
                            ? req.reason
                            : 'No reason provided',
                        multiline: true,
                      ),
                      if (req.reviewerName != null &&
                          req.reviewerName!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailFieldItem(
                          label: 'Reviewed By',
                          value: req.reviewerName!,
                        ),
                      ],
                      if (req.reviewNotes != null &&
                          req.reviewNotes!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailFieldItem(
                          label: 'Review Notes',
                          value: req.reviewNotes!,
                          multiline: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar for Supervisor
          if (canReview)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Reject Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RequestColors.danger,
                          side: const BorderSide(
                            color: RequestColors.danger,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _showRejectDialog,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Approve Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RequestColors.approvedStatus,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _showApproveDialog,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          _isSubmitting ? 'Processing...' : 'Approve',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!canReview && canCancel)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RequestColors.danger,
                      side: const BorderSide(
                        color: RequestColors.danger,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _confirmCancelRequest,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text(
                      'Cancel Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
}

class _DetailFieldItem extends StatelessWidget {
  const _DetailFieldItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight = FontWeight.w600,
    this.multiline = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight valueWeight;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: RequestColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: multiline ? 80.0 : 46.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueWeight,
              color: valueColor ?? RequestColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
