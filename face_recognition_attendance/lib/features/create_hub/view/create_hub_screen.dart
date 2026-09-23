import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : null;

    final role = loginController?.currentuser.value?.role ?? UserRole.employee;
    final isCeo = role == UserRole.ceo || role == UserRole.admin;
    final isManager = role == UserRole.manager;
    final isLeader = role == UserRole.leader;

    return Scaffold(
      backgroundColor: RequestColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCeo
                        ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
                        : (isManager
                            ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                            : [const Color(0xFFB45309), const Color(0xFFF59E0B)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: (isCeo
                              ? const Color(0xFF0F172A)
                              : (isManager ? const Color(0xFF1E3A8A) : const Color(0xFFB45309)))
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCeo
                                ? Icons.domain_rounded
                                : (isManager
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.groups_rounded),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCeo
                                  ? 'CEO Hub'
                                  : (isManager ? 'Manager Hub' : 'Leader Hub'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCeo
                                  ? 'Executive Administration & Shifts'
                                  : (isManager
                                      ? 'Organization & Team Actions'
                                      : 'Team Growth & Invites'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isCeo
                          ? 'Manage organizational departments, change user session times, and coordinate staff.'
                          : (isManager
                              ? 'Create departments and invite Leaders or Employees to your organization.'
                              : 'Invite new Employees to join your operational team.'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Actions Section Title
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: RequestColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              if (isCeo || isManager) ...[
                _HubActionTile(
                  icon: Icons.domain_add_rounded,
                  iconBg: const Color(0xFF1D4ED8),
                  title: 'Create Department',
                  subtitle: 'Add department to an existing branch',
                  onTap: () => Get.toNamed(AppRoutes.createDepartment),
                ),
                const SizedBox(height: 12),
                _HubActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  iconBg: const Color(0xFFB45309),
                  title: isCeo ? 'Invite Staff / Manager' : 'Invite User',
                  subtitle: isCeo
                      ? 'Invite a Manager, Leader, or Employee'
                      : 'Invite a Leader or Employee to join',
                  onTap: () => Get.toNamed(AppRoutes.createEmployee),
                ),
              ] else if (isLeader) ...[
                _HubActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  iconBg: const Color(0xFFB45309),
                  title: 'Invite Employee',
                  subtitle: 'Invite a new Employee to your team',
                  onTap: () => Get.toNamed(AppRoutes.createEmployee),
                ),
              ],

              const SizedBox(height: 32),

              // Directories Section Title
              const Text(
                'DIRECTORIES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: RequestColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              if (isCeo || isManager) ...[
                _HubActionTile(
                  icon: Icons.apartment_rounded,
                  iconBg: const Color(0xFF4F46E5),
                  title: 'Departments List',
                  subtitle: 'View and manage created departments',
                  onTap: () => Get.toNamed(AppRoutes.departmentList),
                ),
                const SizedBox(height: 12),
              ],

              _HubActionTile(
                icon: Icons.badge_outlined,
                iconBg: const Color(0xFF0F766E),
                title: isCeo
                    ? 'Staff & Session Schedules'
                    : (isManager ? 'Staff & Users Directory' : 'Team Directory'),
                subtitle: isCeo
                    ? 'View staff profiles, change session times, and manage users'
                    : 'View staff, resend invitations, and manage members',
                onTap: () => Get.toNamed(AppRoutes.employeeList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubActionTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconBg, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: RequestColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
