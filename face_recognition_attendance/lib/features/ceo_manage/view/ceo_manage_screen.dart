import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/ceo_manage/controller/ceo_manage_controller.dart';
import 'package:face_recognition_attendance/features/ceo_manage/model/ceo_report_models.dart';
import 'package:face_recognition_attendance/features/ceo_manage/view/ceo_branch_detail_screen.dart';

class CeoManageScreen extends StatelessWidget {
  const CeoManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CeoManageController>()
        ? Get.find<CeoManageController>()
        : Get.put(CeoManageController());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Manage',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
        actions: [
          Obx(() {
            if (controller.isExporting.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Export All Branches (Excel/CSV)',
                  onPressed: () => controller.exportAllBranches(),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share All Branches Report',
                  onPressed: () => controller.shareAllBranches(),
                ),
                const SizedBox(width: 8),
              ],
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchBranchesSummary(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector Section
              _buildPeriodSelector(context, controller, isDark),
              const SizedBox(height: 18),

              // Company Overview Metrics Card
              Obx(() {
                final summary = controller.branchesSummary.value?.companySummary;
                if (summary == null) return const SizedBox.shrink();
                return _buildCompanySummaryCard(summary, isDark);
              }),
              const SizedBox(height: 20),

              // Branch Cards List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Branches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  Obx(() {
                    final count = controller.branchesSummary.value?.branches.length ?? 0;
                    return Text(
                      '$count Branches',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (controller.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final branches = controller.branchesSummary.value?.branches ?? [];
                if (branches.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Text(
                      'No branches found.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return _buildBranchCard(context, controller, branch, isDark);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    CeoManageController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Period',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showPeriodPickerModal(context, controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF25252D) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Obx(() => Text(
                          controller.periodDisplayLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        )),
                  ],
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPeriodPickerModal(BuildContext context, CeoManageController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      {'key': 'this_month', 'label': 'This Month'},
      {'key': 'select_month', 'label': 'Select Month'},
      {'key': 'last_3_months', 'label': 'Last 3 Months'},
      {'key': 'last_6_months', 'label': 'Last 6 Months'},
      {'key': 'this_year', 'label': 'This Year'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Report Period',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = controller.selectedPeriod.value == opt['key'];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    opt['label']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.ink),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    Get.back();
                    controller.setPeriod(opt['key']!, context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanySummaryCard(CompanySummary summary, bool isDark) {
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
                'Company Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              Text(
                '${summary.totalEmployees} Employees across ${summary.totalBranches} Branches',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg Attendance',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.attendanceRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg On-Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.onTimeRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3B82F6),
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

  Widget _buildBranchCard(
    BuildContext context,
    CeoManageController controller,
    BranchCardSummary branch,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.to(() => CeoBranchDetailScreen(
                branchId: branch.id,
                branchName: branch.name,
              ));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF25252D) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branch Name & Employee Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      branch.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${branch.employeeCount} Employees',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Manager Name
              Text(
                'Manager: ${branch.managerName}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Attendance Rate & On-Time Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Rate',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${branch.attendanceRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'On-Time Rate',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${branch.onTimeRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Buttons Row: [Download] [Share]
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Download', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.exportBranch(branch.id, branch.name),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Share', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.shareBranch(branch.id, branch.name),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
