import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/controller/suggestion_controller.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/model/suggestion.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/widgets/suggestion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Opened by tapping a row in "Suggestion Status".
/// Get.arguments = the suggestion id (String).
///
///  - Pending -> shows the message + "Delete" / "Edit"
///  - Seen    -> shows the message only (it can no longer be changed)
class SuggestionDetailScreen extends StatefulWidget {
  const SuggestionDetailScreen({super.key});

  @override
  State<SuggestionDetailScreen> createState() => _SuggestionDetailScreenState();
}

class _SuggestionDetailScreenState extends State<SuggestionDetailScreen> {
  final SuggestionController _controller = Get.find<SuggestionController>();
  final TextEditingController _messageController = TextEditingController();
  late final String _id = Get.arguments as String;

  bool _editing = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _startEdit(Suggestion suggestion) {
    _messageController.text = suggestion.message;
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    _messageController.clear();
    setState(() => _editing = false);
  }

  void _saveEdit() {
    final messenger = ScaffoldMessenger.of(context);
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      RequestSnack.show(messenger, 'Write your suggestion first.');
      return;
    }

    final updated = _controller.updateMessage(_id, message);
    _messageController.clear();
    setState(() => _editing = false);
    RequestSnack.show(
      messenger,
      updated
          ? 'Your suggestion was updated.'
          : 'This suggestion was already seen, so it cannot be edited.',
    );
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmDeleteSuggestion(context)) return;

    final deleted = _controller.delete(_id);
    if (deleted) Get.back();
    RequestSnack.show(
      messenger,
      deleted
          ? 'Suggestion deleted.'
          : 'This suggestion was already seen, so it cannot be deleted.',
    );
  }

  // TODO: replace with the real admin/manager review flow.
  Future<void> _confirmMarkSeen() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as seen?'.tr),
        content: Text(
          'The employee will no longer be able to edit this suggestion.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Mark as seen'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _controller.markSeen(_id);
      RequestSnack.show(messenger, 'Suggestion marked as seen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Suggestion Detail',
      body: Obx(() {
        final suggestion = _controller.findById(_id);

        // Deleted: the page is closing, draw nothing for that moment.
        if (suggestion == null) return const SizedBox.shrink();

        // It turned "Seen" while the employee was typing: drop back to read-only.
        final editing = _editing && suggestion.isPending;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(suggestion),
              const SizedBox(height: 16),
              const RequestLabel('Your Message'),
              Expanded(
                child: editing
                    ? _buildEditor()
                    : _buildMessage(suggestion.message),
              ),
              const SizedBox(height: 16),
              ..._buildActions(suggestion, editing),
            ],
          ),
        );
      }),
    );
  }

  /// Same look as a row in the status list: date, time, badge.
  Widget _buildHeader(Suggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.dateLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: RequestColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SuggestionStatusBadge(status: suggestion.status),
        ],
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, color: RequestColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return TextField(
      controller: _messageController,
      autofocus: true,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontSize: 14, color: RequestColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Your Message'.tr,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: RequestColors.textSecondary,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  List<Widget> _buildActions(Suggestion suggestion, bool editing) {
    if (editing) {
      return [
        RequestButton(label: 'Update', onPressed: _saveEdit),
        const SizedBox(height: 10),
        RequestButton(label: 'Cancel', filled: false, onPressed: _cancelEdit),
      ];
    }

    // Seen: read-only, no actions for the employee.
    if (suggestion.isSeen) return const [];

    return [
      Row(
        children: [
          Expanded(
            child: RequestButton(
              label: 'Delete',
              color: const Color(0xFFD9531E),
              onPressed: _delete,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RequestButton(
              label: 'Edit',
              onPressed: () => _startEdit(suggestion),
            ),
          ),
        ],
      ),
      if (_controller.canReview) ...[
        const SizedBox(height: 10),
        RequestButton(
          label: 'Mark as seen',
          filled: false,
          onPressed: _confirmMarkSeen,
        ),
      ],
    ];
  }
}
