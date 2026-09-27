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
  String _id = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is String) {
      _id = args;
    } else if (args is num) {
      _id = args.toString();
    } else if (args is Map && args['id'] != null) {
      _id = args['id'].toString();
    }
    if (_controller.findById(_id) == null) {
      _controller.fetchSuggestions();
    }
  }

  // Admin/manager review flow: mark suggestion as seen
  Future<void> _confirmMarkSeen() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as seen?'),
        content: const Text(
          'Mark this suggestion as reviewed and seen by management.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Mark as seen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.markSeen(_id);
      RequestSnack.show(messenger, 'Suggestion marked as seen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Suggestion Detail',
      body: Obx(() {
        final suggestion = _controller.findById(_id);

        if (suggestion == null) {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Center(
            child: Text(
              'This suggestion could not be found.',
              style: TextStyle(color: RequestColors.textSecondary),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(suggestion),
              const SizedBox(height: 16),
              const RequestLabel('Your Message'),
              Expanded(child: _buildMessage(suggestion.message)),
              const SizedBox(height: 16),
              ..._buildActions(suggestion),
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
          style: const TextStyle(
            fontSize: 14,
            color: RequestColors.textPrimary,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(Suggestion suggestion) {
    if (suggestion.isPending && _controller.canReview) {
      return [
        RequestButton(label: 'Mark as seen', onPressed: _confirmMarkSeen),
      ];
    }
    return const [];
  }
}
