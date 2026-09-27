import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/app_avatar.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/myteam_screen/controller/myteam_controller.dart';
import 'package:face_recognition_attendance/features/myteam_screen/model/my_team_model.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/widgets/change_session_time_dialog.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Local design tokens
// ---------------------------------------------------------------------------

const Color _primaryDark = Color(0xFF2456C7);

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0F1B2437), blurRadius: 14, offset: Offset(0, 4)),
];

class MyteamScreen extends StatefulWidget {
  const MyteamScreen({super.key});

  @override
  State<MyteamScreen> createState() => _MyteamScreenState();
}

class _MyteamScreenState extends State<MyteamScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final MyTeamController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<MyTeamController>()
        ? Get.find<MyTeamController>()
        : Get.put(MyTeamController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChangeSessionTimeDialog(MyTeamMember member) async {
    await ChangeSessionTimeDialog.showForMember(
      context,
      member: member,
      onSave: ({
        required int memberId,
        required String section1Start,
        required String section1End,
        required String section2Start,
        required String section2End,
        required String workDays,
      }) async {
        return await _controller.updateMemberSessionTime(
          memberId: memberId,
          section1Start: section1Start,
          section1End: section1End,
          section2Start: section2Start,
          section2End: section2End,
          workDays: workDays,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'My Team'.tr,
      showBackButton: false,
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: RequestColors.primary),
          );
        }

        if (_controller.errorMessage.value.isNotEmpty && _controller.teamData.value == null) {
          return _buildErrorState(context);
        }

        final tabs = _controller.tabs;
        final pinned = _controller.pinnedMembers;
        final currentTab = _controller.currentTab;
        final filteredItems = _controller.currentFilteredItems;

        return RefreshIndicator(
          color: RequestColors.primary,
          onRefresh: () => _controller.fetchMyTeam(refresh: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _buildSearchBar(context),
              ),

              // Segmented tabs (e.g. Managers/Branches, My Leaders/Team, etc.)
              if (tabs.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSegmentedTabs(tabs, context),
                ),
                const SizedBox(height: 14),
              ],

              // Content List
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    // Pinned Section
                    if (pinned.isNotEmpty) ...[
                      _SectionHeader(
                        'Pinned'.tr,
                        badge: '${pinned.length}/${MyTeamController.maxPins}',
                        badgeColor: pinned.length >= MyTeamController.maxPins
                            ? RequestColors.gold
                            : RequestColors.primary,
                      ),
                      ...pinned.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: (m.isCeo || m.isManager)
                            ? _buildFeaturedCard(m, isPinned: true, context: context)
                            : _buildMemberCard(m, isPinned: true, context: context),
                      )),
                      const SizedBox(height: 10),
                    ],

                    // Current Tab Section
                    if (currentTab != null) ...[
                      _SectionHeader(
                        currentTab.title.tr,
                        badge: '${filteredItems.length}',
                      ),
                      if (filteredItems.isNotEmpty)
                        ...filteredItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: currentTab.isBranchList
                                ? _buildBranchCard(item as MyTeamBranch, context: context)
                                : _buildMemberItem(item as MyTeamMember, context: context),
                          );
                        })
                      else
                        _buildEmptyState(context),
                    ] else if (pinned.isEmpty) ...[
                      _buildEmptyState(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Search Bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))] : _softShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _controller.updateSearch,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : Colors.white,
          hintText: 'Search by name, role, or branch'.tr,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            FluentIcons.search_24_regular,
            color: RequestColors.primary,
            size: 22,
          ),
          suffixIcon: _controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    FluentIcons.dismiss_24_regular,
                    color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearSearch();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 4,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: isDark ? const BorderSide(color: AppColors.darkBorder) : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: RequestColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Segmented Tabs
  // ---------------------------------------------------------------------------

  Widget _buildSegmentedTabs(List<MyTeamTab> tabs, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFE8E8ED),
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = i == _controller.selectedTabIndex.value;

          return Expanded(
            child: GestureDetector(
              onTap: () => _controller.selectTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? AppColors.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: selected && isDark ? Border.all(color: AppColors.darkBorder) : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.title.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? (isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary)
                            : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? RequestColors.primary.withValues(alpha: 0.12)
                            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tab.badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? RequestColors.primary
                              : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Member item router
  // ---------------------------------------------------------------------------

  Widget _buildMemberItem(MyTeamMember member, {required BuildContext context}) {
    if (member.isCeo || member.isManager) {
      return _buildFeaturedCard(member, isPinned: _controller.isPinned(member.id), context: context);
    }
    return _buildMemberCard(member, isPinned: _controller.isPinned(member.id), context: context);
  }

  // ---------------------------------------------------------------------------
  // Featured / Gradient Card (CEO & Manager)
  // ---------------------------------------------------------------------------

  Widget _buildFeaturedCard(MyTeamMember member, {required bool isPinned, required BuildContext context}) {
    final loginController = Get.isRegistered<LoginController>() ? Get.find<LoginController>() : null;
    final currentUser = loginController?.currentuser.value;
    final isSelf = currentUser != null && (
      (member.firebaseUid.isNotEmpty && member.firebaseUid == currentUser.uid) ||
      (member.email.isNotEmpty && member.email.toLowerCase() == currentUser.email.toLowerCase())
    );
    final effectiveProfileUrl = isSelf ? (currentUser.profileUrl ?? member.profileUrl) : member.profileUrl;

    final avatar = AppAvatar(
      profileUrl: effectiveProfileUrl,
      name: member.fullname,
      size: 54,
      backgroundColor: Colors.white,
      textColor: RequestColors.primary,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.45),
        width: 3,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RequestColors.primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: RequestColors.primary.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _withPinBadge(avatar, isPinned),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.displayRole.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (member.hasFaceRegistered) ...[
                      const SizedBox(width: 6),
                      Icon(
                        FluentIcons.checkmark_starburst_24_filled,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 15,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  member.fullname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.branchName != null && member.branchName!.isNotEmpty
                      ? '${'Branch'.tr}: ${member.branchName}'
                      : member.organizationSubtitle.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!member.isCeo) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.clock_24_regular, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${member.formattedShiftSummary} • ${member.formattedWorkDays}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildMemberActions(member, isPinned: isPinned, onDark: true, context: context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Standard Member Card (Leader & Employee)
  // ---------------------------------------------------------------------------

  Widget _buildMemberCard(MyTeamMember member, {required bool isPinned, required BuildContext context}) {
    final color = member.roleColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final loginController = Get.isRegistered<LoginController>() ? Get.find<LoginController>() : null;
    final currentUser = loginController?.currentuser.value;
    final isSelf = currentUser != null && (
      (member.firebaseUid.isNotEmpty && member.firebaseUid == currentUser.uid) ||
      (member.email.isNotEmpty && member.email.toLowerCase() == currentUser.email.toLowerCase())
    );
    final effectiveProfileUrl = isSelf ? (currentUser.profileUrl ?? member.profileUrl) : member.profileUrl;

    final avatar = AppAvatar(
      profileUrl: effectiveProfileUrl,
      name: member.fullname,
      size: 50,
      gradientColors: [color, Color.lerp(color, Colors.black, 0.25)!],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appleCardDecoration(context: context, radius: 18),
      child: Row(
        children: [
          _withPinBadge(avatar, isPinned),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        member.fullname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
                        ),
                      ),
                    ),
                    if (member.hasFaceRegistered) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        FluentIcons.checkmark_starburst_24_filled,
                        color: RequestColors.primary,
                        size: 15,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.displayRole.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  member.organizationSubtitle.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : RequestColors.softSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.clock_24_regular, size: 12, color: RequestColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${member.formattedShiftSummary} • ${member.formattedWorkDays}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildMemberActions(member, isPinned: isPinned, onDark: false, context: context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Branch Card (For CEO Branches tab)
  // ---------------------------------------------------------------------------

  Widget _buildBranchCard(MyTeamBranch branch, {required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appleCardDecoration(context: context, radius: 18),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              FluentIcons.building_multiple_24_regular,
              color: RequestColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      FluentIcons.person_24_regular,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${'Manager'.tr}: ${branch.managerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${branch.totalEmployees} ${'Employees'.tr} • ${branch.totalDepartments} ${'Departments'.tr}',
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _circleButton(
            icon: FluentIcons.call_24_regular,
            tooltip: branch.hasManagerPhone
                ? '${'Call'.tr} ${branch.managerName}'
                : 'No phone number available'.tr,
            background: branch.hasManagerPhone
                ? RequestColors.primary.withValues(alpha: 0.12)
                : (isDark ? AppColors.darkCard : RequestColors.background),
            iconColor: branch.hasManagerPhone
                ? RequestColors.primary
                : (isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.4) : RequestColors.textSecondary.withValues(alpha: 0.4)),
            onTap: () {
              _controller.makePhoneCall(
                branch.managerPhone,
                branch.managerName,
                context,
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Buttons & Pin Badge
  // ---------------------------------------------------------------------------

  Widget _withPinBadge(Widget avatar, bool pinned) {
    if (!pinned) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _softShadow,
            ),
            child: const Icon(
              FluentIcons.pin_24_filled,
              size: 12,
              color: RequestColors.danger,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberActions(
    MyTeamMember member, {
    required bool isPinned,
    required bool onDark,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pinBackground = onDark
        ? Colors.white.withValues(alpha: isPinned ? 0.32 : 0.16)
        : (isPinned
            ? RequestColors.primary.withValues(alpha: 0.12)
            : (isDark ? AppColors.darkCard : RequestColors.background.withValues(alpha: 0.6)));
    final Color pinIconColor = onDark
        ? Colors.white
        : (isPinned ? RequestColors.primary : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary));

    final bool hasPhone = member.hasPhoneNumber;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_controller.canEditSessionFor(member)) ...[
          _circleButton(
            icon: FluentIcons.clock_24_regular,
            tooltip: 'Change Session Time'.tr,
            background: onDark
                ? Colors.white.withValues(alpha: 0.25)
                : RequestColors.primary.withValues(alpha: 0.12),
            iconColor: onDark ? Colors.white : RequestColors.primary,
            onTap: () => _openChangeSessionTimeDialog(member),
          ),
          const SizedBox(width: 8),
        ],
        _circleButton(
          icon: isPinned ? FluentIcons.pin_24_filled : FluentIcons.pin_24_regular,
          tooltip: isPinned ? 'Unpin'.tr : 'Pin'.tr,
          background: pinBackground,
          iconColor: pinIconColor,
          onTap: () => _controller.togglePin(member, context),
        ),
        const SizedBox(width: 8),
        _circleButton(
          icon: FluentIcons.call_24_regular,
          tooltip: hasPhone ? '${'Call'.tr} ${member.fullname}' : 'No phone number available'.tr,
          background: onDark
              ? Colors.white
              : (hasPhone
                  ? RequestColors.primary.withValues(alpha: 0.10)
                  : (isDark ? AppColors.darkCard : RequestColors.background)),
          iconColor: onDark
              ? RequestColors.primary
              : (hasPhone
                  ? RequestColors.primary
                  : (isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.4) : RequestColors.textSecondary.withValues(alpha: 0.4))),
          onTap: () => _controller.makePhoneCall(member.phoneNumber, member.fullname, context),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty & Error States
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
              boxShadow: isDark ? const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))] : _softShadow,
            ),
            child: const Icon(
              FluentIcons.search_info_24_regular,
              size: 32,
              color: RequestColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No team members found'.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching by a different name, role, or branch.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: BoxShape.circle,
                border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                boxShadow: isDark ? const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))] : _softShadow,
              ),
              child: const Icon(
                FluentIcons.cloud_dismiss_24_regular,
                size: 32,
                color: RequestColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load team data'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _controller.fetchMyTeam(),
              icon: const Icon(FluentIcons.arrow_clockwise_24_regular, size: 18),
              label: Text('Retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: RequestColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
    this.title, {
    this.badge,
    this.badgeColor = RequestColors.primary,
  });

  final String title;
  final String? badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}