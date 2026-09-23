import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/myteam_screen/model/my_team_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class MyTeamController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  final RxInt selectedTabIndex = 0.obs;
  final RxString searchQuery = ''.obs;

  final Rx<MyTeamResponse?> teamData = Rx<MyTeamResponse?>(null);

  /// Dynamic pin IDs for fast UI updates (max 3)
  final RxSet<int> pinnedMemberIds = <int>{}.obs;

  static const int maxPins = 3;

  @override
  void onInit() {
    super.onInit();
    fetchMyTeam();
  }

  Future<void> fetchMyTeam({bool refresh = false}) async {
    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final res = await _apiService.get('/employees/my-team/');
      if (res is Map) {
        final parsed = MyTeamResponse.fromJson(Map<String, dynamic>.from(res));
        teamData.value = parsed;

        // Populate initial pinned members from backend response
        for (final m in parsed.pinned) {
          pinnedMemberIds.add(m.id);
        }

        if (selectedTabIndex.value >= parsed.tabs.length) {
          selectedTabIndex.value = 0;
        }
      } else {
        errorMessage.value = 'Failed to load team data.';
      }
    } catch (e) {
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Unable to connect to server. Please try again.';
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void selectTab(int index) {
    if (index >= 0 && index < (teamData.value?.tabs.length ?? 0)) {
      selectedTabIndex.value = index;
    }
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  bool isPinned(int memberId) {
    return pinnedMemberIds.contains(memberId);
  }

  void togglePin(MyTeamMember member, BuildContext context) {
    if (pinnedMemberIds.contains(member.id)) {
      pinnedMemberIds.remove(member.id);
    } else {
      if (pinnedMemberIds.length >= maxPins) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'You can pin up to $maxPins profiles. Unpin one first.',
        );
        return;
      }
      pinnedMemberIds.add(member.id);
    }
  }

  Future<void> makePhoneCall(String? phoneNumber, String memberName, BuildContext context) async {
    final phone = (phoneNumber ?? '').trim();
    if (phone.isEmpty) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'No phone number available for $memberName.',
      );
      return;
    }

    // Keep digits and leading plus sign
    final cleanNumber = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri.parse('tel:$cleanNumber');

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback standard launch
        await launchUrl(phoneUri);
      }
    } catch (e) {
      if (context.mounted) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Error opening dialer: $e',
        );
      }
    }
  }

  Future<bool> updateMemberSessionTime({
    required int memberId,
    required String section1Start,
    required String section1End,
    required String section2Start,
    required String section2End,
    required String workDays,
  }) async {
    try {
      final res = await _apiService.patch('/employees/$memberId/', body: {
        'section1_start': section1Start,
        'section1_end': section1End,
        'section2_start': section2Start,
        'section2_end': section2End,
        'work_days': workDays,
      });
      if (res is Map) {
        await fetchMyTeam(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      if (e is ApiException) {
        throw Exception(e.message);
      }
      throw Exception('Failed to update session time: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  String get currentRole => teamData.value?.role ?? 'employee';
  bool get isCeo => currentRole == 'ceo';
  bool get isManager => currentRole == 'manager';
  bool get isLeader => currentRole == 'leader';
  bool get isEmployee => currentRole == 'employee';

  List<MyTeamTab> get tabs => teamData.value?.tabs ?? [];

  MyTeamTab? get currentTab {
    final list = tabs;
    if (list.isEmpty) return null;
    final idx = selectedTabIndex.value;
    if (idx >= 0 && idx < list.length) {
      return list[idx];
    }
    return list.first;
  }

  /// Pinned member list:
  /// Combines backend pinned members and any tab members the user manually pinned.
  List<MyTeamMember> get pinnedMembers {
    final data = teamData.value;
    if (data == null) return [];

    final Map<int, MyTeamMember> map = {};
    for (final m in data.pinned) {
      if (pinnedMemberIds.contains(m.id)) {
        map[m.id] = m;
      }
    }

    for (final tab in data.tabs) {
      if (!tab.isBranchList) {
        for (final item in tab.items) {
          if (item is MyTeamMember && pinnedMemberIds.contains(item.id)) {
            map[item.id] = item;
          }
        }
      }
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      return map.values.toList();
    }

    return map.values.where((m) =>
      m.fullname.toLowerCase().contains(q) ||
      m.displayRole.toLowerCase().contains(q) ||
      (m.departmentName?.toLowerCase().contains(q) ?? false) ||
      (m.branchName?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  /// Items for the current tab, filtered by search query and excluding items
  /// that are already shown in the Pinned section.
  List<dynamic> get currentFilteredItems {
    final tab = currentTab;
    if (tab == null) return [];

    final q = searchQuery.value.trim().toLowerCase();

    if (tab.isBranchList) {
      final branches = tab.items.cast<MyTeamBranch>();
      if (q.isEmpty) return branches;
      return branches.where((b) =>
        b.name.toLowerCase().contains(q) ||
        b.managerName.toLowerCase().contains(q)
      ).toList();
    } else {
      final members = tab.items.cast<MyTeamMember>();
      return members.where((m) {
        // Exclude if already in pinnedMembers
        if (pinnedMemberIds.contains(m.id)) return false;

        if (q.isEmpty) return true;
        return m.fullname.toLowerCase().contains(q) ||
          m.displayRole.toLowerCase().contains(q) ||
          (m.departmentName?.toLowerCase().contains(q) ?? false) ||
          (m.branchName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }
}
