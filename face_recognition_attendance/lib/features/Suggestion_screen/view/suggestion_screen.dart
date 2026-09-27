import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/controller/suggestion_controller.dart';
import 'package:face_recognition_attendance/features/Suggestion_screen/model/suggestion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Suggestion Box":
/// - Tab 0: Submit Feedback (no categories, no anonymous toggle card, simple text with "Your identity will not be attached.")
/// - Tab 1: History & Status (inline on same screen with All / Pending / Seen filters)
class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final SuggestionController _controller = Get.find<SuggestionController>();
  final TextEditingController _messageController = TextEditingController();
  int _tabIndex = 0;
  int _historyFilter = 0; // 0: All, 1: Pending, 2: Seen

  @override
  void initState() {
    super.initState();
    _controller.fetchSuggestions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      RequestSnack.show(messenger, 'Please input your suggestion.');
      return;
    }

    final success = await _controller.submit(message);
    if (success) {
      _messageController.clear();
      setState(() {
        _tabIndex = 1;
      });
      RequestSnack.show(messenger, 'Your suggestion was submitted.');
    } else {
      RequestSnack.show(
        messenger,
        'Failed to submit suggestion. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Suggestion Box',
      backLabel: 'Requests',
      actions: const [],
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AppleSegmentedControl(
              tabs: const ['Submit Feedback', 'History & Status'],
              selectedIndex: _tabIndex,
              onChanged: (i) {
                setState(() => _tabIndex = i);
                if (i == 1) {
                  _controller.fetchSuggestions();
                }
              },
            ),
          ),

          Expanded(
            child: _tabIndex == 0
                ? _buildSubmitForm()
                : _buildHistoryAndStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitForm() {
    return SingleChildScrollView(
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
            style: TextStyle(fontSize: 14, color: RequestColors.textSecondary),
          ),

          const SizedBox(height: 24),

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
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_messageController.text.length} / 500',
              style: const TextStyle(
                fontSize: 12,
                color: RequestColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          RequestButton(
            label: 'Submit Feedback',
            icon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              'Your identity will not be attached.',
              style: TextStyle(
                fontSize: 13,
                color: RequestColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHistoryAndStatus() {
    return Obx(() {
      final all = _controller.suggestions;
      final items = _historyFilter == 1
          ? all.where((s) => s.isPending).toList()
          : (_historyFilter == 2 ? all.where((s) => s.isSeen).toList() : all);

      return Column(
        children: [
          // Filter Chips (All, Pending, Seen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _buildFilterChip('All', 0, all.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Pending',
                  1,
                  all.where((s) => s.isPending).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Seen', 2, all.where((s) => s.isSeen).length),
              ],
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 48,
                          color: RequestColors.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No suggestions yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: RequestColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _SuggestionCard(
                        suggestion: item,
                        onTap: () => Get.toNamed(
                          AppRoutes.suggestionDetail,
                          arguments: item.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _historyFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _historyFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? RequestColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? RequestColors.primary : const Color(0xFFE5E5EA),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : RequestColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onTap});

  final Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPending = suggestion.isPending;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${suggestion.dateLabel} • ${suggestion.timeLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? RequestColors.pendingBackground
                          : RequestColors.approvedBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPending ? 'Pending' : 'Seen',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPending
                            ? RequestColors.pendingText
                            : RequestColors.approvedText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                suggestion.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: RequestColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
