import 'package:face_recognition_attendance/core/permissions/permission_service.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/department/controller/department_controller.dart';
import 'package:face_recognition_attendance/features/employee/controller/employee_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _empIdController = TextEditingController();

  UserRole _selectedRole = UserRole.employee;
  int? _selectedBranchId;
  int? _selectedDeptId;
  final RxBool _isSubmitting = false.obs;

  final EmployeeController _employeeController = Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());

  final BranchController _branchController = Get.isRegistered<BranchController>()
      ? Get.find<BranchController>()
      : Get.put(BranchController());

  final DepartmentController _departmentController = Get.isRegistered<DepartmentController>()
      ? Get.find<DepartmentController>()
      : Get.put(DepartmentController());

  @override
  void initState() {
    super.initState();
    final allowedRoles = PermissionService.to.getCreateableRoles();
    if (allowedRoles.isNotEmpty) {
      _selectedRole = allowedRoles.first;
    }

    if (_branchController.branches.isNotEmpty) {
      _selectedBranchId = _branchController.branches.first.id;
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _empIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting.value || _employeeController.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;

    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();

    _isSubmitting.value = true;
    try {
      final success = await _employeeController.createEmployee(
        fullname: fullname,
        email: email,
        role: _selectedRole,
        branchId: _selectedBranchId,
        departmentId: _selectedDeptId,
        employeeId: _empIdController.text.trim(),
      );

      if (success) {
        Get.back(result: true);
        Get.snackbar(
          'Success',
          'User "$fullname" created successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedRoles = PermissionService.to.getCreateableRoles();
    if (allowedRoles.isNotEmpty && !allowedRoles.contains(_selectedRole)) {
      _selectedRole = allowedRoles.first;
    }
    final isSingleRole = allowedRoles.length == 1;

    return RequestScaffold(
      title: isSingleRole ? 'Invite Employee' : 'Create User',
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Information Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.mark_email_read_outlined, color: Colors.indigo.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The employee will receive an invitation email and link to set their own password upon first login.',
                      style: TextStyle(fontSize: 12, color: Colors.indigo.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Full Name
            const Text(
              'Full Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullnameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. Sokha Chan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: RequestColors.primary),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
            ),
            const SizedBox(height: 16),

            // Email Address
            const Text(
              'Email Address',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. sokha@example.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: RequestColors.primary),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter email';
                if (!GetUtils.isEmail(v.trim())) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Employee ID (Optional)
            const Text(
              'Employee ID (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _empIdController,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. EMP-0012',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.badge_outlined, color: RequestColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Role Dropdown
            const Text(
              'Company Role',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            isSingleRole
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: RequestColors.softSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedRole.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: RequestColors.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: RequestColors.textSecondary,
                        ),
                      ],
                    ),
                  )
                : RequestDropdownField<UserRole>(
                    value: _selectedRole,
                    fillColor: RequestColors.softSurface,
                    icon: Icons.keyboard_arrow_down_rounded,
                    items: allowedRoles
                        .map((r) => DropdownMenuItem<UserRole>(
                              value: r,
                              child: Text(r.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (role) {
                      setState(() => _selectedRole = role);
                    },
                  ),
            const SizedBox(height: 16),

            // Branch Dropdown
            const Text(
              'Branch Assignment',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final branches = _branchController.branches;
              return RequestDropdownField<int>(
                value: _selectedBranchId,
                hint: 'Select Branch',
                fillColor: RequestColors.softSurface,
                icon: Icons.keyboard_arrow_down_rounded,
                items: branches
                    .map((b) => DropdownMenuItem<int>(
                          value: b.id,
                          child: Text(b.name),
                        ))
                    .toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedBranchId = id;
                    _selectedDeptId = null;
                  });
                },
              );
            }),
            const SizedBox(height: 16),

            // Department Dropdown
            const Text(
              'Department Assignment (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final depts = _selectedBranchId != null
                  ? _departmentController.departments.where((d) => d.branchId == _selectedBranchId).toList()
                  : _departmentController.departments;

              return RequestDropdownField<int>(
                value: _selectedDeptId,
                hint: 'Select Department',
                fillColor: RequestColors.softSurface,
                icon: Icons.keyboard_arrow_down_rounded,
                items: [
                  ...depts.map((d) => DropdownMenuItem<int>(
                        value: d.id,
                        child: Text(d.name),
                      )),
                ],
                onChanged: (id) => setState(() => _selectedDeptId = id),
              );
            }),
            const SizedBox(height: 32),

            // Submit Button with double-tap & loading protection
            Obx(() {
              final isBusy = _isSubmitting.value || _employeeController.isLoading.value;
              return SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequestColors.primary,
                    disabledBackgroundColor: RequestColors.primary.withValues(alpha: 0.65),
                    disabledForegroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: isBusy ? 0 : 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isBusy) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Creating User...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ] else ...[
                        const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Create User',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
