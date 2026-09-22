import 'dart:convert';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? profileUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final List<Color>? gradientColors;
  final Border? border;
  final TextStyle? textStyle;

  const AppAvatar({
    super.key,
    this.profileUrl,
    required this.name,
    this.size = 50,
    this.backgroundColor,
    this.textColor,
    this.gradientColors,
    this.border,
    this.textStyle,
  });

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (profileUrl != null && profileUrl!.isNotEmpty) {
      if (profileUrl!.startsWith('data:image')) {
        try {
          final base64Data = profileUrl!.split(',').last;
          final bytes = base64Decode(base64Data);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: border,
            ),
            child: ClipOval(
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              ),
            ),
          );
        } catch (_) {}
      } else if (profileUrl!.startsWith('http')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
          ),
          child: ClipOval(
            child: Image.network(
              profileUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            ),
          ),
        );
      }
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: gradientColors == null
          ? (backgroundColor ?? RequestColors.primary.withValues(alpha: 0.10))
          : null,
      gradient: gradientColors != null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors!,
            )
          : null,
      border: border,
    );

    final fontColor = textColor ??
        (gradientColors != null ? Colors.white : RequestColors.primary);

    final style = textStyle ??
        TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: fontColor,
        );

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Text(
        initials(name),
        style: style,
      ),
    );
  }
}
