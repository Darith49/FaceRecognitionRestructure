import 'package:face_recognition_attendance/core/service/firebase_service.dart';
import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/employee/model/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeController extends GetxController {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();

  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }

  Future<void> fetchEmployees({int? branchId, int? departmentId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final queryParams = <String, dynamic>{};
      if (branchId != null) queryParams['branch'] = branchId;
      if (departmentId != null) queryParams['department'] = departmentId;

      final data = await _apiService.get(
        '/employees/',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      if (data is List) {
        employees.assignAll(
          data.map((item) => EmployeeModel.fromJson(item)).toList(),
        );
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createEmployee({
    required String fullname,
    required String email,
    required UserRole role,
    int? branchId,
    int? departmentId,
    String? employeeId,
    String? section1Start,
    String? section1End,
    String? section2Start,
    String? section2End,
    String? workDays,
  }) async {
    // Early guard to prevent duplicate calls / spam clicking
    if (isLoading.value) return false;

    try {
      isLoading.value = true;
      final payload = <String, dynamic>{
        'fullname': fullname,
        'email': email,
        'role': userRoleToString(role),
      };

      if (branchId != null) {
        payload['branch_id'] = branchId;
      }
      if (departmentId != null) {
        payload['department_id'] = departmentId;
      }
      if (employeeId != null && employeeId.isNotEmpty) {
        payload['employee_id'] = employeeId;
      }
      if (section1Start != null && section1Start.isNotEmpty) {
        payload['section1_start'] = section1Start;
      }
      if (section1End != null && section1End.isNotEmpty) {
        payload['section1_end'] = section1End;
      }
      if (section2Start != null && section2Start.isNotEmpty) {
        payload['section2_start'] = section2Start;
      }
      if (section2End != null && section2End.isNotEmpty) {
        payload['section2_end'] = section2End;
      }
      if (workDays != null && workDays.isNotEmpty) {
        payload['work_days'] = workDays;
      }

      final response = await _apiService.post('/employees/', body: payload);

      if (response is Map) {
        if (response.containsKey('employee') && response['employee'] is Map) {
          final newEmp = EmployeeModel.fromJson(
            Map<String, dynamic>.from(response['employee']),
          );
          employees.insert(0, newEmp);
        }

        // Automatically trigger Firebase to send password setup/reset email to user's Gmail
        try {
          await _firebaseService.resetPassowrd(email: email);
        } catch (e) {
          debugPrint('Notice: Firebase auto email dispatch: $e');
        }

        return true;
      }
      return false;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed to Invite',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not invite employee: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateEmployee({
    required int id,
    required String fullname,
    required String email,
    required UserRole role,
    int? branchId,
    int? departmentId,
    String? employeeId,
    String? section1Start,
    String? section1End,
    String? section2Start,
    String? section2End,
    String? workDays,
  }) async {
    if (isLoading.value) return false;

    try {
      isLoading.value = true;
      final payload = <String, dynamic>{
        'fullname': fullname,
        'email': email,
        'role': userRoleToString(role),
      };

      payload['branch'] = branchId;
      payload['department'] = departmentId;
      if (employeeId != null) payload['employee_id'] = employeeId;
      if (section1Start != null) payload['section1_start'] = section1Start;
      if (section1End != null) payload['section1_end'] = section1End;
      if (section2Start != null) payload['section2_start'] = section2Start;
      if (section2End != null) payload['section2_end'] = section2End;
      if (workDays != null) payload['work_days'] = workDays;

      final response = await _apiService.patch(
        '/employees/$id/',
        body: payload,
      );

      if (response is Map) {
        final updatedEmp = EmployeeModel.fromJson(
          Map<String, dynamic>.from(response),
        );
        final index = employees.indexWhere((e) => e.id == id);
        if (index != -1) {
          employees[index] = updatedEmp;
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
        'Could not update employee: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resendInvitation(EmployeeModel employee) async {
    try {
      // 1. Call backend to generate invitation link
      await _apiService.post('/employees/${employee.id}/resend-invitation/');

      // 2. Trigger Firebase to send password reset/setup email
      try {
        await _firebaseService.resetPassowrd(email: employee.email);
      } catch (e) {
        debugPrint('Firebase reset password note: $e');
      }

      Get.snackbar(
        'Invitation Sent',
        'Invitation email resent to ${employee.email}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.mark_email_read_outlined, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
      return true;
    } on ApiException catch (e) {
      Get.snackbar(
        'Failed to Resend',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not resend invitation: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    }
  }
}
