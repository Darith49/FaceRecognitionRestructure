import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/department/controller/department_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateDepartmentScreen extends StatefulWidget {
  const CreateDepartmentScreen({super.key});

  @override
  State<CreateDepartmentScreen> createState() => _CreateDepartmentScreenState();
}

class _CreateDepartmentScreenState extends State<CreateDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _selectedBranchId;
  final RxBool _isSubmitting = false.obs;

  final DepartmentController _departmentController = Get.isRegistered<DepartmentController>()
      ? Get.find<DepartmentController>()
      : Get.put(DepartmentController());

  final BranchController _branchController = Get.isRegistered<BranchController>()
      ? Get.find<BranchController>()
      : Get.put(BranchController());

  @override
  void initState() {
    super.initState();
    if (_branchController.branches.isNotEmpty) {
      _selectedBranchId = _branchController.branches.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting.value || _departmentController.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBranchId == null) {
      Get.snackbar(
        'Branch Required',
        'Please select a branch for this department.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final deptName = _nameController.text.trim();
    _isSubmitting.value = true;
    try {
      final success = await _departmentController.createDepartment(
        name: deptName,
        branchId: _selectedBranchId!,
      );

      if (success) {
        Get.back(result: true);
        Get.snackbar(
          'Success',
          'Department "$deptName" created successfully.',
          snackPosition: SnackPosition.TOP,
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
    return RequestScaffold(
      title: 'Create Department',
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Department Name
            const Text(
              'Department Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. IT & Software Development',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.corporate_fare_rounded, color: RequestColors.primary),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter department name' : null,
            ),
            const SizedBox(height: 20),

            // Branch Dropdown
            const Text(
              'Assigned Branch',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final branches = _branchController.branches;
              if (branches.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'No branches found. Please create a branch first before adding departments.',
                    style: TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                );
              }

              if (_selectedBranchId == null && branches.isNotEmpty) {
                _selectedBranchId = branches.first.id;
              }

              return RequestDropdownField<int>(
                value: _selectedBranchId,
                fillColor: RequestColors.softSurface,
                icon: Icons.keyboard_arrow_down_rounded,
                items: branches
                    .map((b) => DropdownMenuItem<int>(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (id) => setState(() => _selectedBranchId = id),
              );
            }),
            const SizedBox(height: 32),

            // Submit Button with double-tap & loading protection
            Obx(() {
              final isBusy = _isSubmitting.value || _departmentController.isLoading.value;
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
                          'Creating Department...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ] else ...[
                        const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Department',
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
