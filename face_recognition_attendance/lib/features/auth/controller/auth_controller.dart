import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/service/firebase_service.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  final Rx<UserModel?> currentuser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  bool get isLoggedIn => currentuser.value != null;

  @override
  void onInit() {
    super.onInit();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final firebaseUser = _firebaseService.getCurrentUser();
    if (firebaseUser != null) {
      final user = await _firebaseService.getUserByUid(firebaseUser.uid);
      if (user != null) {
        currentuser.value = user;
      }
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
            _navigationBasedOnRole(user.role);                                                                                          
            return true;                                                                                                                
          } else {                                                                                                                      
            // 2. User exists in Auth, but NO document found in Firestore                                                               
            await _firebaseService.logout(); // Clean up auth session so they aren't stuck in a half-logged-in state                    
                                                                                                                                        
            errorMessage.value = "User profile not found in database. Please contact an administrator.";                                
                                                                                                                                        
            Get.snackbar(                                                                                                               
              'Account Not Found',                                                                                                      
              errorMessage.value,                                                                                                       
              snackPosition: SnackPosition.BOTTOM,                                                                                      
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
            snackPosition: SnackPosition.BOTTOM,                                                                                        
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

  Future<void> logOut() async {
    await _firebaseService.logout();
    currentuser.value = null;
    Get.offNamed(AppRoutes.login);
  }

  void _navigationBasedOnRole(UserRole role) {
    Get.offAllNamed(AppRoutes.navigation);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use'))
      return 'That email is already registered.';
    if (msg.contains('weak-password'))
      return 'Password must be at least 6 characters.';
    if (msg.contains('user-not-found'))
      return 'No account found with that email.';
    if (msg.contains('wrong-password')) return 'Incorrect password.';
    if (msg.contains('invalid-email'))
      return 'That email address looks invalid.';
    return msg;
  }
}
