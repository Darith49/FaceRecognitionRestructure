import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/ceo_manage/controller/ceo_manage_controller.dart';
import 'package:face_recognition_attendance/features/ceo_manage/model/ceo_report_models.dart';
import 'package:face_recognition_attendance/features/ceo_manage/view/ceo_employee_detail_screen.dart';

class CeoBranchDetailScreen extends StatefulWidget {
  final int branchId;
  final String branchName;

  const CeoBranchDetailScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  State<CeoBranchDetailScreen> createState() => _CeoBranchDetailScreenState();
}

class _CeoBranchDetailScreenState extends State<CeoBranchDetailScreen> {
  final CeoManageController controller = Get.isRegistered<CeoManageController>()
      ? Get.find<CeoManageController>()
      : Get.put(CeoManageController());

  @override
  void initState() {
    super.initState();
    controller.fetchBranchDetail(widget.branchId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          widget.branchName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Branch Excel/CSV',
            onPressed: () => controller.exportBranch(widget.branchId, widget.branchName),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Branch Report',
            onPressed: () => controller.shareBranch(widget.branchId, widget.branchName),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isBranchDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.branchDetail.value;
        if (data == null) {
          return const Center(child: Text('Failed to load branch details.'));
        }

        // Group employees by department while preserving role hierarchy inside
        final Map<String, List<EmployeeItemReport>> deptGroups = {};
        for (final emp in data.employees) {
          final dept = emp.department.isNotEmpty ? emp.department : 'General';
          deptGroups.putIfAbsent(dept, () => []).add(emp);
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchBranchDetail(widget.branchId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch Header Card
                _buildBranchHeaderCard(data, isDark),
                const SizedBox(height: 16),

                // Rates Overview
                Row(
                  children: [
                    Expanded(
                      child: _buildRateCard(
                        title: 'Attendance Rate',
                        rate: data.attendanceRate,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRateCard(
                        title: 'On-Time Rate',
                        rate: data.onTimeRate,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Employees Header
                Text(
                  'Employees & Performance',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),

                if (data.employees.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text(
                      'No employees assigned to this branch.',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  )
                else
                  ...deptGroups.entries.map((entry) {
                    final deptName = entry.key;
                    final empList = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                deptName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : AppColors.ink.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${empList.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: empList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final emp = empList[index];
                            return _buildEmployeeCard(emp, isDark);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBranchHeaderCard(BranchDetailResponse data, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25252D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.branchName,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.periodLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Manager: ${data.managerName}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${data.employeeCount} Employees total',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard({
    required String title,
    required double rate,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25252D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeItemReport emp, bool isDark) {
    Color roleBadgeColor;
    switch (emp.role.toLowerCase()) {
      case 'manager':
        roleBadgeColor = const Color(0xFF8B5CF6);
        break;
      case 'leader':
        roleBadgeColor = const Color(0xFFF59E0B);
        break;
      default:
        roleBadgeColor = const Color(0xFF3B82F6);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Get.to(() => CeoEmployeeDetailScreen(
                employeeId: emp.id,
                employeeName: emp.name,
              ));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF25252D) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Name, Role & Arrow
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: emp.profileUrl != null && emp.profileUrl!.isNotEmpty
                        ? NetworkImage(emp.profileUrl!)
                        : null,
                    child: emp.profileUrl == null || emp.profileUrl!.isEmpty
                        ? Text(
                            emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: roleBadgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                emp.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: roleBadgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              emp.department,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Rates Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Attendance: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${emp.attendanceRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'On-Time: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${emp.onTimeRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Small metric chips (Present, Absent, Leave, Late, OT)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildSmallBadge('P: ${emp.summary.presentDays}d', const Color(0xFF10B981)),
                  _buildSmallBadge('A: ${emp.summary.absentDays}d', const Color(0xFFEF4444)),
                  _buildSmallBadge('L: ${emp.summary.leaveDays}d', const Color(0xFF8B5CF6)),
                  if (emp.summary.lateCount > 0)
                    _buildSmallBadge('Late: ${emp.summary.lateCount}', const Color(0xFFF59E0B)),
                  if (emp.summary.leftEarlyCount > 0)
                    _buildSmallBadge('Early: ${emp.summary.leftEarlyCount}', const Color(0xFFF97316)),
                  if (emp.summary.otCount > 0)
                    _buildSmallBadge('OT: ${emp.summary.otCount}', const Color(0xFF06B6D4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
