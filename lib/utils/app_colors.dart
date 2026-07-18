import 'package:flutter/material.dart';

extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get scaffoldBg =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);
  Color get cardBg =>
      isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get surfaceMuted =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

  // Text
  Color get textPrimary =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // Borders / dividers
  Color get borderSubtle =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get borderMedium =>
      isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
}
