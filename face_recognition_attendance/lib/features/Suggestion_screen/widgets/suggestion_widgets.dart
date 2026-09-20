import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/suggestion_screen/model/suggestion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pending (yellow) / Seen (green) badge, shared by every Suggestion page.
class SuggestionStatusBadge extends StatelessWidget {
  const SuggestionStatusBadge({super.key, required this.status});

  final SuggestionStatus status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == SuggestionStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPending
            ? RequestColors.pendingBackground
            : RequestColors.approvedBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPending ? RequestColors.pendingText : Colors.white,
        ),
      ),
    );
  }
}

/// "Delete suggestion?" dialog. Returns true only if the employee confirms.
Future<bool> confirmDeleteSuggestion(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete suggestion?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text(
            'Delete',
            style: TextStyle(color: RequestColors.danger),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
