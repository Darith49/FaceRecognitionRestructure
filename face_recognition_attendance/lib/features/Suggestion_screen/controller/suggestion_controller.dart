import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/model/suggestion.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class SuggestionController extends GetxController {
  final ApiService _apiService = ApiService();
  final RxList<Suggestion> suggestions = <Suggestion>[].obs;
  final RxBool isLoading = false.obs;

  String? _ownerUid;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
    fetchSuggestions();
  }

  UserModel? get _signedInUser => Get.isRegistered<LoginController>()
      ? Get.find<LoginController>().currentuser.value
      : null;

  void _watchSignedInUser() {
    if (!Get.isRegistered<LoginController>()) return;

    final auth = Get.find<LoginController>();
    _ownerUid = auth.currentuser.value?.uid;

    ever(auth.currentuser, (UserModel? user) {
      if (user?.uid == _ownerUid) return;
      _ownerUid = user?.uid;
      suggestions.clear();
      fetchSuggestions();
    });
  }

  Future<void> fetchSuggestions() async {
    try {
      isLoading.value = true;
      final res = await _apiService.get('/requests/suggestions/');
      if (res is List) {
        final list = res
            .map((e) => Suggestion.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        suggestions.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool get canReview {
    final role = _signedInUser?.role;
    return role != null &&
        (role == UserRole.ceo || role == UserRole.manager);
  }

  Future<bool> submit(
    String message, {
    String subject = 'General Suggestion',
    bool isAnonymous = true,
  }) async {
    try {
      final body = {
        'subject': subject,
        'content': message,
        'is_anonymous': isAnonymous,
      };
      await _apiService.post('/requests/suggestions/', body: body);
      await fetchSuggestions();
      return true;
    } catch (e) {
      debugPrint('Error submitting suggestion: $e');
      return false;
    }
  }

  Suggestion? findById(String id) {
    final index = suggestions.indexWhere((s) => s.id == id);
    return index == -1 ? null : suggestions[index];
  }

  bool updateMessage(String id, String message) {
    final index = suggestions.indexWhere((s) => s.id == id);
    if (index == -1 || suggestions[index].isSeen) return false;
    suggestions[index] = suggestions[index].copyWith(message: message);
    return true;
  }

  bool delete(String id) {
    final before = suggestions.length;
    suggestions.removeWhere((s) => s.id == id && s.isPending);
    return suggestions.length < before;
  }

  Future<void> markSeen(String id) async {
    try {
      await _apiService.patch('/requests/suggestions/$id/read/');
      final index = suggestions.indexWhere((s) => s.id == id);
      if (index != -1) {
        suggestions[index] = suggestions[index].copyWith(
          status: SuggestionStatus.seen,
        );
      }
    } catch (e) {
      debugPrint('Error marking suggestion as seen: $e');
    }
  }
}
