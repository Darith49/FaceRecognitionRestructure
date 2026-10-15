import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/attendance_screen/controller/attendance_controller.dart';
import 'package:face_recognition_attendance/features/attendance_screen/model/attendance_record.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color _absentColor = Color(0xFFF15B5B);
const Color _waiveColor = Color(0xFF3AA6F0);
const Color _permissionColor = Color(0xFFC59500);
const Color _lineColor = Color(0xFFE8B93C);

/// Attendance overview: pick Department, Month and Year to see the session totals.
class AttendanceScreen extends GetView<AttendanceController> {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'attendance_title'.tr,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Overview'.tr),
          const SizedBox(height: 10),
          _Caption('Department'.tr),
          Obx(
            () {
              final deptList = controller.departments.isNotEmpty
                  ? controller.departments.toList()
                  : (controller.department.value.isNotEmpty
                      ? [controller.department.value]
                      : ['General']);
              final currentVal = controller.department.value.isNotEmpty &&
                      deptList.contains(controller.department.value)
                  ? controller.department.value
                  : deptList.first;
              return RequestDropdownField<String>(
                value: currentVal,
                fillColor: RequestColors.softSurface,
                icon: Icons.keyboard_arrow_down_rounded,
                items: deptList
                    .map(
                      (name) => DropdownMenuItem<String>(
                        value: name,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (name) {
                  controller.department.value = name;
                  controller.fetchDepartmentSummary();
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _Caption('Date'.tr),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => RequestDropdownField<int>(
                    value: controller.month.value == 0
                        ? null
                        : controller.month.value,
                    hint: 'Month'.tr,
                    fillColor: RequestColors.softSurface,
                    icon: Icons.keyboard_arrow_down_rounded,
                    items: [
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text('All months'.tr),
                      ),
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem<int>(
                          value: m,
                          child: Text(DateText.monthName(m)),
                        ),
                    ],
                    onChanged: (m) {
                      controller.month.value = m;
                      controller.fetchDepartmentSummary();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => RequestDropdownField<int>(
                    value: controller.year.value == 0
                        ? null
                        : controller.year.value,
                    hint: 'Year'.tr,
                    fillColor: RequestColors.softSurface,
                    icon: Icons.keyboard_arrow_down_rounded,
                    items: [
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text('All years'.tr),
                      ),
                      for (final y in controller.years)
                        DropdownMenuItem<int>(value: y, child: Text('$y')),
                    ],
                    onChanged: (y) {
                      controller.year.value = y;
                      controller.fetchDepartmentSummary();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle('Total Sessions'.tr),
              Obx(() {
                if (!controller.isLoading.value) return const SizedBox.shrink();
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: RequestColors.primary,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: RequestColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading summary...'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: RequestColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CountCard(
                        title: 'Absent'.tr,
                        code: 'A',
                        codeColor: _absentColor,
                        count: controller.countOf(AttendanceType.absent),
                        onTap: () => _showDepartmentEmployeesSheet(
                          context,
                          'Absent'.tr,
                          'A',
                          _absentColor,
                          controller.department.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CountCard(
                        title: 'Waive'.tr,
                        code: 'W',
                        codeColor: _waiveColor,
                        count: controller.countOf(AttendanceType.waive),
                        onTap: () => _showDepartmentEmployeesSheet(
                          context,
                          'Waive'.tr,
                          'W',
                          _waiveColor,
                          controller.department.value,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CountCard(
                  title: 'Absent with Permission'.tr,
                  code: 'AP',
                  codeColor: _permissionColor,
                  count: controller.countOf(AttendanceType.absentWithPermission),
                  centered: true,
                  onTap: () => _showDepartmentEmployeesSheet(
                    context,
                    'Absent with Permission'.tr,
                    'AP',
                    _permissionColor,
                    controller.department.value,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showDepartmentEmployeesSheet(
    BuildContext context,
    String categoryTitle,
    String categoryCode,
    Color categoryColor,
    String deptName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DepartmentDrillDownSheet(
        categoryTitle: categoryTitle,
        categoryCode: categoryCode,
        categoryColor: categoryColor,
        departmentName: deptName,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: RequestColors.textPrimary,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: RequestColors.textPrimary,
        ),
      ),
    );
  }
}

/// Card with a title, a colored code (A / W / AP), a gold line and the session count.
class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.title,
    required this.code,
    required this.codeColor,
    required this.count,
    this.centered = false,
    this.onTap,
  });

  final String title;
  final String code;
  final Color codeColor;
  final int count;
  final bool centered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RequestColors.softSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: centered
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: codeColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: codeColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(height: 2, color: _lineColor),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: centered
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$count',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: count == 1 ? ' Session'.tr : ' Sessions'.tr),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  if (!centered)
                    Text(
                      'Tap to view'.tr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                        fontWeight: FontWeight.w500,
                      ),
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

class _DepartmentDrillDownSheet extends StatefulWidget {
  const _DepartmentDrillDownSheet({
    required this.categoryTitle,
    required this.categoryCode,
    required this.categoryColor,
    required this.departmentName,
  });

  final String categoryTitle;
  final String categoryCode;
  final Color categoryColor;
  final String departmentName;

  @override
  State<_DepartmentDrillDownSheet> createState() => _DepartmentDrillDownSheetState();
}

class _DepartmentDrillDownSheetState extends State<_DepartmentDrillDownSheet> {
  late String _selectedFilter;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _todayRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.categoryCode;
    _loadData();
  }

  void _loadData() {
    final db = LocalDatabaseService();
    final allEmps = db.getEmployees();
    final todayStr = DateText.ymd(DateText.nowCambodia());
    final records = db.getAttendanceRecords(date: todayStr);

    final dept = widget.departmentName.trim().toLowerCase();
    var filtered = allEmps.where((e) {
      if (dept.isEmpty || dept == 'all' || dept == 'general') return true;
      final eDept = (e['department'] ?? e['department_name'] ?? '').toString().toLowerCase();
      return eDept == dept || eDept.contains(dept) || dept.contains(eDept);
    }).toList();

    if (filtered.isEmpty) {
      filtered = allEmps;
    }

    setState(() {
      _employees = filtered;
      _todayRecords = records;
      _loading = false;
    });
  }

  Map<String, dynamic>? _getRecordForEmp(Map<String, dynamic> emp) {
    final empId = emp['employee_id']?.toString() ?? emp['id']?.toString() ?? '';
    final empUid = emp['firebase_uid']?.toString() ?? emp['id']?.toString() ?? '';
    return _todayRecords.firstWhereOrNull((r) {
      final rId = r['employee_id']?.toString() ?? '';
      final rUid = r['employee_uid']?.toString() ?? '';
      return (empId.isNotEmpty && (rId == empId || rUid == empId)) ||
          (empUid.isNotEmpty && (rId == empUid || rUid == empUid));
    });
  }

  @override
  Widget build(BuildContext context) {
    final deptDisplayName = widget.departmentName.isNotEmpty
        ? widget.departmentName
        : 'Department'.tr;

    final recordsList = _employees.map((emp) {
      final rec = _getRecordForEmp(emp);
      final checkIn = rec?['check_in_time']?.toString();
      final checkOut = rec?['check_out_time']?.toString();
      final isAbsent = rec == null ||
          (checkIn == null && (rec['status'] == null || rec['status'] == 'absent'));
      return {
        'employee': emp,
        'record': rec,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'isAbsent': isAbsent,
      };
    }).toList();

    final displayedList = recordsList.where((item) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'A') return item['isAbsent'] == true;
      if (_selectedFilter == 'PRESENT') return item['isAbsent'] == false;
      return true;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2430),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deptDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${"Today's Attendance".tr} • ${DateText.ymd(DateText.nowCambodia())}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: '${"All".tr} (${recordsList.length})',
                    isSelected: _selectedFilter == 'ALL',
                    onTap: () => setState(() => _selectedFilter = 'ALL'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '${"Absent".tr} (${recordsList.where((i) => i['isAbsent'] == true).length})',
                    isSelected: _selectedFilter == 'A',
                    color: _absentColor,
                    onTap: () => setState(() => _selectedFilter = 'A'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '${"Checked In".tr} (${recordsList.where((i) => i['isAbsent'] == false).length})',
                    isSelected: _selectedFilter == 'PRESENT',
                    color: const Color(0xFF10B981),
                    onTap: () => setState(() => _selectedFilter = 'PRESENT'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : displayedList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline, size: 40, color: Colors.white38),
                                const SizedBox(height: 8),
                                Text(
                                  'No employees found'.tr,
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: displayedList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final item = displayedList[i];
                            final emp = item['employee'] as Map<String, dynamic>;
                            final checkIn = item['checkIn'] as String?;
                            final checkOut = item['checkOut'] as String?;
                            final isAbsent = item['isAbsent'] as bool;
                            final name = emp['fullname'] ?? emp['name'] ?? 'Staff ${emp['id']}';
                            final role = emp['role']?.toString().capitalizeFirst ?? 'Staff';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF28303F),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAbsent
                                      ? _absentColor.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isAbsent
                                        ? _absentColor.withValues(alpha: 0.2)
                                        : const Color(0xFF10B981).withValues(alpha: 0.2),
                                    child: Text(
                                      (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                                      style: TextStyle(
                                        color: isAbsent ? _absentColor : const Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          role,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (isAbsent)
                                          Text(
                                            'Not checked in'.tr,
                                            style: const TextStyle(
                                              color: _absentColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              Text(
                                                'In: ${checkIn ?? '—'}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Out: ${checkOut ?? '—'}',
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAbsent
                                          ? _absentColor.withValues(alpha: 0.15)
                                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAbsent ? 'ABSENT'.tr : 'PRESENT'.tr,
                                      style: TextStyle(
                                        color: isAbsent ? _absentColor : const Color(0xFF10B981),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF3AA6F0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

