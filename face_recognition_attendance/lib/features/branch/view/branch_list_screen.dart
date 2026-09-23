import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/widgets/permission_view.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/branch/model/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class BranchListScreen extends StatelessWidget {
  const BranchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<BranchController>()
        ? Get.find<BranchController>()
        : Get.put(BranchController());

    return RequestScaffold(
      title: 'Branch Management',
      showBackButton: true,
      body: Obx(() {
        if (controller.isLoading.value && controller.branches.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: RequestColors.primary));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchBranches,
          color: RequestColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Action: Create Branch (CEO only)
              PermissionView(
                targetPermission: AppPermission.createBranch,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Get.toNamed(AppRoutes.createBranch);
                      if (created == true) {
                        controller.fetchBranches();
                      }
                    },
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Add New Branch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RequestColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              if (controller.branches.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.location_off_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No branches found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a branch to configure geofence attendance.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...controller.branches.map((b) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: RequestColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.business_rounded, color: RequestColors.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: RequestColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Geofence Radius: ${b.radius.toInt()}m',
                                        style: const TextStyle(fontSize: 12, color: RequestColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    PermissionView(
                                      targetPermission: AppPermission.editBranch,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: RequestColors.primary),
                                        onPressed: () => _showEditBranchBottomSheet(context, b, controller),
                                      ),
                                    ),
                                    PermissionView(
                                      targetPermission: AppPermission.deleteBranch,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                        onPressed: () {
                                          Get.defaultDialog(
                                            title: 'Delete Branch',
                                            middleText: 'Are you sure you want to delete "${b.name}"?',
                                            textConfirm: 'Delete',
                                            textCancel: 'Cancel',
                                            confirmTextColor: Colors.white,
                                            buttonColor: Colors.redAccent,
                                            onConfirm: () {
                                              Get.back();
                                              controller.deleteBranch(b.id);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GPS: ${b.latitude.toStringAsFixed(4)}, ${b.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline_rounded, size: 14, color: RequestColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${b.employeeCount} Staff',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
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

  void _showEditBranchBottomSheet(BuildContext context, BranchModel branch, BranchController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: branch.name);
    final latController = TextEditingController(text: branch.latitude.toStringAsFixed(6));
    final lngController = TextEditingController(text: branch.longitude.toStringAsFixed(6));
    final radiusController = TextEditingController(text: branch.radius.toInt().toString());
    final isLocating = false.obs;
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
                      'Edit Branch',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Branch Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: RequestColors.softSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter branch name' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GPS Coordinates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                    Obx(() => TextButton.icon(
                          onPressed: isLocating.value
                              ? null
                              : () async {
                                  isLocating.value = true;
                                  try {
                                    final pos = await Geolocator.getCurrentPosition(
                                      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                                    );
                                    latController.text = pos.latitude.toStringAsFixed(6);
                                    lngController.text = pos.longitude.toStringAsFixed(6);
                                  } catch (e) {
                                    Get.snackbar('GPS Error', e.toString(), snackPosition: SnackPosition.TOP);
                                  } finally {
                                    isLocating.value = false;
                                  }
                                },
                          icon: isLocating.value
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location_rounded, size: 16),
                          label: Text(isLocating.value ? 'Locating...' : 'Get GPS'),
                          style: TextButton.styleFrom(foregroundColor: RequestColors.primary),
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          filled: true,
                          fillColor: RequestColors.softSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lat' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: lngController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          filled: true,
                          fillColor: RequestColors.softSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lng' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Allowed Geofence Radius (meters)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RequestColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: radiusController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixText: 'meters',
                    filled: true,
                    fillColor: RequestColors.softSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) {
                    final r = double.tryParse(v ?? '');
                    if (r == null || r <= 0) return 'Invalid radius';
                    return null;
                  },
                ),
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
                              isSubmitting.value = true;
                              try {
                                final name = nameController.text.trim();
                                final lat = double.parse(latController.text.trim());
                                final lng = double.parse(lngController.text.trim());
                                final radius = double.parse(radiusController.text.trim());
                                final success = await controller.updateBranch(
                                  id: branch.id,
                                  name: name,
                                  latitude: lat,
                                  longitude: lng,
                                  radius: radius,
                                );
                                if (success) {
                                  Get.back();
                                  Get.snackbar(
                                    'Success',
                                    'Branch "$name" updated successfully.',
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
