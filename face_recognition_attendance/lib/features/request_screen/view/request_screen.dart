import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key, this.showBackButton = false});

  /// false = the "Request" tab of the bottom bar (no back arrow).
  /// true  = opened on top of another page, for example from the Clock screen.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Request',
      showBackButton: showBackButton,
      body: ListView(
        // Extra space at the bottom in the tab, so the floating bar does not cover the cards.
        padding: EdgeInsets.fromLTRB(16, 16, 16, showBackButton ? 24.0 : 120.0),
        children: [
          _RequestLinks(
            links: [
              // TODO(Hong): open the real pages when they are ready.
              _RequestLink('My Schedule', () => _comingSoon(context)),
              _RequestLink('Leave', () => Get.toNamed(AppRoutes.leave)),
              _RequestLink('Overtime', () => Get.toNamed(AppRoutes.overtime)),
              _RequestLink(
                'Suggestion',
                () => Get.toNamed(AppRoutes.suggestion),
              ),
              _RequestLink(
                'Clock Attendance',
                () => Get.toNamed(AppRoutes.clock),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Task 4 : Request Information + Permission ----
          RequestMenuCard(
            icon: Icons.receipt_long_outlined,
            iconBackground: RequestColors.primary,
            title: 'Request Information',
            subtitle: 'Authorized / Unauthorized',
            onTap: () => Get.toNamed(AppRoutes.requestInformation),
          ),
          const SizedBox(height: 12),
          RequestMenuCard(
            icon: Icons.how_to_reg_outlined,
            iconBackground: const Color(0xFF7B61C9),
            title: 'Permission',
            subtitle: 'Request Permission / Change Permission',
            onTap: () => Get.toNamed(AppRoutes.permission),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    RequestSnack.show(
      ScaffoldMessenger.of(context),
      'This page is coming soon.',
    );
  }
}

class _RequestLink {
  const _RequestLink(this.title, this.onTap);

  final String title;
  final VoidCallback onTap;
}

/// White card with the list of links (My Schedule, Leave, ...).
class _RequestLinks extends StatelessWidget {
  const _RequestLinks({required this.links});

  final List<_RequestLink> links;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < links.length; i++) ...[
            InkWell(
              onTap: links[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        links[i].title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: RequestColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: RequestColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
            if (i != links.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
