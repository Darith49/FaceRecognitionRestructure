import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/controller/suggestion_controller.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/model/suggestion.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/widgets/suggestion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Suggestion Status": every suggestion the employee submitted, newest first,
/// with a Pending / Seen badge and a one-line preview of the message.
/// Tap a row to open it: Pending ones can be edited or deleted there.
class SuggestionStatusScreen extends GetView<SuggestionController> {
  const SuggestionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Suggestion Status',
      body: Obx(() {
        final items = controller.suggestions;

        if (items.isEmpty) {
          return Center(
            child: Text(
              'No suggestions yet'.tr,
              style: const TextStyle(
                fontSize: 13,
                color: RequestColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _SuggestionTile(
            suggestion: items[index],
            onTap: () => Get.toNamed(
              AppRoutes.suggestionDetail,
              arguments: items[index].id,
            ),
          ),
        );
      }),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 6),
                    Text(
                      suggestion.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SuggestionStatusBadge(status: suggestion.status),
            ],
          ),
        ),
      ),
    );
  }
}
