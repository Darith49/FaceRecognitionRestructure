import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/controller/suggestion_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Suggestion Box": form with category chips, text area, anonymous toggle.
class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final SuggestionController _controller = Get.find<SuggestionController>();
  final TextEditingController _messageController = TextEditingController();
  int _selectedCategory = 0;
  bool _anonymous = false;
  int _tabIndex = 0;

  static const _categories = [
    'Workplace & Equipment',
    'Shift Schedule',
    'Team Culture',
    'Other',
  ];

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

    Get.offNamed(AppRoutes.suggestionStatus);
    RequestSnack.show(messenger, 'Your suggestion was submitted.');
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Suggestion Box',
      backLabel: 'Requests',
      actions: [
        IconButton(
          tooltip: 'Suggestion Status',
          icon: const Icon(
            Icons.history_rounded,
            color: RequestColors.textSecondary,
          ),
          onPressed: () => Get.toNamed(AppRoutes.suggestionStatus),
        ),
      ],
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: AppleSegmentedControl(
              tabs: const ['Submit Feedback', 'History & Status'],
              selectedIndex: _tabIndex,
              onChanged: (i) {
                if (i == 1) {
                  Get.toNamed(AppRoutes.suggestionStatus);
                } else {
                  setState(() => _tabIndex = i);
                }
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anything we can do better?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Even the smallest suggestion can help us improve together',
                    style: TextStyle(
                      fontSize: 14,
                      color: RequestColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category section
                  const Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_categories.length, (i) {
                      final selected = i == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? RequestColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: selected
                                ? null
                                : Border.all(color: const Color(0xFFE5E5EA)),
                          ),
                          child: Text(
                            _categories[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : RequestColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Your Suggestion
                  const Text(
                    'YOUR SUGGESTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: appleCardDecoration(radius: 14),
                    child: TextField(
                      controller: _messageController,
                      minLines: 6,
                      maxLines: 8,
                      maxLength: 500,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 15,
                        color: RequestColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts, suggestions, or concerns...',
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          color: RequestColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Constructive feedback is shared directly with ops',
                        style: TextStyle(
                          fontSize: 12,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_messageController.text.length} / 500',
                        style: const TextStyle(
                          fontSize: 12,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Anonymous toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: appleCardDecoration(radius: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Submit anonymously',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: RequestColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Your identity will not be attached',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: RequestColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _anonymous,
                          onChanged: (v) => setState(() => _anonymous = v),
                          activeTrackColor: RequestColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  RequestButton(
                    label: 'Submit Feedback',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _submit,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
