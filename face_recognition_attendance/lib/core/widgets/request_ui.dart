import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Colors used by the Clock / Request / Permission screens (from the Figma design).
class RequestColors {
  RequestColors._();

  static const Color background = Color(0xFFDCDEEA);
  static const Color textPrimary = Color(0xFF1B2437);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color primary = Color(0xFF3B78F0);
  static const Color danger = Color(0xFFE82020);
  static const Color pendingBackground = Color(0xFFF6EBC8);
  static const Color pendingText = Color(0xFF9C7F0C);
  static const Color approvedBackground = Color(0xFF39F07C);
  static const Color approvedText = Color(0xFF0B3D1E);
  static const Color approvedStatus = Color(0xFF1B9A3A);
  static const Color gold = Color(0xFFD4A017);
  static const Color teal = Color(0xFF3E5C76);
}

/// Page frame used by every screen in this feature:
/// white app bar with a title + back arrow, and the light purple-grey body.
class RequestScaffold extends StatelessWidget {
  const RequestScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.centerTitle = false,
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final bool centerTitle;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RequestColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: centerTitle,
        automaticallyImplyLeading: false,
        titleSpacing: showBackButton ? 0.0 : 16.0,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: RequestColors.textPrimary,
                ),
                onPressed: () => Get.back(),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: RequestColors.textPrimary,
          ),
        ),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// A white rounded card with a colored icon on the left, a title, a subtitle
/// and an arrow on the right. Used for menus (Request Information, Permission...).
class RequestMenuCard extends StatelessWidget {
  const RequestMenuCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: RequestColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bold label shown above an input or a read-only field.
class RequestLabel extends StatelessWidget {
  const RequestLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: RequestColors.textPrimary,
        ),
      ),
    );
  }
}

/// Label + white read-only box (used on the request detail page).
class RequestField extends StatelessWidget {
  const RequestField({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = RequestColors.textPrimary,
    this.valueWeight = FontWeight.w500,
    this.multiline = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final FontWeight valueWeight;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequestLabel(label),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: multiline ? 110.0 : 48.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: valueWeight,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width button. `filled: true` = blue button, `filled: false` = white button.
class RequestButton extends StatelessWidget {
  const RequestButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  /// Overrides the background color (text becomes white). Used for
  /// non-standard buttons like the red "Delete" button on Suggestion.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        color ?? (filled ? RequestColors.primary : Colors.white);
    final foregroundColor = color != null
        ? Colors.white
        : (filled ? Colors.white : RequestColors.textPrimary);

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Small message at the bottom of the screen.
class RequestSnack {
  RequestSnack._();

  /// Get the messenger BEFORE any `await` or `Get.back()`:
  /// `RequestSnack.show(ScaffoldMessenger.of(context), 'Saved');`
  static void show(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: RequestColors.textPrimary,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
