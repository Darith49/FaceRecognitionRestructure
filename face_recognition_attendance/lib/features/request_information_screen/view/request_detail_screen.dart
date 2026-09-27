import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final ApiService _apiService = ApiService();
  final PermissionController _controller = Get.find<PermissionController>();
  final TextEditingController _reasonController = TextEditingController();

  String? _requestId;
  PermissionRequest? _request;
  DateTime _date = DateTime.now();
  String _schedule = kSessionSchedules.first;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _parseArguments();
    _checkUserRole();
    _fetchDetail();
    _reasonController.addListener(_refresh);
  }

  void _parseArguments() {
    final args = Get.arguments;
    if (args is PermissionRequest) {
      _request = args;
      _requestId = args.id;
      _initFields(args);
      _isLoading = false;
    } else if (args is String) {
      _requestId = args;
      final cached = _controller.findById(args);
      if (cached != null) {
        _request = cached;
        _initFields(cached);
        _isLoading = false;
      }
    } else if (args is num) {
      _requestId = args.toString();
    }
  }

  void _initFields(PermissionRequest r) {
    _date = r.date;
    _schedule = r.schedule;
    _reasonController.text = r.reason;
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
      final res = await _apiService.get('/requests/permissions/$_requestId/');
      if (res is Map && mounted) {
        final req = PermissionRequest.fromJson(Map<String, dynamic>.from(res));
        setState(() {
          _request = req;
          _initFields(req);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching permission request detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.removeListener(_refresh);
    _reasonController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _hasChanges {
    final request = _request;
    if (request == null) return false;
    return DateText.ymd(_date) != DateText.ymd(request.date) ||
        _schedule != request.schedule ||
        _reasonController.text.trim() != request.reason;
  }

  Future<void> _handleReview(String status) async {
    if (_request == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final res = await _apiService.post(
        '/requests/permissions/${_request!.id}/review/',
        body: {'status': status},
      );

      if (res is Map && res['error'] == null) {
        final updated = PermissionRequest.fromJson(
          Map<String, dynamic>.from(res),
        );
        if (mounted) {
          setState(() {
            _request = updated;
            _isSubmitting = false;
          });
        }

        _controller.fetchRequests();
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications(
            background: true,
          );
        }

        final isApprove = status == 'approved';
        RequestSnack.show(
          null,
          isApprove
              ? 'Permission request for ${_request!.fullName} was approved.'
              : 'Permission request for ${_request!.fullName} was rejected.',
        );
      } else {
        setState(() => _isSubmitting = false);
        RequestSnack.show(
          null,
          res is Map && res['error'] != null
              ? res['error'].toString()
              : 'Failed to update request status.',
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      RequestSnack.show(null, 'Network error. Please try again.');
    }
  }

  Future<void> _save() async {
    final request = _request!;
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      RequestSnack.show(null, 'Enter the reason for your request.');
      return;
    }

    final wasApproved = request.status == RequestStatus.approved;
    if (wasApproved) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Change this approved request?'),
          content: const Text(
            'After you save, the request goes back to Pending and needs approval again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Keep as approved'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Yes, change it'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final error = await _controller.updateRequest(
      id: request.id,
      date: _date,
      schedule: _schedule,
      reason: reason,
    );

    if (error == null) {
      setState(() {
        _request = _controller.findById(request.id);
      });
      RequestSnack.show(
        null,
        wasApproved
            ? 'Saved. The request is now Pending.'
            : 'Your request was updated.',
      );
    } else {
      RequestSnack.show(null, error);
    }
  }

  Future<void> _confirmCancel() async {
    final request = _request!;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text(
          'The request will be removed from your pending list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep request'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Yes, cancel',
              style: TextStyle(color: RequestColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _controller.cancelRequest(request.id);
    Get.back();
    RequestSnack.show(null, 'Your request was cancelled.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const RequestScaffold(
        title: 'Permission',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final request = _request;
    if (request == null) {
      return const RequestScaffold(
        title: 'Permission',
        body: Center(child: Text('This request could not be found.')),
      );
    }

    final isPending = request.status == RequestStatus.pending;
    final canReview = ['leader', 'manager', 'ceo'].contains(_currentUserRole);
    final isOwnRequest = _currentUserRole == 'employee' || !canReview;
    final editable = !request.hasPassed && isOwnRequest;

    return RequestScaffold(
      title: 'Permission',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!editable && isOwnRequest && request.hasPassed)
                  const _LockedNote(),
                RequestField(label: 'Request Type', value: request.type),
                const SizedBox(height: 14),
                RequestField(label: 'Full Name', value: request.fullName),
                const SizedBox(height: 14),
                RequestField(label: 'EmployeeID', value: request.employeeId),
                const SizedBox(height: 14),
                if (editable)
                  ..._buildEditableFields(request)
                else ...[
                  RequestField(label: 'Time', value: request.timeLabel),
                  const SizedBox(height: 14),
                  RequestField(
                    label: 'Reason',
                    value: request.reason,
                    multiline: true,
                  ),
                  const SizedBox(height: 14),
                ],
                RequestField(
                  label: 'Status',
                  value: request.status.label,
                  valueColor: isPending
                      ? RequestColors.pendingText
                      : (request.status == RequestStatus.approved
                            ? RequestColors.approvedStatus
                            : RequestColors.danger),
                  valueWeight: FontWeight.w600,
                ),
                if (!isPending && request.authorizedAt != null) ...[
                  const SizedBox(height: 14),
                  RequestField(
                    label: 'Authorized Date',
                    value: DateText.stamp(request.authorizedAt!),
                  ),
                ],
              ],
            ),
          ),
          if (isPending && canReview)
            _buildSupervisorReviewActions()
          else if (editable || (isPending && isOwnRequest))
            _buildEmployeeActions(editable, isPending),
        ],
      ),
    );
  }

  Widget _buildSupervisorReviewActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => _handleReview('rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RequestColors.danger,
                side: const BorderSide(color: RequestColors.danger, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleReview('approved'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RequestColors.approvedStatus,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Approve',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEditableFields(PermissionRequest request) {
    return [
      const RequestLabel('Date'),
      RequestDateField(
        value: _date,
        onChanged: (date) => setState(() => _date = date),
      ),
      const SizedBox(height: 14),
      const RequestLabel('Schedule'),
      RequestDropdownField<String>(
        value: _schedule,
        items: scheduleOptionsFor(request.schedule)
            .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
            .toList(),
        onChanged: (schedule) => setState(() => _schedule = schedule),
      ),
      const SizedBox(height: 14),
      const RequestLabel('Reason'),
      RequestTextArea(controller: _reasonController),
      const SizedBox(height: 14),
    ];
  }

  Widget _buildEmployeeActions(bool editable, bool isPending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editable)
            RequestButton(
              label: 'Save changes',
              onPressed: _hasChanges ? _save : null,
            ),
          if (editable && isPending) const SizedBox(height: 10),
          if (isPending)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _confirmCancel,
                style: TextButton.styleFrom(
                  foregroundColor: RequestColors.danger,
                ),
                child: const Text('Cancel request'),
              ),
            ),
        ],
      ),
    );
  }
}

class _LockedNote extends StatelessWidget {
  const _LockedNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: RequestColors.softSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: RequestColors.textSecondary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This request date has passed and cannot be changed.',
                style: TextStyle(
                  fontSize: 12,
                  color: RequestColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
