import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Branded Apple-style animated Splash Screen that verifies authentication
/// and smoothly directs users to either the main dashboard or login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Brief branded delay for visual polish
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final secureStorage = SecureStorageService();
    final rememberMe = await secureStorage.getRememberMe();
    final hasSession = await secureStorage.hasValidSession();
    final currentUser = LocalAuthService().getCurrentUser();

    final bool isAuthenticated = rememberMe && (currentUser != null || hasSession);

    if (isAuthenticated) {
      Get.offAllNamed(AppRoutes.navigation);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branded Biometric Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066CC), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066CC).withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      FluentIcons.person_passkey_24_filled,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App Title
                Text(
                  'Face Attendance',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  'Smart Biometric Workforce System',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 48),

                // Subtle Loading Spinner
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white54 : const Color(0xFF0066CC),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
