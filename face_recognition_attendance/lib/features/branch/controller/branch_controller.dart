import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/features/branch/model/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BranchController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<BranchModel> branches = <BranchModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final data = await _apiService.get('/branches/');
      if (data is List) {
        branches.assignAll(data.map((item) => BranchModel.fromJson(item)).toList());
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createBranch({
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    // Early guard to prevent duplicate calls / spam clicking
    if (isLoading.value) return false;

    try {
      isLoading.value = true;
      final response = await _apiService.post('/branches/', body: {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });

      if (response is Map) {
        final newBranch = BranchModel.fromJson(Map<String, dynamic>.from(response));
        branches.insert(0, newBranch);
        return true;
      }
      return false;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not create branch: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBranch({
    required int id,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    if (isLoading.value) return false;

    try {
      isLoading.value = true;
      final response = await _apiService.patch('/branches/$id/', body: {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });

      if (response is Map) {
        final updatedBranch = BranchModel.fromJson(Map<String, dynamic>.from(response));
        final index = branches.indexWhere((b) => b.id == id);
        if (index != -1) {
          branches[index] = updatedBranch;
        }
        return true;
      }
      return false;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update branch: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteBranch(int branchId) async {
    try {
      isLoading.value = true;
      await _apiService.delete('/branches/$branchId/');
      branches.removeWhere((b) => b.id == branchId);
      Get.snackbar(
        'Success',
        'Branch deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      return true;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
