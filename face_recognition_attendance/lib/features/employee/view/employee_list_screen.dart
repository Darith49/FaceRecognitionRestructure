import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/permission_service.dart';
import 'package:face_recognition_attendance/core/permissions/widgets/permission_view.dart';
import 'package:face_recognition_attendance/core/widgets/app_avatar.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/department/controller/department_controller.dart';
import 'package:face_recognition_attendance/features/employee/controller/employee_controller.dart';
import 'package:face_recognition_attendance/features/employee/model/employee_model.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/widgets/change_session_time_dialog.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  int? _selectedBranchFilter;

  final EmployeeController _controller = Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());

  final BranchController _branchController = Get.isRegistered<BranchController>()
      ? Get.find<BranchController>()
      : Get.put(BranchController());

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Employee Directory',
      showBackButton: true,
      body: Obx(() {
        if (_controller.isLoading.value && _controller.employees.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: RequestColors.primary));
        }

        final branches = _branchController.branches;
        final allEmployees = _controller.employees;

        final filteredEmployees = _selectedBranchFilter == null
            ? allEmployees
            : allEmployees.where((e) => e.branchId == _selectedBranchFilter).toList();

        final Map<String, List<EmployeeModel>> groupedEmployees = {};
        for (final emp in filteredEmployees) {
          final branchName = emp.branchName.isNotEmpty ? emp.branchName : 'Unassigned Branch';
          groupedEmployees.putIfAbsent(branchName, () => []).add(emp);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _controller.fetchEmployees(),
              _branchController.fetchBranches(),
            ]);
          },
          color: RequestColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Action: Invite Employee
              PermissionView(
                targetPermission: AppPermission.createEmployee,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Get.toNamed(AppRoutes.createEmployee);
                      if (created == true) {
                        _controller.fetchEmployees();
                      }
                    },
                    icon: const Icon(FluentIcons.person_add_24_regular),
                    label: Text('Invite New Employee'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RequestColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              // ─── Branch Filter Chips ───
              if (branches.isNotEmpty) ...[
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${'All'.tr} (${allEmployees.length})'),
                          selected: _selectedBranchFilter == null,
                          onSelected: (_) => setState(() => _selectedBranchFilter = null),
                          selectedColor: RequestColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedBranchFilter == null ? RequestColors.primary : RequestColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _selectedBranchFilter == null ? RequestColors.primary : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      ...branches.map((b) {
                        final count = allEmployees.where((e) => e.branchId == b.id).length;
                        final isSelected = _selectedBranchFilter == b.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${b.name} ($count)'),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedBranchFilter = isSelected ? null : b.id),
                            selectedColor: RequestColors.primary.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? RequestColors.primary : RequestColors.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? RequestColors.primary : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (filteredEmployees.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(FluentIcons.people_24_regular, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No employees found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedBranchFilter != null
                              ? 'No staff assigned to this branch yet.'
                              : 'Invite employees to get started with attendance tracking.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...groupedEmployees.entries.map((entry) {
                  final branchName = entry.key;
                  final employeesInBranch = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Branch Section Header ───
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(FluentIcons.building_24_regular, size: 16, color: Color(0xFF0F766E)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                branchName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${employeesInBranch.length} Staff',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ─── Employee Cards in this Branch ───
                      ...employeesInBranch.map((e) => _buildEmployeeCard(context, e)),
                    ],
                  );
                }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, EmployeeModel e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              profileUrl: e.profileUrl,
              name: e.fullname,
              size: 44,
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
                          e.fullname,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: RequestColors.textPrimary,
                          ),
                        ),
                      ),
                      _buildRoleBadge(e.role.name),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    e.email,
                    style: const TextStyle(fontSize: 13, color: RequestColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (e.departmentName.isNotEmpty) ...[
                        Icon(FluentIcons.building_24_regular, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          e.departmentName,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (e.employeeId.isNotEmpty) ...[
                        Icon(FluentIcons.badge_24_regular, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          e.employeeId,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: RequestColors.softSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.clock_24_regular, size: 12, color: RequestColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatTime(e.section1Start)} - ${_formatTime(e.section1End)} • ${_formatTime(e.section2Start)} - ${_formatTime(e.section2End)} (${e.workDays.toUpperCase()})',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RequestColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(FluentIcons.clock_24_regular, size: 20, color: Color(0xFFD97706)),
                  tooltip: 'Change Session Time',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _openChangeSessionTimeDialog(context, e),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.mail_checkmark_24_regular, size: 20, color: Colors.indigo),
                  tooltip: 'Resend Invitation',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _controller.resendInvitation(e),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.edit_24_regular, size: 20, color: RequestColors.primary),
                  tooltip: 'Edit User',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showEditEmployeeBottomSheet(context, e),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '--:--';
    final parts = timeStr.trim().split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return timeStr;
  }

  void _openChangeSessionTimeDialog(BuildContext context, EmployeeModel employee) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeSessionTimeDialog(
        memberId: employee.id,
        memberName: employee.fullname,
        memberRole: employee.role.name.toUpperCase(),
        memberSubtitle: employee.departmentName.isNotEmpty ? employee.departmentName : employee.branchName,
        initialSection1Start: employee.section1Start,
        initialSection1End: employee.section1End,
        initialSection2Start: employee.section2Start,
        initialSection2End: employee.section2End,
        initialWorkDays: employee.workDays,
        onSave: ({
          required int memberId,
          required String section1Start,
          required String section1End,
          required String section2Start,
          required String section2End,
          required String workDays,
        }) async {
          return await _controller.updateEmployee(
            id: memberId,
            fullname: employee.fullname,
            email: employee.email,
            role: employee.role,
            branchId: employee.branchId,
            departmentId: employee.departmentId,
            employeeId: employee.employeeId,
            section1Start: section1Start,
            section1End: section1End,
            section2Start: section2Start,
            section2End: section2End,
            workDays: workDays,
          );
        },
      ),
    );
  }

  void _showEditEmployeeBottomSheet(BuildContext context, EmployeeModel employee) {
    final formKey = GlobalKey<FormState>();
    final fullnameController = TextEditingController(text: employee.fullname);
    final emailController = TextEditingController(text: employee.email);
    final empIdController = TextEditingController(text: employee.employeeId);

    UserRole selectedRole = employee.role;
    int? selectedBranchId = employee.branchId;
    int? selectedDeptId = employee.departmentId;

    TimeOfDay parseTime(String? timeStr, TimeOfDay fallback) {
      if (timeStr == null || timeStr.trim().isEmpty) return fallback;
      try {
        final parts = timeStr.trim().split(':');
        if (parts.length >= 2) {
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (_) {}
      return fallback;
    }

    String formatTimeOfDay(TimeOfDay tod) {
      return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}:00';
    }

    String formatDisplay(TimeOfDay tod) {
      return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
    }

    TimeOfDay s1Start = parseTime(employee.section1Start, const TimeOfDay(hour: 7, minute: 0));
    TimeOfDay s1End = parseTime(employee.section1End, const TimeOfDay(hour: 11, minute: 0));
    TimeOfDay s2Start = parseTime(employee.section2Start, const TimeOfDay(hour: 13, minute: 0));
    TimeOfDay s2End = parseTime(employee.section2End, const TimeOfDay(hour: 17, minute: 0));

    Set<String> selectedWorkDays = (employee.workDays.isNotEmpty ? employee.workDays : 'mon,tue,wed,thu,fri')
        .toLowerCase()
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toSet();
    if (selectedWorkDays.isEmpty) {
      selectedWorkDays = {'mon', 'tue', 'wed', 'thu', 'fri'};
    }

    final departmentController = Get.isRegistered<DepartmentController>()
        ? Get.find<DepartmentController>()
        : Get.put(DepartmentController());

    final isSubmitting = false.obs;
    final isResending = false.obs;

    final allowedRoles = PermissionService.to.getCreateableRoles();
    final roleChoices = allowedRoles.contains(employee.role)
        ? allowedRoles
        : [employee.role, ...allowedRoles];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit User',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.dismiss_24_regular),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: fullnameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: RequestColors.softSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(FluentIcons.person_24_regular, color: RequestColors.primary),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Email Address (Gmail)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: RequestColors.softSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(FluentIcons.mail_24_regular, color: RequestColors.primary),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter email';
                        if (!GetUtils.isEmail(v.trim())) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Company Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                    const SizedBox(height: 6),
                    RequestDropdownField<UserRole>(
                      value: selectedRole,
                      fillColor: RequestColors.softSurface,
                      icon: FluentIcons.chevron_down_24_regular,
                      items: roleChoices
                          .map((r) => DropdownMenuItem<UserRole>(
                                value: r,
                                child: Text(r.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (role) {
                        setSheetState(() => selectedRole = role);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Assigned Branch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                    const SizedBox(height: 6),
                    Obx(() {
                      final branches = _branchController.branches;
                      return RequestDropdownField<int>(
                        value: selectedBranchId,
                        hint: 'Select Branch',
                        fillColor: RequestColors.softSurface,
                        icon: FluentIcons.chevron_down_24_regular,
                        items: branches
                            .map((b) => DropdownMenuItem<int>(
                                  value: b.id,
                                  child: Text(b.name),
                                ))
                            .toList(),
                        onChanged: (id) {
                          setSheetState(() {
                            selectedBranchId = id;
                            selectedDeptId = null;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 14),
                    const Text('Assigned Department (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                    const SizedBox(height: 6),
                    Obx(() {
                      final depts = selectedBranchId != null
                          ? departmentController.departments.where((d) => d.branchId == selectedBranchId).toList()
                          : departmentController.departments;

                      return RequestDropdownField<int>(
                        value: selectedDeptId,
                        hint: 'Select Department',
                        fillColor: RequestColors.softSurface,
                        icon: FluentIcons.chevron_down_24_regular,
                        items: depts
                            .map((d) => DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(d.name),
                                ))
                            .toList(),
                        onChanged: (id) => setSheetState(() => selectedDeptId = id),
                      );
                    }),
                    const SizedBox(height: 14),
                    const Text('Employee ID (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: empIdController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: RequestColors.softSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(FluentIcons.badge_24_regular, color: RequestColors.primary),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // ─── Work Shift & Session Times Section ───
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: RequestColors.softSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(FluentIcons.clock_24_regular, size: 16, color: RequestColors.primary),
                              SizedBox(width: 6),
                              Text('Work Shift Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: RequestColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Session 1 (Morning):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: RequestColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: s1Start);
                                    if (t != null) setSheetState(() => s1Start = t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                    child: Row(
                                      children: [
                                        const Icon(FluentIcons.clock_24_regular, size: 14, color: RequestColors.primary),
                                        const SizedBox(width: 4),
                                        Text('In: ${formatDisplay(s1Start)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: s1End);
                                    if (t != null) setSheetState(() => s1End = t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                    child: Row(
                                      children: [
                                        const Icon(FluentIcons.clock_24_regular, size: 14, color: RequestColors.primary),
                                        const SizedBox(width: 4),
                                        Text('Out: ${formatDisplay(s1End)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Session 2 (Afternoon):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: RequestColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: s2Start);
                                    if (t != null) setSheetState(() => s2Start = t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                    child: Row(
                                      children: [
                                        const Icon(FluentIcons.clock_24_regular, size: 14, color: RequestColors.primary),
                                        const SizedBox(width: 4),
                                        Text('In: ${formatDisplay(s2Start)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: s2End);
                                    if (t != null) setSheetState(() => s2End = t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                    child: Row(
                                      children: [
                                        const Icon(FluentIcons.clock_24_regular, size: 14, color: RequestColors.primary),
                                        const SizedBox(width: 4),
                                        Text('Out: ${formatDisplay(s2End)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Active Days:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: RequestColors.textSecondary)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].map((d) {
                              final sel = selectedWorkDays.contains(d);
                              return ChoiceChip(
                                label: Text(d.toUpperCase()),
                                selected: sel,
                                onSelected: (b) {
                                  setSheetState(() {
                                    if (b) {
                                      selectedWorkDays.add(d);
                                    } else if (selectedWorkDays.length > 1) {
                                      selectedWorkDays.remove(d);
                                    }
                                  });
                                },
                                selectedColor: RequestColors.primary,
                                labelStyle: TextStyle(
                                  color: sel ? Colors.white : RequestColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() => OutlinedButton.icon(
                          onPressed: isResending.value
                              ? null
                              : () async {
                                  isResending.value = true;
                                  try {
                                    await _controller.resendInvitation(employee);
                                  } finally {
                                    isResending.value = false;
                                  }
                                },
                          icon: isResending.value
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(FluentIcons.mail_checkmark_24_regular, size: 18),
                          label: Text(isResending.value ? 'Resending...' : 'Resend Invitation Email'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )),
                    const SizedBox(height: 12),
                    Obx(() {
                      final isBusy = isSubmitting.value || _controller.isLoading.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isBusy
                              ? null
                              : () async {
                                  if (isSubmitting.value || _controller.isLoading.value) return;
                                  if (!formKey.currentState!.validate()) return;
                                  isSubmitting.value = true;
                                  try {
                                    final fullname = fullnameController.text.trim();
                                    final email = emailController.text.trim();
                                    final empId = empIdController.text.trim();

                                    final success = await _controller.updateEmployee(
                                      id: employee.id,
                                      fullname: fullname,
                                      email: email,
                                      role: selectedRole,
                                      branchId: selectedBranchId,
                                      departmentId: selectedDeptId,
                                      employeeId: empId,
                                      section1Start: formatTimeOfDay(s1Start),
                                      section1End: formatTimeOfDay(s1End),
                                      section2Start: formatTimeOfDay(s2Start),
                                      section2End: formatTimeOfDay(s2End),
                                      workDays: selectedWorkDays.join(','),
                                    );

                                    if (success) {
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        'User "$fullname" updated successfully.',
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.green.shade600,
                                        colorText: Colors.white,
                                        icon: const Icon(FluentIcons.checkmark_circle_24_regular, color: Colors.white),
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 12,
                                        duration: const Duration(seconds: 3),
                                      );
                                    }
                                  } finally {
                                    isSubmitting.value = false;
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RequestColors.primary,
                            disabledBackgroundColor: RequestColors.primary.withValues(alpha: 0.65),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildRoleBadge(String roleName) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    switch (roleName.toLowerCase()) {
      case 'ceo':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        break;
      case 'admin':
        bg = Colors.indigo.shade50;
        fg = Colors.indigo.shade700;
        break;
      case 'manager':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case 'leader':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade700;
        break;
      case 'employee':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        roleName.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
