import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestScreenController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxBool isLoading = false.obs;
  final RxBool canApprove = false.obs;

  final RxList<Map<String, dynamic>> incomingLeaves = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> incomingOvertimes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> incomingPermissions = <Map<String, dynamic>>[].obs;
  final RxInt totalPending = 0.obs;
  final RxInt selectedTab = 0.obs;
  bool _hasInitializedTab = false;

  final RxList<UnifiedRequestModel> myRequests = <UnifiedRequestModel>[].obs;
  final RxString selectedCategoryFilter = 'All'.obs;
  final RxString selectedStatusFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    _checkRole();
    fetchIncoming();
    fetchMyRequests();
  }

  void _checkRole() {
    if (Get.isRegistered<LoginController>()) {
      final user = Get.find<LoginController>().currentuser.value;
      if (user != null) {
        canApprove.value = user.role == UserRole.ceo ||
            user.role == UserRole.admin ||
            user.role == UserRole.manager ||
            user.role == UserRole.leader;
      }
    }
  }

  Future<void> fetchMyRequests() async {
    try {
      final results = await Future.wait([
        _apiService.get('/requests/leave/'),
        _apiService.get('/requests/overtime/'),
        _apiService.get('/requests/suggestions/'),
        _apiService.get('/permissions/'),
      ]);

      final List<UnifiedRequestModel> items = [];
      if (results[0] is List) {
        for (final item in results[0] as List) {
          items.add(UnifiedRequestModel.fromLeave(Map<String, dynamic>.from(item)));
        }
      }
      if (results[1] is List) {
        for (final item in results[1] as List) {
          items.add(UnifiedRequestModel.fromOvertime(Map<String, dynamic>.from(item)));
        }
      }
      if (results[2] is List) {
        for (final item in results[2] as List) {
          items.add(UnifiedRequestModel.fromSuggestion(Map<String, dynamic>.from(item)));
        }
      }
      if (results[3] is List) {
        for (final item in results[3] as List) {
          items.add(UnifiedRequestModel.fromPermission(Map<String, dynamic>.from(item)));
        }
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      myRequests.assignAll(items);
    } catch (e) {
      debugPrint('Error fetching my requests: $e');
    }
  }

  List<UnifiedRequestModel> get filteredMyRequests {
    return myRequests.where((req) {
      if (selectedCategoryFilter.value != 'All' && req.category != selectedCategoryFilter.value) {
        return false;
      }
      if (selectedStatusFilter.value != 'All' && req.status.toLowerCase() != selectedStatusFilter.value.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> fetchIncoming() async {
    _checkRole();
    if (!canApprove.value) return;

    try {
      isLoading.value = true;
      final res = await _apiService.get('/requests/incoming/');
      if (res is Map) {
        totalPending.value = (res['total_pending'] as num?)?.toInt() ?? 0;
        if (res['leaves'] is List) {
          incomingLeaves.assignAll(
            (res['leaves'] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
        if (res['overtimes'] is List) {
          incomingOvertimes.assignAll(
            (res['overtimes'] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
        if (res['permissions'] is List) {
          incomingPermissions.assignAll(
            (res['permissions'] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
        if (!_hasInitializedTab) {
          selectedTab.value = totalPending.value > 0 ? 0 : 1;
          _hasInitializedTab = true;
        }
      }
    } catch (e) {
      debugPrint('Error fetching incoming requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reviewLeave(int id, bool approve, BuildContext context) async {
    try {
      final res = await _apiService.post(
        '/requests/leave/$id/review/',
        body: {'status': approve ? 'approved' : 'rejected'},
      );
      if (res is Map) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Leave request has been ${approve ? "approved" : "rejected"}.',
        );
        await fetchIncoming();
      }
    } catch (e) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'Failed to review leave request: $e',
      );
    }
  }

  Future<void> reviewOvertime(int id, bool approve, BuildContext context) async {
    try {
      final res = await _apiService.post(
        '/requests/overtime/$id/review/',
        body: {'status': approve ? 'approved' : 'rejected'},
      );
      if (res is Map) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Overtime request has been ${approve ? "approved" : "rejected"}.',
        );
        await fetchIncoming();
      }
    } catch (e) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'Failed to review overtime request: $e',
      );
    }
  }

  Future<void> reviewPermission(int id, bool approve, BuildContext context) async {
    try {
      final res = await _apiService.post(
        '/requests/permissions/$id/review/',
        body: {'status': approve ? 'approved' : 'rejected'},
      );
      if (res is Map) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Permission request has been ${approve ? "approved" : "rejected"}.',
        );
        await fetchIncoming();
      }
    } catch (e) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'Failed to review permission request: $e',
      );
    }
  }
}

class UnifiedRequestModel {
  final int id;
  final String category; // 'Leave', 'Overtime', 'Permission', 'Suggestion'
  final String title;
  final String detail;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String dateText;
  final String reason;
  final Map<String, dynamic> rawData;

  const UnifiedRequestModel({
    required this.id,
    required this.category,
    required this.title,
    required this.detail,
    required this.status,
    required this.createdAt,
    required this.dateText,
    required this.reason,
    required this.rawData,
  });

  factory UnifiedRequestModel.fromLeave(Map<String, dynamic> json) {
    final sess = json['session'] as num? ?? 1;
    final mode = json['leave_mode']?.toString() ?? 'full_section';
    final earlyTime = json['early_leave_time']?.toString() ?? '';
    final dateStr = json['from_date']?.toString() ?? '';
    String detailStr = dateStr;
    if (sess == 1) {
      detailStr = mode == 'early_leave' && earlyTime.isNotEmpty
          ? 'Section 1 • Early at $earlyTime'
          : 'Section 1 (Morning)';
    } else if (sess == 2) {
      detailStr = mode == 'early_leave' && earlyTime.isNotEmpty
          ? 'Section 2 • Early at $earlyTime'
          : 'Section 2 (Afternoon)';
    } else if (sess == 0) {
      detailStr = 'Full Day';
    }

    DateTime dt;
    try {
      dt = DateTime.parse(json['created_at']?.toString() ?? json['from_date']?.toString() ?? '');
    } catch (_) {
      dt = DateTime.now();
    }

    return UnifiedRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      category: 'Leave',
      title: (json['day_type'] ?? json['leave_type'] ?? 'Leave Request').toString(),
      detail: '$detailStr • $dateStr',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      createdAt: dt,
      dateText: dateStr,
      reason: json['reason']?.toString() ?? '',
      rawData: json,
    );
  }

  factory UnifiedRequestModel.fromOvertime(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString() ?? '';
    final startStr = json['start_time']?.toString() ?? '';
    final endStr = json['end_time']?.toString() ?? '';
    final totalH = json['total_hours']?.toString() ?? '';

    DateTime dt;
    try {
      dt = DateTime.parse(json['created_at']?.toString() ?? dateStr);
    } catch (_) {
      dt = DateTime.now();
    }

    return UnifiedRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      category: 'Overtime',
      title: 'Overtime Request',
      detail: '$dateStr ($startStr - $endStr)${totalH.isNotEmpty ? " • ${totalH}h" : ""}',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      createdAt: dt,
      dateText: dateStr,
      reason: json['reason']?.toString() ?? '',
      rawData: json,
    );
  }

  factory UnifiedRequestModel.fromPermission(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString() ?? '';
    final schedTime = json['schedule_time']?.toString() ?? '';
    final titleStr = json['title']?.toString() ?? json['category']?.toString() ?? 'Permission';

    DateTime dt;
    try {
      dt = DateTime.parse(json['created_at']?.toString() ?? dateStr);
    } catch (_) {
      dt = DateTime.now();
    }

    return UnifiedRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      category: 'Permission',
      title: titleStr,
      detail: '$dateStr • $schedTime',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      createdAt: dt,
      dateText: dateStr,
      reason: json['reason']?.toString() ?? '',
      rawData: json,
    );
  }

  factory UnifiedRequestModel.fromSuggestion(Map<String, dynamic> json) {
    final titleStr = json['title']?.toString() ?? 'Suggestion';
    final topic = json['topic']?.toString() ?? '';
    final dateStr = json['created_at']?.toString() ?? '';

    DateTime dt;
    try {
      dt = DateTime.parse(dateStr);
    } catch (_) {
      dt = DateTime.now();
    }

    return UnifiedRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      category: 'Suggestion',
      title: titleStr,
      detail: topic.isNotEmpty ? topic : (json['description']?.toString() ?? ''),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      createdAt: dt,
      dateText: dateStr.contains('T') ? dateStr.split('T').first : dateStr,
      reason: json['description']?.toString() ?? '',
      rawData: json,
    );
  }
}
