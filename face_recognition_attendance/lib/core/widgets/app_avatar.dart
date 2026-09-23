import 'dart:convert';
import 'dart:typed_data';
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

  /// In-memory cache for decoded base64 images to prevent repeated decoding on every frame/rebuild
  static final Map<int, Uint8List> _base64Cache = <int, Uint8List>{};

  /// Decodes base64 data URI or raw base64 string with memory caching
  static Uint8List? decodeBase64Cached(String dataUriOrBase64) {
    final trimmed = dataUriOrBase64.trim();
    if (trimmed.isEmpty) return null;

    // Filter out dummy/corrupted placeholder strings
    if (trimmed.contains('test_') || trimmed.contains('TEST_') || trimmed.length < 50) {
      return null;
    }

    final int hash = trimmed.hashCode;
    final cached = _base64Cache[hash];
    if (cached != null) return cached;

    try {
      final base64Data = trimmed.contains(',')
          ? trimmed.split(',').last.trim()
          : trimmed;
      final bytes = base64Decode(base64Data);
      if (bytes.length < 20) return null;

      if (_base64Cache.length > 100) {
        _base64Cache.remove(_base64Cache.keys.first);
      }
      _base64Cache[hash] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (profileUrl != null && profileUrl!.trim().isNotEmpty) {
      final url = profileUrl!.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
          ),
          child: ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            ),
          ),
        );
      } else {
        final bytes = decodeBase64Cached(url);
        if (bytes != null && bytes.isNotEmpty) {
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
        }
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
