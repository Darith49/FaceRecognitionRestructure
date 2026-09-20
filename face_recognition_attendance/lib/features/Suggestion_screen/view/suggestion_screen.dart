import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/suggestion_screen/controller/suggestion_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Suggestion": always a blank form to write a new suggestion.
///
/// After "Submit" the employee goes to "Suggestion Status", where every
/// suggestion is listed. Tapping a Pending one there opens the Delete / Edit page.
class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final SuggestionController _controller = Get.find<SuggestionController>();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      RequestSnack.show(messenger, 'Write your suggestion first.');
      return;
    }

    _controller.submit(message);
    _messageController.clear();

    // Replace this page so "back" from the status list returns to the
    // Request menu, not to an empty form.
    Get.offNamed(AppRoutes.suggestionStatus);
    RequestSnack.show(messenger, 'Your suggestion was submitted.');
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Suggestion',
      actions: [
        IconButton(
          tooltip: 'Suggestion Status',
          icon: const Icon(
            Icons.history_rounded,
            color: RequestColors.textPrimary,
          ),
          onPressed: () => Get.toNamed(AppRoutes.suggestionStatus),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggestion',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Anything we can do better ?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Even the smallest suggestion can help us improve together',
              style: TextStyle(
                fontSize: 11,
                color: RequestColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _messageController,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 14,
                  color: RequestColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Your Message',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: RequestColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE9EAF0),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            RequestButton(label: 'Submit', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
