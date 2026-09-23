import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/service/firebase_service.dart';
import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/myteam_screen/controller/myteam_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  final Rx<UserModel?> currentuser = Rx<UserModel?>(null);
  final RxBool hasFaceRegistered = false.obs;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //UI State
  final RxBool isGoogleLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final RxBool rememberMe = true.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  bool get isLoggedIn => currentuser.value != null;

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
    } catch (_) {
      // Graceful fallback
    }
  }

  Future<void> _checkCurrentUser() async {
    final secureStorage = SecureStorageService();
    final remember = await secureStorage.getRememberMe();
    if (!remember) {
      // User unchecked remember me previously: do not restore cached session
      return;
    }

    final firebaseUser = _firebaseService.getCurrentUser();
    if (firebaseUser != null) {
      final user = await _firebaseService.getUserByUid(firebaseUser.uid);
      if (user != null) {
        currentuser.value = user;
        hasFaceRegistered.value = user.hasFaceRegistered;
        if (user.profileUrl != null && user.profileUrl!.isNotEmpty) {
          _syncProfileToBackend(user.profileUrl!);
        }
        final token = await _firebaseService.getIdToken();
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
          final user = UserModel.fromJson(cached);
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
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final user = await _firebaseService.login(
        email: email,
        password: password,
      );

      if (user != null) {
        currentuser.value = user; // 1. Save user state
        hasFaceRegistered.value = user.hasFaceRegistered;
        if (user.profileUrl != null && user.profileUrl!.isNotEmpty) {
          _syncProfileToBackend(user.profileUrl!);
        }
        final token = await _firebaseService.getIdToken(forceRefresh: true);
        final firebaseUser = _firebaseService.getCurrentUser();

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
        _navigationBasedOnRole(user.role);
        return true;
      } else {
        // 2. User exists in Auth, but NO document found in Firestore
        await _firebaseService.logout(); // Clean up auth session so they aren't stuck in a half-logged-in state
        await SecureStorageService().clearAll();

        errorMessage.value = "User profile not found in database. Please contact an administrator.";

        Get.snackbar(
          'Account Not Found',
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
      errorMessage.value = _friendlyError(e);
      Get.snackbar(
        'Login Failed',
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

  //Log In with google
  Future<void> loginWithGoogle() async {
    isGoogleLoading.value = true;
    errorMessage.value = "";

    try {
      final credential = await _firebaseService.signInWithGoogle();
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Google authentication failed.');
      }

      // 1. Try finding employee by UID
      var user = await _firebaseService.getUserByUid(firebaseUser.uid);

      // 2. If not found by UID, search by email and link to this UID
      if (user == null && firebaseUser.email != null) {
        user = await _firebaseService.getUserByEmail(firebaseUser.email!);
        if (user != null) {
          await _firebaseService.linkFirestoreUser(firebaseUser.uid, user);
          user = user.copyWith(uid: firebaseUser.uid);
        }
      }

      if (user == null) {
        await _firebaseService.logout();

        final email = firebaseUser.email ?? '';
        errorMessage.value = email.isNotEmpty
            ? 'No employee profile found for $email. Please contact an administrator.'
            : 'User profile not found. Please contact an administrator.';

        Get.snackbar(
          'Account Not Found',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
        return;
      }
      currentuser.value = user;
      if (user.profileUrl != null && user.profileUrl!.isNotEmpty) {
        _syncProfileToBackend(user.profileUrl!);
      }

      await SecureStorageService().setRememberMe(rememberMe.value);
      if (rememberMe.value) {
        final token = await _firebaseService.getIdToken();
        final firebaseUser = _firebaseService.getCurrentUser();
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

      _navigationBasedOnRole(user.role);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      errorMessage.value = msg;

      if (!msg.toLowerCase().contains('cancelled')) {
        Get.snackbar(
          'Sign In Failed',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isGoogleLoading.value = false;
    }
  }

  /// Update the current user's profile picture in state and Firestore
  Future<void> updateProfilePicture(String profileUrl) async {
    final user = currentuser.value;
    if (user != null) {
      currentuser.value = user.copyWith(profileUrl: profileUrl);
      try {
        await _firebaseService.updateProfilePicture(user.uid, profileUrl);
      } catch (e) {
        debugPrint('Error updating profile picture in Firestore: $e');
      }
      await _syncProfileToBackend(profileUrl);

      // Auto-refresh MyTeam tab so it reflects the updated picture immediately
      if (Get.isRegistered<MyTeamController>()) {
        Get.find<MyTeamController>().fetchMyTeam(refresh: true);
      }
    }
  }

  Future<void> logOut() async {
    try {
      await _firebaseService.logout();
    } catch (e) {
      debugPrint('Logout service error: $e');
    } finally {
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
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'That email is already registered.';
    }
    if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('user-not-found')) {
      return 'No account found with that email.';
    }
    if (msg.contains('wrong-password')) {
      return 'Incorrect password.';
    }
    if (msg.contains('invalid-email')) {
      return 'That email address looks invalid.';
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
