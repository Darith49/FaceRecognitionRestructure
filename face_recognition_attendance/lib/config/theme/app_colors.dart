import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============== APPLE DESIGN SYSTEM – BRAND COLORS ==============
  static const Color primary = Color(0xFF0066CC);       // Apple Action Blue
  static const Color primaryFocus = Color(0xFF0071E3);  // Hover / Focus Blue
  static const Color primaryOnDark = Color(0xFF2997FF); // Blue on dark surfaces
  static const Color secondary = Color(0xFF5F5E60);     // Neutral secondary

  // ============== SEMANTIC COLORS ==============
  static const Color success = Color(0xFF34C759);       // Apple Green
  static const Color warning = Color(0xFFFF9500);       // Apple Amber / Orange
  static const Color error = Color(0xFFFF3B30);         // Apple Red
  static const Color info = Color(0xFF8E8E93);          // Apple Gray

  // ============== INK / TEXT ==============
  static const Color ink = Color(0xFF1D1D1F);           // Primary text
  static const Color inkMuted80 = Color(0xFF333333);    // Secondary text darker
  static const Color inkMuted48 = Color(0xFF7A7A7A);    // Muted / tertiary text

  // ============== LIGHT THEME ==============
  static const Color lightBackground = Color(0xFFF5F5F7);   // Canvas parchment
  static const Color lightSurface = Color(0xFFFFFFFF);       // White surface
  static const Color lightText = Color(0xFF1D1D1F);          // Ink
  static const Color lightTextSecondary = Color(0xFF6B7280); // Muted gray
  static const Color lightBorder = Color(0xFFE0E0E0);       // Hairline
  static const Color lightDivider = Color(0xFFF0F0F0);      // Divider soft

  // ============== APPLE SURFACE COLORS ==============
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasParchment = Color(0xFFF5F5F7);
  static const Color surfacePearl = Color(0xFFFAFAFC);
  static const Color hairline = Color(0xFFE0E0E0);
  static const Color dividerSoft = Color(0xFFF0F0F0);

  // ============== DARK THEME ==============
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF475569);
}
