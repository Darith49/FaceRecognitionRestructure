import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/core/services/sqlite_sync_service.dart';
import 'package:face_recognition_attendance/core/utils/image_compressor.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/myteam_screen/controller/myteam_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final LocalAuthService _authService = LocalAuthService();

  final Rx<UserModel?> currentuser = Rx<UserModel?>(null);
  final RxBool hasFaceRegistered = false.obs;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //UI State
  final RxBool isPasswordHidden = true.obs;
  final RxBool rememberMe = true.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxBool isDemoExpanded = false.obs;

  bool get isLoggedIn => currentuser.value != null;
  bool get isCeo => currentuser.value?.role == UserRole.ceo;

  @override
  void onInit() {
    super.onInit();
    emailController.text = '';
    passwordController.text = '';
    errorMessage.value = '';
    _loadRememberMe();
    _checkCurrentUser();
  }

  Future<void> _loadRememberMe() async {
    final val = await SecureStorageService().getRememberMe();
    rememberMe.value = val;
  }

  Future<void> checkFaceStatus() async {
    try {
      final api = ApiService();
      final res = await api.get('/face/status/');
      if (res is Map && res.containsKey('registered')) {
        final registered = res['registered'] == true;
        hasFaceRegistered.value = registered;
        if (currentuser.value != null && currentuser.value!.hasFaceRegistered != registered) {
          currentuser.value = currentuser.value!.copyWith(hasFaceRegistered: registered);
          await SecureStorageService().updateCachedUserData(currentuser.value!.toJson());
        }
      }
    } catch (e) {
      Get.snackbar(
        'Face Biometrics'.tr,
        'Could not verify registered face status.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF374151),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _checkCurrentUser() async {
    final secureStorage = SecureStorageService();
    final remember = await secureStorage.getRememberMe();
    if (!remember) {
      // User unchecked remember me previously: do not restore cached session
      return;
    }

    final firebaseUser = _authService.getCurrentUser();
    if (firebaseUser != null) {
      var user = await _authService.getUserByUid(firebaseUser.uid);
      if (user != null) {
        final vault = LocalDatabaseService().getUserAccountData(user.email);
        if (vault != null) {
          user = user.copyWith(
            profileUrl: (vault['profile_picture'] != null && vault['profile_picture'].toString().isNotEmpty)
                ? vault['profile_picture']
                : user.profileUrl,
            hasFaceRegistered: vault['has_face_registered'] == true || user.hasFaceRegistered,
          );
        }
        LocalDatabaseService().setDemoMode(isDemoAccountEmail(user.email));
        currentuser.value = user;
        hasFaceRegistered.value = user.hasFaceRegistered;
        final token = await _authService.getIdToken();
        final refreshToken = firebaseUser.refreshToken;
        await secureStorage.saveUserSession(
          uid: user.uid,
          email: user.email,
          accessToken: token ?? '',
          refreshToken: refreshToken,
          userData: user.toJson(),
        );
        await checkFaceStatus();
        return;
      }
    }

    // Fallback to SecureStorageService for persistent offline launch
    if (await secureStorage.hasValidSession()) {
      final cached = await secureStorage.getCachedUserData();
      if (cached != null) {
        try {
          var user = UserModel.fromJson(cached);
          final vault = LocalDatabaseService().getUserAccountData(user.email);
          if (vault != null) {
            user = user.copyWith(
              profileUrl: (vault['profile_picture'] != null && vault['profile_picture'].toString().isNotEmpty)
                  ? vault['profile_picture']
                  : user.profileUrl,
              hasFaceRegistered: vault['has_face_registered'] == true || user.hasFaceRegistered,
            );
          }
          LocalDatabaseService().setDemoMode(isDemoAccountEmail(user.email));
          currentuser.value = user;
          hasFaceRegistered.value = user.hasFaceRegistered;
          await checkFaceStatus();
        } catch (_) {}
      }
    }
  }

  Future<void> _syncProfileToBackend(String profileUrl) async {
    try {
      final api = ApiService();
      await api.patch('/employees/me/', body: {'profile_url': profileUrl});
    } catch (_) {
      // Graceful fallback if backend is offline or unauthenticated yet
    }
  }

  Future<bool> login({required String email, required String password}) async {
    emailError.value = '';
    passwordError.value = '';
    errorMessage.value = '';

    bool hasError = false;
    if (email.trim().isEmpty) {
      emailError.value = 'Email is required'.tr;
      hasError = true;
    } else if (!GetUtils.isEmail(email.trim())) {
      emailError.value = 'That email address looks invalid.'.tr;
      hasError = true;
    }

    if (password.isEmpty) {
      passwordError.value = 'Password is required'.tr;
      hasError = true;
    }

    if (hasError) return false;

    try {
      isLoading.value = true;
      errorMessage.value = "";

      final user = await _authService.login(
        email: email,
        password: password,
      );

      if (user != null) {
        LocalDatabaseService().setDemoMode(isDemoAccountEmail(user.email));
        currentuser.value = user; // 1. Save user state
        hasFaceRegistered.value = user.hasFaceRegistered;
        if (user.profileUrl != null && user.profileUrl!.isNotEmpty) {
          _syncProfileToBackend(user.profileUrl!);
        }
        final token = await _authService.getIdToken(forceRefresh: true);
        final firebaseUser = _authService.getCurrentUser();

        await SecureStorageService().setRememberMe(rememberMe.value);
        if (rememberMe.value) {
          await SecureStorageService().saveUserSession(
            uid: user.uid,
            email: user.email,
            accessToken: token ?? '',
            refreshToken: firebaseUser?.refreshToken,
            userData: user.toJson(),
          );
        } else {
          await SecureStorageService().clearSession();
        }
        await checkFaceStatus();
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications();
        }
        _navigationBasedOnRole(user.role);
        return true;
      } else {
        // 2. User exists in Auth, but NO document found in Firestore
        await _authService.logout(); // Clean up auth session so they aren't stuck in a half-logged-in state
        await SecureStorageService().clearAll();

        errorMessage.value = "User profile not found in database. Please contact an administrator.".tr;

        Get.snackbar(
          'Account Not Found'.tr,
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
        return false;
      }
    } catch (e) {
      final msg = _friendlyError(e);
      final eStr = e.toString().toLowerCase();
      if (eStr.contains('user-not-found') || eStr.contains('invalid-email')) {
        emailError.value = msg;
      } else if (eStr.contains('wrong-password')) {
        passwordError.value = msg;
      } else if (eStr.contains('invalid-credential') || eStr.contains('auth credential is incorrect')) {
        emailError.value = 'Incorrect email or password. Please try again.'.tr;
        passwordError.value = 'Incorrect email or password. Please try again.'.tr;
      }
      errorMessage.value = msg;
      Get.snackbar(
        'Login Failed'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update the current user's profile picture in state and Firestore
  Future<void> updateProfilePicture(String profileUrl) async {
    final user = currentuser.value;
    if (user != null) {
      final compressed = ImageCompressor.compressProfilePicture(profileUrl);
      final updated = user.copyWith(profileUrl: compressed);
      currentuser.value = updated;
      try {
        await _authService.updateProfilePicture(user.uid, compressed);
      } catch (e) {
        debugPrint('Error updating profile picture in Firestore: $e');
      }
      await _syncProfileToBackend(compressed);
      await SecureStorageService().updateCachedUserData(updated.toJson());
      await SqliteSyncService().syncProfilePicture(
        email: user.email,
        uid: user.uid,
        profilePictureBase64: compressed,
      );

      // Auto-refresh MyTeam tab so it reflects the updated picture immediately
      if (Get.isRegistered<MyTeamController>()) {
        Get.find<MyTeamController>().fetchMyTeam(refresh: true);
      }
    }
  }

  Future<void> logOut() async {
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Logout service error: $e');
    } finally {
      LocalDatabaseService().setDemoMode(null);
      await SecureStorageService().clearSession();
      await SecureStorageService().setRememberMe(true);
      rememberMe.value = true;
      currentuser.value = null;
      hasFaceRegistered.value = false;
      emailController.clear();
      passwordController.clear();
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changePage(0);
      }
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().reset();
        Get.delete<NotificationController>(force: true);
      }
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _navigationBasedOnRole(UserRole role) {
    Get.offAllNamed(AppRoutes.navigation);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-credential') ||
        msg.contains('auth credential is incorrect')) {
      return 'Incorrect email or password. Please try again.'.tr;
    }
    if (msg.contains('email-already-in-use')) {
      return 'That email is already registered.'.tr;
    }
    if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.'.tr;
    }
    if (msg.contains('user-not-found')) {
      return 'No account found with that email.'.tr;
    }
    if (msg.contains('wrong-password')) {
      return 'Incorrect password.'.tr;
    }
    if (msg.contains('invalid-email')) {
      return 'That email address looks invalid.'.tr;
    }
    return msg;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
