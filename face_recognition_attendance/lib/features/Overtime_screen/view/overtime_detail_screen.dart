import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/controller/overtime_controller.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OvertimeDetailScreen extends StatefulWidget {
  const OvertimeDetailScreen({super.key});

  @override
  State<OvertimeDetailScreen> createState() => _OvertimeDetailScreenState();
}

class _OvertimeDetailScreenState extends State<OvertimeDetailScreen> {
  final ApiService _apiService = ApiService();

  String? _requestId;
  OvertimeRequest? _request;
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
    if (args is OvertimeRequest) {
      _request = args;
      _requestId = args.id;
      _isLoading = false;
    } else if (args is String) {
      _requestId = args;
      if (Get.isRegistered<OvertimeController>()) {
        final cached = Get.find<OvertimeController>().findById(args);
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
      final res = await _apiService.get('/requests/overtime/$_requestId/');
      if (res is Map && mounted) {
        setState(() {
          _request = OvertimeRequest.fromJson(Map<String, dynamic>.from(res));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching overtime request detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleReview(String status) async {
    if (_request == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final res = await _apiService.post(
        '/requests/overtime/${_request!.id}/review/',
        body: {'status': status},
      );

      if (res is Map && res['error'] == null) {
        final updated = OvertimeRequest.fromJson(
          Map<String, dynamic>.from(res),
        );
        if (mounted) {
          setState(() {
            _request = updated;
            _isSubmitting = false;
          });
        }

        if (Get.isRegistered<OvertimeController>()) {
          Get.find<OvertimeController>().fetchRequests();
        }
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications(
            background: true,
          );
        }

        final isApprove = status == 'approved';
        RequestSnack.show(
          null,
          isApprove
              ? 'Overtime request for ${_request!.fullName} was approved.'
              : 'Overtime request for ${_request!.fullName} was rejected.',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const RequestScaffold(
        title: 'Overtime',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final request = _request;
    if (request == null) {
      return const RequestScaffold(
        title: 'Overtime',
        body: Center(child: Text('This request could not be found.')),
      );
    }

    final isPending = request.status == OvertimeStatus.pending;
    final isApproved = request.status == OvertimeStatus.approved;
    final canReview = ['leader', 'manager', 'ceo'].contains(_currentUserRole);

    Color statusColor = RequestColors.pendingText;
    if (isApproved) {
      statusColor = RequestColors.approvedStatus;
    } else if (request.status == OvertimeStatus.rejected) {
      statusColor = RequestColors.danger;
    }

    return RequestScaffold(
      title: 'Overtime',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RequestField(label: 'Full Name', value: request.fullName),
          const SizedBox(height: 14),
          RequestField(label: 'EmployeeID', value: request.employeeId),
          const SizedBox(height: 14),
          RequestField(
            label: 'Date',
            value: DateText.monthShortDay(request.date),
          ),
          const SizedBox(height: 14),
          RequestField(label: 'Time', value: request.timeRangeLabel),
          const SizedBox(height: 14),
          RequestField(label: 'Duration', value: request.durationLabel),
          const SizedBox(height: 14),
          RequestField(label: 'Reason', value: request.reason, multiline: true),
          if (request.hasAttachment) ...[
            const SizedBox(height: 14),
            RequestField(
              label: 'Supporting Document',
              value: request.attachmentName ?? 'Document Attached',
              valueColor: RequestColors.primary,
              valueWeight: FontWeight.w600,
            ),
          ],
          const SizedBox(height: 14),
          RequestField(
            label: 'Status',
            value: request.status.label,
            valueColor: statusColor,
            valueWeight: FontWeight.w600,
          ),
          if (isPending && canReview) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleReview('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RequestColors.danger,
                      side: const BorderSide(
                        color: RequestColors.danger,
                        width: 1.5,
                      ),
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
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleReview('approved'),
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
          ],
        ],
      ),
    );
  }
}
