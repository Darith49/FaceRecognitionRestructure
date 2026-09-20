import 'package:face_recognition_attendance/features/Suggestion_screen/model/suggestion.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:get/get.dart';

/// Keeps the suggestions for the Suggestion feature.
/// For now the data lives in memory only (it is lost when the app closes).
class SuggestionController extends GetxController {
  /// Newest first. Shown on the "Suggestion Status" page.
  final RxList<Suggestion> suggestions = <Suggestion>[].obs;

  String? _ownerUid;
  int _idCounter = 0;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
  }

  UserModel? get _signedInUser => Get.isRegistered<LoginController>()
      ? Get.find<LoginController>().currentuser.value
      : null;

  /// If another user logs in on the same phone, do not show the old user's suggestions.
  void _watchSignedInUser() {
    if (!Get.isRegistered<LoginController>()) return;

    final auth = Get.find<LoginController>();
    _ownerUid = auth.currentuser.value?.uid;

    ever(auth.currentuser, (UserModel? user) {
      if (user?.uid == _ownerUid) return;
      _ownerUid = user?.uid;
      suggestions.clear();
    });
  }

  /// TODO: replace with a real permission check once the admin review flow
  /// exists. For now, anyone who is not a plain employee can mark a
  /// suggestion as "Seen" from the Suggestion Status list.
  bool get canReview {
    final role = _signedInUser?.role;
    return role != null && role != UserRole.employee;
  }

  void submit(String message) {
    final user = _signedInUser;
    _idCounter++;

    suggestions.insert(
      0,
      Suggestion(
        id: '${DateTime.now().microsecondsSinceEpoch}-$_idCounter',
        fullName: user?.fullname ?? 'Unknown',
        employeeId: user?.employeeId ?? '-',
        message: message,
        submittedAt: DateTime.now(),
        status: SuggestionStatus.pending,
      ),
    );
  }

  Suggestion? findById(String id) {
    final index = suggestions.indexWhere((s) => s.id == id);
    return index == -1 ? null : suggestions[index];
  }

  /// Only allowed while the suggestion is still Pending.
  /// Returns false if it was not changed (missing, or already Seen).
  bool updateMessage(String id, String message) {
    final index = suggestions.indexWhere((s) => s.id == id);
    if (index == -1 || suggestions[index].isSeen) return false;
    suggestions[index] = suggestions[index].copyWith(message: message);
    return true;
  }

  /// Only allowed while the suggestion is still Pending.
  /// Returns false if nothing was deleted (missing, or already Seen).
  bool delete(String id) {
    final before = suggestions.length;
    suggestions.removeWhere((s) => s.id == id && s.isPending);
    return suggestions.length < before;
  }

  /// Marks a suggestion as reviewed. Once Seen, it can no longer be edited or deleted.
  void markSeen(String id) {
    final index = suggestions.indexWhere((s) => s.id == id);
    if (index == -1) return;
    suggestions[index] = suggestions[index].copyWith(
      status: SuggestionStatus.seen,
    );
  }
}
