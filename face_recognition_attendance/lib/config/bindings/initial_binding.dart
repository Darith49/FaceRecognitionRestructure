import 'package:face_recognition_attendance/core/permissions/permission_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/department/controller/department_controller.dart';
import 'package:face_recognition_attendance/features/employee/controller/employee_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  final UserModel? initialUser;
  InitialBinding({this.initialUser});

  @override
  void dependencies() {
    Get.put<SecureStorageService>(SecureStorageService(), permanent: true);
    final loginController = Get.put<LoginController>(LoginController(), permanent: true);
    final user = initialUser;
    if (user != null) {
      loginController.currentuser.value = user;
      loginController.hasFaceRegistered.value = user.hasFaceRegistered;
      loginController.checkFaceStatus();
    }
    Get.put<PermissionService>(PermissionService(), permanent: true);
    Get.lazyPut<BranchController>(() => BranchController(), fenix: true);
    Get.lazyPut<DepartmentController>(() => DepartmentController(), fenix: true);
    Get.lazyPut<EmployeeController>(() => EmployeeController(), fenix: true);
  }
}
