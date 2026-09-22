import 'package:face_recognition_attendance/core/permissions/permission_service.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/department/controller/department_controller.dart';
import 'package:face_recognition_attendance/features/employee/controller/employee_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LoginController>(LoginController(), permanent: true);
    Get.put<PermissionService>(PermissionService(), permanent: true);
    Get.lazyPut<BranchController>(() => BranchController(), fenix: true);
    Get.lazyPut<DepartmentController>(() => DepartmentController(), fenix: true);
    Get.lazyPut<EmployeeController>(() => EmployeeController(), fenix: true);
  }
}
