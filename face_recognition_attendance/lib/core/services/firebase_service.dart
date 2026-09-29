import 'dart:async';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';

/// Compatibility adapter for legacy FirebaseService imports.
/// Transparently delegates all authentication operations to LocalAuthService.
class FirebaseService {
  final LocalAuthService _auth = LocalAuthService();

  Future<UserModel?> login({
    required String email,
    required String password,
  }) {
    return _auth.login(email: email, password: password);
  }

  Future<UserModel> register({
    required String fullname,
    required String email,
    required String password,
    required UserRole role,
    int? branchId,
    String? branchName,
    int? departmentId,
    String? departmentName,
    String? employeeId,
  }) {
    return _auth.register(
      fullname: fullname,
      email: email,
      password: password,
      role: role,
      branchId: branchId,
      branchName: branchName,
      departmentId: departmentId,
      departmentName: departmentName,
      employeeId: employeeId,
    );
  }

  Future<void> logout() {
    return _auth.logout();
  }

  Future<void> resetPassowrd({required String email}) {
    return _auth.resetPassowrd(email: email);
  }

  dynamic getCurrentUser() {
    return _auth.getCurrentUser();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) {
    return _auth.getIdToken(forceRefresh: forceRefresh);
  }

  Future<UserModel?> getUserByUid(String uid) {
    return _auth.getUserByUid(uid);
  }

  Future<UserModel?> getUserByEmail(String email) {
    return _auth.getUserByEmail(email);
  }

  Future<void> updateProfilePicture(String uid, String profileUrl) {
    return _auth.updateProfilePicture(uid, profileUrl);
  }

  Future<void> linkFirestoreUser(String targetUid, UserModel user) {
    return _auth.linkFirestoreUser(targetUid, user);
  }
}
