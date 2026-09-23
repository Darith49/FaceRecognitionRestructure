import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/features/ceo_panel/controller/ceo_panel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CeoControlPanelScreen extends GetView<CeoPanelController> {
  const CeoControlPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Get.back(),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 22),
            SizedBox(width: 8),
            Text(
              'CEO Control Panel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh Telemetry',
            onPressed: () => controller.fetchDashboardData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.employees.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: () => controller.fetchDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Executive Banner
                _buildExecutiveBanner(context),
                const SizedBox(height: 20),

                // 2. High-Level KPI Telemetry Grid
                _buildKpiGrid(context),
                const SizedBox(height: 24),

                // 3. Quick Executive Actions Grid
                _buildSectionHeader('Executive Actions', 'System configuration and resource creation'),
                const SizedBox(height: 12),
                _buildQuickActionsGrid(context),
                const SizedBox(height: 24),

                // 4. Biometric Security & Anti-Spoofing Engine
                _buildSectionHeader('Biometric Security & Anti-Spoofing', 'kby-ai on-device matching engine'),
                const SizedBox(height: 12),
                _buildBiometricEngineCard(context),
                const SizedBox(height: 24),

                // 5. Pending Executive Approvals (if any)
                if (controller.pendingApprovalsCount > 0) ...[
                  _buildSectionHeader('Pending Approvals', '${controller.pendingApprovalsCount} requests requiring executive decision'),
                  const SizedBox(height: 12),
                  _buildPendingApprovalsList(context),
                  const SizedBox(height: 24),
                ],

                // 6. Branch Geofences Telemetry
                _buildSectionHeader('Branch Locations & Geofences', '${controller.totalBranches} operational facilities'),
                const SizedBox(height: 12),
                _buildBranchGeofencesList(context),
                const SizedBox(height: 24),

                // 7. Department Structure Overview
                _buildSectionHeader('Departments & Structure', '${controller.totalDepartments} organizational divisions'),
                const SizedBox(height: 12),
                _buildDepartmentList(context),
                const SizedBox(height: 24),

                // 8. Recent System Activity Feed
                _buildSectionHeader('System Audit & Attendance Stream', 'Real-time on-device transaction log'),
                const SizedBox(height: 12),
                _buildActivityAuditLog(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── 1. Executive Banner ───────────────────────────────────────────────────
  Widget _buildExecutiveBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF4ADE80), size: 14),
                    SizedBox(width: 5),
                    Text(
                      'STRICT 1:1 SECURITY ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '100% ON-DEVICE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE2E8F0),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Executive Command Hub',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Full enterprise control over branches, workforce, geofences, and biometric verification thresholds.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. KPI Grid ───────────────────────────────────────────────────────────
  Widget _buildKpiGrid(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 500;
      final crossAxisCount = isWide ? 4 : 2;

      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 1.4 : 1.35,
        children: [
          _buildKpiCard(
            title: 'Total Workforce',
            value: controller.totalEmployees.toString(),
            subtitle: '${controller.activeEmployees} active accounts',
            icon: Icons.groups_rounded,
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
          ),
          _buildKpiCard(
            title: 'Present Today',
            value: controller.presentToday.toString(),
            subtitle: '${controller.onLeaveToday} approved leave',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF059669),
            bg: const Color(0xFFECFDF5),
          ),
          _buildKpiCard(
            title: 'Biometric Enrolled',
            value: '${(controller.biometricEnrollmentRate * 100).toStringAsFixed(0)}%',
            subtitle: '${controller.biometricEnrolledCount} / ${controller.totalEmployees} registered',
            icon: Icons.face_rounded,
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFF5F3FF),
          ),
          _buildKpiCard(
            title: 'Branches & Hubs',
            value: controller.totalBranches.toString(),
            subtitle: '${controller.totalDepartments} departments',
            icon: Icons.account_tree_rounded,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
          ),
        ],
      );
    });
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 3. Quick Actions Grid ─────────────────────────────────────────────────
  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _ActionItem(
        title: 'New Branch',
        subtitle: 'Configure GPS geofence',
        icon: Icons.add_business_rounded,
        color: const Color(0xFF0D9488),
        onTap: () => Get.toNamed(AppRoutes.createBranch),
      ),
      _ActionItem(
        title: 'New Department',
        subtitle: 'Add team division',
        icon: Icons.domain_add_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => Get.toNamed(AppRoutes.createDepartment),
      ),
      _ActionItem(
        title: 'Add Employee',
        subtitle: 'Onboard team member',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () => Get.toNamed(AppRoutes.createEmployee),
      ),
      _ActionItem(
        title: 'Branch Hub',
        subtitle: 'Manage all sites',
        icon: Icons.apartment_rounded,
        color: const Color(0xFFD97706),
        onTap: () => Get.toNamed(AppRoutes.branchList),
      ),
      _ActionItem(
        title: 'Departments',
        subtitle: 'Structure & managers',
        icon: Icons.category_rounded,
        color: const Color(0xFF0284C7),
        onTap: () => Get.toNamed(AppRoutes.departmentList),
      ),
      _ActionItem(
        title: 'Employees',
        subtitle: 'Workforce roster',
        icon: Icons.badge_rounded,
        color: const Color(0xFF475569),
        onTap: () => Get.toNamed(AppRoutes.employeeList),
      ),
      _ActionItem(
        title: 'Face Scanner',
        subtitle: 'Biometric capture',
        icon: Icons.document_scanner_rounded,
        color: const Color(0xFFE11D48),
        onTap: () => Get.toNamed(AppRoutes.faceCapture),
      ),
      _ActionItem(
        title: 'Approvals Desk',
        subtitle: 'Review incoming requests',
        icon: Icons.rule_rounded,
        color: const Color(0xFF059669),
        onTap: () => Get.toNamed(AppRoutes.request),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 550;
      final count = isWide ? 4 : 2;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 2.2 : 2.0,
        ),
        itemBuilder: (context, idx) {
          final item = actions[idx];
          return InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // ─── 4. Biometric Security & Threshold Controls ─────────────────────────────
  Widget _buildBiometricEngineCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: Color(0xFF7C3AED), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'kby-ai Face Recognition Engine',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '128-d spatial normalized template • Cosine similarity matcher',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF7C3AED)),
                tooltip: 'Configure Thresholds',
                onPressed: () => _showThresholdConfigDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Threshold Status Chips
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identity Match Req.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(controller.identifyThreshold.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('(Strict 1:1)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liveness & Anti-Spoof',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(controller.livenessThreshold.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('(Active)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Enrolled Profiles Summary Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${controller.biometricEnrolledCount} employees have active biometric templates registered. Anti-buddy punching is actively enforcing identity mismatch rejection.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThresholdConfigDialog(BuildContext context) {
    double idVal = controller.identifyThreshold.value;
    double liveVal = controller.livenessThreshold.value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFF7C3AED), size: 22),
              SizedBox(width: 8),
              Text('Security Thresholds', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust required biometric match precision and anti-spoofing sensitivity.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Identity Match Threshold', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${(idVal * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                ],
              ),
              Slider(
                value: idVal,
                min: 0.50,
                max: 0.95,
                divisions: 9,
                activeColor: const Color(0xFF7C3AED),
                onChanged: (v) => setDialogState(() => idVal = v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Liveness & Sharpness', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${(liveVal * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ],
              ),
              Slider(
                value: liveVal,
                min: 0.40,
                max: 0.90,
                divisions: 10,
                activeColor: const Color(0xFF059669),
                onChanged: (v) => setDialogState(() => liveVal = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                controller.updateSecurityThresholds(identify: idVal, liveness: liveVal);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Thresholds'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. Pending Approvals List ─────────────────────────────────────────────
  Widget _buildPendingApprovalsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.pendingLeaves.take(3).length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, idx) {
          final item = controller.pendingLeaves[idx];
          final leaveId = (item['id'] as num?)?.toInt() ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_busy_rounded, color: Color(0xFFD97706), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['employee_name'] ?? 'Team Member',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['leave_type'] ?? 'Leave'} • ${item['start_date'] ?? ''} to ${item['end_date'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 26),
                  tooltip: 'Approve',
                  onPressed: () => controller.quickApproveLeave(leaveId),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 26),
                  tooltip: 'Reject',
                  onPressed: () => controller.quickRejectLeave(leaveId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── 6. Branch Geofences List ──────────────────────────────────────────────
  Widget _buildBranchGeofencesList(BuildContext context) {
    return Column(
      children: controller.branches.map((b) {
        final radius = (b['radius'] as num?)?.toDouble() ?? 500.0;
        final lat = (b['latitude'] as num?)?.toDouble();
        final lng = (b['longitude'] as num?)?.toDouble();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFF0F766E), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b['name'] ?? 'Branch Site',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Geofence: ${radius.toStringAsFixed(0)}m',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      b['address'] ?? 'Official company site',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lat != null && lng != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── 7. Department List ───────────────────────────────────────────────────
  Widget _buildDepartmentList(BuildContext context) {
    return Column(
      children: controller.departments.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    d['code'] ?? 'DIV',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d['name'] ?? 'Department',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${d['employee_count'] ?? 0} members',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manager: ${d['manager_name'] ?? 'Assigned Manager'}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── 8. System Activity Audit Log ──────────────────────────────────────────
  Widget _buildActivityAuditLog(BuildContext context) {
    final recent = controller.attendanceRecords.reversed.take(5).toList();

    if (recent.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No attendance records recorded yet today.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, idx) {
          final item = recent[idx];
          final hasCheckOut = item['check_out_time'] != null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasCheckOut ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasCheckOut ? Icons.logout_rounded : Icons.login_rounded,
                    color: hasCheckOut ? const Color(0xFF2563EB) : const Color(0xFF059669),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['employee_name'] ?? 'Employee',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasCheckOut
                            ? 'Checked Out: ${item['check_out_time']}'
                            : 'Checked In: ${item['check_in_time'] ?? item['date']}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VERIFIED 1:1',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
