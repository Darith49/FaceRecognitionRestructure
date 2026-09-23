import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/features/department/model/department_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DepartmentController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<DepartmentModel> departments = <DepartmentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDepartments();
  }

  Future<void> fetchDepartments({int? branchId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final queryParams = branchId != null ? {'branch': branchId} : null;
      final data = await _apiService.get('/departments/', queryParams: queryParams);
      if (data is List) {
        departments.assignAll(data.map((item) => DepartmentModel.fromJson(item)).toList());
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createDepartment({
    required String name,
    required int branchId,
  }) async {
    // Early guard to prevent duplicate calls / spam clicking
    if (isLoading.value) return false;

    try {
      isLoading.value = true;
      final response = await _apiService.post('/departments/', body: {
        'name': name,
        'branch': branchId,
      });

      if (response is Map) {
        final newDept = DepartmentModel.fromJson(Map<String, dynamic>.from(response));
        departments.insert(0, newDept);
        return true;
      }
      return false;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not create department: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDepartment({
    required int id,
    required String name,
    required int branchId,
  }) async {
    if (isLoading.value) return false;

    try {
      isLoading.value = true;
      final response = await _apiService.patch('/departments/$id/', body: {
        'name': name,
        'branch': branchId,
      });

      if (response is Map) {
        final updatedDept = DepartmentModel.fromJson(Map<String, dynamic>.from(response));
        final index = departments.indexWhere((d) => d.id == id);
        if (index != -1) {
          departments[index] = updatedDept;
        }
        return true;
      }
      return false;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update department: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteDepartment(int departmentId) async {
    try {
      isLoading.value = true;
      await _apiService.delete('/departments/$departmentId/');
      departments.removeWhere((d) => d.id == departmentId);
      Get.snackbar(
        'Success',
        'Department deleted successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      return true;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
