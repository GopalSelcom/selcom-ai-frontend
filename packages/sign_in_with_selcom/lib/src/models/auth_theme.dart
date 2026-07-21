import 'package:flutter/material.dart';

/// Styling configuration for Selcom ID Auth button and fallback dialog/bottom sheet.
///
/// Implements beautiful gradients, custom typography, and micro-animation durations.
class SelcomAuthTheme {
  // --- Button Style Properties ---
  /// Background gradient of the button. If specified, overrides [buttonColor].
  final Gradient? buttonGradient;

  /// Background solid color of the button if [buttonGradient] is null.
  final Color buttonColor;

  /// Color of the text and standard logo on the button.
  final Color buttonTextColor;

  /// Color of the ripple/splash effect on the button.
  final Color buttonRippleColor;

  /// Text style of the button. Overrides [buttonTextColor] if specified.
  final TextStyle? buttonTextStyle;

  /// Border radius of the button.
  final double buttonBorderRadius;

  /// Border side details of the button (optional).
  final BorderSide? buttonBorder;

  /// Padding inside the button.
  final EdgeInsets buttonPadding;

  /// Hover/tap scale factor of the button.
  /// Defaults to `0.96` (shrinks slightly when tapped).
  final double buttonScaleFactor;

  /// Scale animation duration.
  final Duration scaleDuration;

  // --- Bottom Sheet Style Properties ---
  /// Background color of the fallback bottom sheet.
  final Color sheetBackgroundColor;

  /// Text style for the fallback bottom sheet's title.
  final TextStyle sheetTitleStyle;

  /// Text style for the fallback bottom sheet's description body.
  final TextStyle sheetDescriptionStyle;

  /// Background color for the primary store action button.
  final Color sheetPrimaryButtonColor;

  /// Text color for the primary store action button.
  final Color sheetPrimaryButtonTextColor;

  /// Background color for the secondary close action button.
  final Color sheetSecondaryButtonColor;

  /// Text color for the secondary close action button.
  final Color sheetSecondaryButtonTextColor;

  /// Border radius of the bottom sheet itself.
  final double sheetBorderRadius;

  /// Gradient accents for the custom illustration in the bottom sheet.
  final List<Color> illustrationGradient;

  const SelcomAuthTheme({
    this.buttonGradient,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.buttonRippleColor,
    this.buttonTextStyle,
    required this.buttonBorderRadius,
    this.buttonBorder,
    required this.buttonPadding,
    required this.buttonScaleFactor,
    required this.scaleDuration,
    required this.sheetBackgroundColor,
    required this.sheetTitleStyle,
    required this.sheetDescriptionStyle,
    required this.sheetPrimaryButtonColor,
    required this.sheetPrimaryButtonTextColor,
    required this.sheetSecondaryButtonColor,
    required this.sheetSecondaryButtonTextColor,
    required this.sheetBorderRadius,
    required this.illustrationGradient,
  });

  /// The default sleek, premium modern dark-blue brand theme for Selcom ID.
  factory SelcomAuthTheme.defaultTheme(BuildContext context) {
    final theme = Theme.of(context);
    return SelcomAuthTheme(
      buttonGradient: const LinearGradient(
        colors: [
          Color(0xFF0F172A), // Slate 900
          Color(0xFF1E293B), // Slate 800
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      buttonColor: const Color(0xFF0F172A),
      buttonTextColor: Colors.white,
      buttonRippleColor: Colors.white.withOpacity(0.12),
      buttonBorderRadius: 16.0,
      buttonPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      buttonScaleFactor: 0.96,
      scaleDuration: const Duration(milliseconds: 100),
      sheetBackgroundColor: Colors.white,
      sheetTitleStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A), // Slate 900
      ),
      sheetDescriptionStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15.0,
        height: 1.5,
        color: Color(0xFF475569), // Slate 600
      ),
      sheetPrimaryButtonColor: const Color(0xFF2563EB), // Blue 600
      sheetPrimaryButtonTextColor: Colors.white,
      sheetSecondaryButtonColor: const Color(0xFFF1F5F9), // Slate 100
      sheetSecondaryButtonTextColor: const Color(0xFF475569), // Slate 600
      sheetBorderRadius: 28.0,
      illustrationGradient: const [
        Color(0xFF3B82F6), // Blue 500
        Color(0xFF1D4ED8), // Blue 700
      ],
    );
  }

  /// Modern dark theme configuration.
  factory SelcomAuthTheme.darkTheme(BuildContext context) {
    return SelcomAuthTheme(
      buttonGradient: const LinearGradient(
        colors: [
          Color(0xFF1E293B), // Slate 800
          Color(0xFF0F172A), // Slate 900
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      buttonColor: const Color(0xFF0F172A),
      buttonTextColor: Colors.white,
      buttonRippleColor: Colors.white.withOpacity(0.12),
      buttonBorderRadius: 16.0,
      buttonPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      buttonScaleFactor: 0.96,
      scaleDuration: const Duration(milliseconds: 100),
      sheetBackgroundColor: const Color(0xFF0F172A), // Dark slate
      sheetTitleStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      sheetDescriptionStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15.0,
        height: 1.5,
        color: Color(0xFF94A3B8), // Slate 400
      ),
      sheetPrimaryButtonColor: const Color(0xFF3B82F6), // Blue 500
      sheetPrimaryButtonTextColor: Colors.white,
      sheetSecondaryButtonColor: const Color(0xFF1E293B), // Slate 800
      sheetSecondaryButtonTextColor: const Color(0xFF94A3B8), // Slate 400
      sheetBorderRadius: 28.0,
      illustrationGradient: const [
        Color(0xFF60A5FA), // Blue 400
        Color(0xFF2563EB), // Blue 600
      ],
    );
  }

  /// Creates a copy of this theme but with the given fields replaced.
  SelcomAuthTheme copyWith({
    Gradient? buttonGradient,
    Color? buttonColor,
    Color? buttonTextColor,
    Color? buttonRippleColor,
    TextStyle? buttonTextStyle,
    double? buttonBorderRadius,
    BorderSide? buttonBorder,
    EdgeInsets? buttonPadding,
    double? buttonScaleFactor,
    Duration? scaleDuration,
    Color? sheetBackgroundColor,
    TextStyle? sheetTitleStyle,
    TextStyle? sheetDescriptionStyle,
    Color? sheetPrimaryButtonColor,
    Color? sheetPrimaryButtonTextColor,
    Color? sheetSecondaryButtonColor,
    Color? sheetSecondaryButtonTextColor,
    double? sheetBorderRadius,
    List<Color>? illustrationGradient,
  }) {
    return SelcomAuthTheme(
      buttonGradient: buttonGradient ?? this.buttonGradient,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      buttonRippleColor: buttonRippleColor ?? this.buttonRippleColor,
      buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonBorder: buttonBorder ?? this.buttonBorder,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonScaleFactor: buttonScaleFactor ?? this.buttonScaleFactor,
      scaleDuration: scaleDuration ?? this.scaleDuration,
      sheetBackgroundColor: sheetBackgroundColor ?? this.sheetBackgroundColor,
      sheetTitleStyle: sheetTitleStyle ?? this.sheetTitleStyle,
      sheetDescriptionStyle: sheetDescriptionStyle ?? this.sheetDescriptionStyle,
      sheetPrimaryButtonColor: sheetPrimaryButtonColor ?? this.sheetPrimaryButtonColor,
      sheetPrimaryButtonTextColor: sheetPrimaryButtonTextColor ?? this.sheetPrimaryButtonTextColor,
      sheetSecondaryButtonColor: sheetSecondaryButtonColor ?? this.sheetSecondaryButtonColor,
      sheetSecondaryButtonTextColor: sheetSecondaryButtonTextColor ?? this.sheetSecondaryButtonTextColor,
      sheetBorderRadius: sheetBorderRadius ?? this.sheetBorderRadius,
      illustrationGradient: illustrationGradient ?? this.illustrationGradient,
    );
  }
}
