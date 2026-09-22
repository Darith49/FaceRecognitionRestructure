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

  // WorkTime sections (defaults: 07:00 AM - 11:00 AM, 01:00 PM - 05:00 PM)
  TimeOfDay _section1Start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _section1End = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _section2Start = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _section2End = const TimeOfDay(hour: 17, minute: 0);

  // WorkDay selector (default: Monday - Friday)
  final List<String> _daysOfWeek = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};

  final EmployeeController _employeeController =
      Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());

  final BranchController _branchController =
      Get.isRegistered<BranchController>()
      ? Get.find<BranchController>()
      : Get.put(BranchController());

  final DepartmentController _departmentController =
      Get.isRegistered<DepartmentController>()
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _toTimeString(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  double _timeOfDayToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  Future<void> _submit() async {
    if (_isSubmitting.value || _employeeController.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;

    if (_timeOfDayToDouble(_section1Start) >=
        _timeOfDayToDouble(_section1End)) {
      Get.snackbar(
        'Invalid Section 1 Time',
        'Section 1 End time must be after Start time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (_timeOfDayToDouble(_section2Start) >=
        _timeOfDayToDouble(_section2End)) {
      Get.snackbar(
        'Invalid Section 2 Time',
        'Section 2 End time must be after Start time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (_timeOfDayToDouble(_section1End) > _timeOfDayToDouble(_section2Start)) {
      Get.snackbar(
        'Invalid Shift Order',
        'Section 2 cannot start before Section 1 ends.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      Get.snackbar(
        'Select Work Days',
        'Please select at least one active work day.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();
    final workDaysStr = _daysOfWeek
        .where((d) => _selectedDays.contains(d))
        .map((d) => d.toLowerCase())
        .join(',');

    _isSubmitting.value = true;
    try {
      final success = await _employeeController.createEmployee(
        fullname: fullname,
        email: email,
        role: _selectedRole,
        branchId: _selectedBranchId,
        departmentId: _selectedDeptId,
        employeeId: _empIdController.text.trim(),
        section1Start: _toTimeString(_section1Start),
        section1End: _toTimeString(_section1End),
        section2Start: _toTimeString(_section2Start),
        section2End: _toTimeString(_section2End),
        workDays: workDaysStr,
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
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.indigo.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The employee will receive an invitation email and link to set their own password upon first login.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Full Name
            const Text(
              'Full Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullnameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. Sokha Chan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: RequestColors.primary,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter full name'
                  : null,
            ),
            const SizedBox(height: 16),

            // Email Address
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. sokha@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.mail_outline_rounded,
                  color: RequestColors.primary,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter email';
                }
                if (!GetUtils.isEmail(v.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Employee ID (Optional)
            const Text(
              'Employee ID (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _empIdController,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. EMP-0012',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: RequestColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Role Dropdown
            const Text(
              'Company Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            isSingleRole
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                        .map(
                          (r) => DropdownMenuItem<UserRole>(
                            value: r,
                            child: Text(r.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (role) {
                      setState(() => _selectedRole = role);
                    },
                  ),
            const SizedBox(height: 16),

            // Branch Dropdown
            const Text(
              'Branch Assignment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
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
                    .map(
                      (b) => DropdownMenuItem<int>(
                        value: b.id,
                        child: Text(b.name),
                      ),
                    )
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final depts = _selectedBranchId != null
                  ? _departmentController.departments
                        .where((d) => d.branchId == _selectedBranchId)
                        .toList()
                  : _departmentController.departments;

              return RequestDropdownField<int>(
                value: _selectedDeptId,
                hint: 'Select Department',
                fillColor: RequestColors.softSurface,
                icon: Icons.keyboard_arrow_down_rounded,
                items: [
                  ...depts.map(
                    (d) =>
                        DropdownMenuItem<int>(value: d.id, child: Text(d.name)),
                  ),
                ],
                onChanged: (id) => setState(() => _selectedDeptId = id),
              );
            }),
            const SizedBox(height: 20),

            // WorkTime Section Header
            const Text(
              'WorkTime',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Section 1 Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Section 1',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Morning Shift',
                        style: TextStyle(
                          fontSize: 12,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTimeCard(
                        label: 'Start',
                        time: _section1Start,
                        onSelected: (t) => setState(() => _section1Start = t),
                      ),
                      const SizedBox(width: 12),
                      _buildTimeCard(
                        label: 'End',
                        time: _section1End,
                        onSelected: (t) => setState(() => _section1End = t),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Section 2 Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Section 2',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Afternoon Shift',
                        style: TextStyle(
                          fontSize: 12,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTimeCard(
                        label: 'Start',
                        time: _section2Start,
                        onSelected: (t) => setState(() => _section2Start = t),
                      ),
                      const SizedBox(width: 12),
                      _buildTimeCard(
                        label: 'End',
                        time: _section2End,
                        onSelected: (t) => setState(() => _section2End = t),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // WorkDay Section Header
            const Text(
              'WorkDay',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _daysOfWeek.map((day) => _buildDayChip(day)).toList(),
            ),
            const SizedBox(height: 32),

            // Submit Button with double-tap & loading protection
            Obx(() {
              final isBusy =
                  _isSubmitting.value || _employeeController.isLoading.value;
              return SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequestColors.primary,
                    disabledBackgroundColor: RequestColors.primary.withValues(
                      alpha: 0.65,
                    ),
                    disabledForegroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Creating User...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

  Widget _buildTimeCard({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onSelected,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: RequestColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) {
                onSelected(picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: RequestColors.softSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTimeOfDay(time),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: RequestColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(String day) {
    final isSelected = _selectedDays.contains(day);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              if (_selectedDays.length > 1) {
                _selectedDays.remove(day);
              }
            } else {
              _selectedDays.add(day);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? RequestColors.primary
                : RequestColors.softSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? RequestColors.primary : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : RequestColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
