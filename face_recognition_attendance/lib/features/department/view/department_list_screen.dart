import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/widgets/permission_view.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/department/controller/department_controller.dart';
import 'package:face_recognition_attendance/features/department/model/department_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DepartmentListScreen extends StatelessWidget {
  const DepartmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DepartmentController>()
        ? Get.find<DepartmentController>()
        : Get.put(DepartmentController());

    return RequestScaffold(
      title: 'Department Management',
      showBackButton: true,
      body: Obx(() {
        if (controller.isLoading.value && controller.departments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: RequestColors.primary));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchDepartments,
          color: RequestColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Action: Add Department (CEO or Manager)
              PermissionView(
                targetPermission: AppPermission.createDepartment,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Get.toNamed(AppRoutes.createDepartment);
                      if (created == true) {
                        controller.fetchDepartments();
                      }
                    },
                    icon: const Icon(Icons.add_business_rounded),
                    label: Text('Add New Department'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RequestColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              if (controller.departments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.domain_disabled_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No departments found'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add departments to organize teams within branches.'.tr,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...controller.departments.map((d) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.apartment_rounded, color: Colors.blue.shade700, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: RequestColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: RequestColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        d.branchName.isNotEmpty ? d.branchName : 'Branch #${d.branchId}',
                                        style: const TextStyle(fontSize: 12, color: RequestColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                             Row(
                              children: [
                                Text(
                                  '${d.employeeCount} Staff',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
                                ),
                                PermissionView(
                                  targetPermission: AppPermission.editDepartment,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: RequestColors.primary, size: 20),
                                    onPressed: () => _showEditDepartmentBottomSheet(context, d, controller),
                                  ),
                                ),
                                PermissionView(
                                  targetPermission: AppPermission.deleteDepartment,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      Get.defaultDialog(
                                        title: 'Delete Department',
                                        middleText: 'Are you sure you want to delete "${d.name}"?',
                                        textConfirm: 'Delete',
                                        textCancel: 'Cancel',
                                        confirmTextColor: Colors.white,
                                        buttonColor: Colors.redAccent,
                                        onConfirm: () {
                                          Get.back();
                                          controller.deleteDepartment(d.id);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        );
      }),
    );
  }

  void _showEditDepartmentBottomSheet(BuildContext context, DepartmentModel department, DepartmentController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: department.name);
    final branchController = Get.isRegistered<BranchController>()
        ? Get.find<BranchController>()
        : Get.put(BranchController());
    int? selectedBranchId = department.branchId;
    final isSubmitting = false.obs;

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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Department',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Department Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: RequestColors.softSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter department name' : null,
                ),
                const SizedBox(height: 14),
                const Text('Assigned Branch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                const SizedBox(height: 6),
                Obx(() {
                  final branches = branchController.branches;
                  return RequestDropdownField<int>(
                    value: selectedBranchId,
                    fillColor: RequestColors.softSurface,
                    icon: Icons.keyboard_arrow_down_rounded,
                    items: branches
                        .map((b) => DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(b.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (id) => selectedBranchId = id,
                  );
                }),
                const SizedBox(height: 24),
                Obx(() {
                  final isBusy = isSubmitting.value || controller.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : () async {
                              if (isSubmitting.value || controller.isLoading.value) return;
                              if (!formKey.currentState!.validate()) return;
                              if (selectedBranchId == null) {
                                Get.snackbar('Branch Required', 'Please select a branch.', snackPosition: SnackPosition.TOP);
                                return;
                              }
                              isSubmitting.value = true;
                              try {
                                final name = nameController.text.trim();
                                final success = await controller.updateDepartment(
                                  id: department.id,
                                  name: name,
                                  branchId: selectedBranchId!,
                                );
                                if (success) {
                                  Get.back();
                                  Get.snackbar(
                                    'Success',
                                    'Department "$name" updated successfully.',
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
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
