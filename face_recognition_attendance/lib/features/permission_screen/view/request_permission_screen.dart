import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Form and History for Permission Requests.
class RequestPermissionScreen extends StatefulWidget {
  const RequestPermissionScreen({super.key});

  @override
  State<RequestPermissionScreen> createState() =>
      _RequestPermissionScreenState();
}

class _RequestPermissionScreenState extends State<RequestPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final PermissionController _controller;
  late final TabController _tabController;
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _date = DateTime.now();
  String _schedule = kSessionSchedules.first;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<PermissionController>()
        ? Get.find<PermissionController>()
        : Get.put(PermissionController());

    _controller.fetchRequests();

    int initialTab = 0;
    final args = Get.arguments;
    if (args is Map && args['tab'] != null) {
      initialTab = (args['tab'] as num).toInt();
    }
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final date = _date;
    final reason = _reasonController.text.trim();

    if (date == null) {
      Get.snackbar(
        'Required',
        'Please select a date for your permission request.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: RequestColors.danger,
        colorText: Colors.white,
      );
      return;
    }

    if (reason.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter the reason for your permission request.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: RequestColors.danger,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _controller.submitPermission(
      date: date,
      schedule: _schedule,
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _reasonController.clear();
      _tabController.animateTo(1);
      Get.snackbar(
        'Success',
        'Your permission request has been submitted to your supervisor.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: RequestColors.approvedStatus,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Submission Failed',
        'Could not submit permission request. Please check your connection and try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: RequestColors.danger,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Permission',
      body: Column(
        children: [
          // Segmented Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: RequestColors.textPrimary,
                unselectedLabelColor: RequestColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Request Permission'),
                  Tab(text: 'History & Status'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: appleCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RequestLabel('Target Date'),
                RequestDateField(
                  value: _date,
                  onChanged: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 16),

                const RequestLabel('Section'),
                RequestDropdownField<String>(
                  value: _schedule,
                  items: kSessionSchedules
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        ),
                      )
                      .toList(),
                  onChanged: (schedule) =>
                      setState(() => _schedule = schedule),
                ),
                const SizedBox(height: 16),

                const RequestLabel('Reason'),
                RequestTextArea(
                  controller: _reasonController,
                  hint: 'Describe the reason for taking permission...',
                ),
                const SizedBox(height: 20),

                RequestButton(
                  label: _isSubmitting ? 'Submitting...' : 'Submit Request',
                  onPressed: _isSubmitting ? () {} : _submit,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Today's Submissions Quick Section
          Obx(() {
            final todayStr = DateText.ymd(DateTime.now());
            final todayRequests = _controller.requests.where((r) {
              return DateText.ymd(r.date) == todayStr;
            }).toList();

            if (todayRequests.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "TODAY'S SUBMISSIONS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final req in todayRequests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildPermissionCard(req),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Obx(() {
      if (_controller.isLoading.value && _controller.requests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final requests = _controller.requests;
      if (requests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  size: 28,
                  color: RequestColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No Permission Requests Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: RequestColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _controller.fetchRequests(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildPermissionCard(requests[index]);
          },
        ),
      );
    });
  }

  Widget _buildPermissionCard(PermissionRequest req) {
    Color statusBg;
    Color statusFg;
    String statusText;

    switch (req.status) {
      case RequestStatus.approved:
        statusBg = RequestColors.approvedBackground;
        statusFg = RequestColors.approvedText;
        statusText = 'Approved';
        break;
      case RequestStatus.rejected:
        statusBg = RequestColors.rejectedBackground;
        statusFg = RequestColors.rejectedText;
        statusText = 'Rejected';
        break;
      case RequestStatus.pending:
        statusBg = const Color(0xFFFEF3C7);
        statusFg = const Color(0xFFD97706);
        statusText = 'Pending';
        break;
    }

    final dateStr = DateText.ymd(req.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appleCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: RequestColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: RequestColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Section: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RequestColors.textSecondary,
                ),
              ),
              Text(
                req.schedule,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: RequestColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reason: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RequestColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  req.reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RequestColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (req.status == RequestStatus.pending) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () async {
                  await _controller.cancelRequest(req.id);
                  await _controller.fetchRequests();
                  Get.snackbar(
                    'Deleted',
                    'Pending permission request was deleted.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: const Color(0xFF1F2937),
                    colorText: Colors.white,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: RequestColors.danger,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Delete Request',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: RequestColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
