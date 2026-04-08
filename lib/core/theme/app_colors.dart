import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary        = Color(0xFFF01C4B);  // Red — buttons, highlights
  static const Color primaryLight   = Color(0xFFFDE8ED);  // Light red bg

  // Backgrounds
  static const Color pageBackground = Color(0xFFF5F7FA);  // Screen backgrounds
  static const Color cardBackground = Color(0xFFFFFFFF);  // Cards, sheets, modals
  static const Color errorBackground= Color(0xFFFDECEA);  // OTP error banner

  // Text
  static const Color textDark       = Color(0xFF1A1A1A);  // Titles, labels
  static const Color textGrey       = Color(0xFF555555);  // Subtitles, hints
  static const Color textLight      = Color(0xFFAAAAAA);  // Placeholders, disabled

  // Semantic
  static const Color success        = Color(0xFF1D9E75);  // Green
  static const Color error          = Color(0xFFE24B4A);  // Red error
  static const Color warning        = Color(0xFFEF9F27);  // Orange/amber
  static const Color info           = Color(0xFF378ADD);  // Blue

  // Input
  static const Color inputBorderActive   = Color(0xFF378ADD);  // Blue on focus
  static const Color inputBorderDefault  = Color(0xFFDDDDDD);
  static const Color inputBorderError    = Color(0xFFE24B4A);

  // Dividers
  static const Color divider        = Color(0xFFEEEEEE);
  static const Color shadow         = Color(0x1A000000);  // 10% black
}
