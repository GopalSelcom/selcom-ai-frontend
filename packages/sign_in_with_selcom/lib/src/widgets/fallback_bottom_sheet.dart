import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/auth_config.dart';
import '../models/auth_theme.dart';
import '../services/auth_service.dart';

/// An elegant, visually polished bottom sheet shown to the user when
/// the Selcom ID main app is not installed on the device.
///
/// Features customizable text parameters, standard action hooks, and an
/// custom-painted security lock-shield vector.
class SelcomFallbackBottomSheet extends StatelessWidget {
  /// The auth configurations containing store redirect paths.
  final SelcomAuthConfig config;

  /// Custom styling parameters for the UI.
  final SelcomAuthTheme theme;

  /// Header title of the bottom sheet.
  final String titleText;

  /// Detailed instructions explaining why the app is needed.
  final String descriptionText;

  /// Label of the store redirect button.
  final String primaryButtonText;

  /// Label of the cancellation button.
  final String secondaryButtonText;

  const SelcomFallbackBottomSheet({
    super.key,
    required this.config,
    required this.theme,
    this.titleText = 'Get Selcom ID',
    this.descriptionText =
        'To continue with single sign-on authentication, you need the Selcom ID app installed on your device. It takes less than a minute to set up.',
    this.primaryButtonText = 'Install Selcom ID',
    this.secondaryButtonText = 'Cancel',
  });

  /// Static helper to display the sheet in a standardized bottom sheet frame.
  static Future<bool?> show({
    required BuildContext context,
    required SelcomAuthConfig config,
    required SelcomAuthTheme theme,
    String? titleText,
    String? descriptionText,
    String? primaryButtonText,
    String? secondaryButtonText,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelcomFallbackBottomSheet(
        config: config,
        theme: theme,
        titleText: titleText ?? 'Get Selcom ID',
        descriptionText: descriptionText ??
            'To continue with single sign-on authentication, you need the Selcom ID app installed on your device. It takes less than a minute to set up.',
        primaryButtonText: primaryButtonText ?? 'Install Selcom ID',
        secondaryButtonText: secondaryButtonText ?? 'Cancel',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Container(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 8.0,
        bottom: 24.0 + mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.sheetBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.sheetBorderRadius),
          topRight: Radius.circular(theme.sheetBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20.0,
            spreadRadius: 5.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48.0,
              height: 5.0,
              margin: const EdgeInsets.only(bottom: 28.0),
              decoration: BoxDecoration(
                color: (theme.sheetBackgroundColor.computeLuminance() > 0.5)
                    ? Colors.black.withOpacity(0.08)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Elegant Painted Vector Graphic
          Center(
            child: Container(
              width: 100.0,
              height: 100.0,
              margin: const EdgeInsets.only(bottom: 24.0),
              child: CustomPaint(
                painter: ShieldLockPainter(
                  gradientColors: theme.illustrationGradient,
                  isDarkBackground: theme.sheetBackgroundColor.computeLuminance() < 0.5,
                ),
              ),
            ),
          ),

          // Title
          Text(
            titleText,
            style: theme.sheetTitleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),

          // Description
          Text(
            descriptionText,
            style: theme.sheetDescriptionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),

          // Primary Store Button
          ElevatedButton(
            onPressed: () async {
              final success = await SelcomAuthService.instance.openAppStore(
                config,
                isAndroid: isAndroid,
              );
              if (context.mounted) {
                Navigator.of(context).pop(success);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.sheetPrimaryButtonColor,
              foregroundColor: theme.sheetPrimaryButtonTextColor,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 0,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.white.withOpacity(0.08);
                  }
                  return null;
                },
              ),
            ),
            child: Text(
              primaryButtonText,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Secondary Close Button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            style: TextButton.styleFrom(
              backgroundColor: theme.sheetSecondaryButtonColor,
              foregroundColor: theme.sheetSecondaryButtonTextColor,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            child: Text(
              secondaryButtonText,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a sleek, modern security shield with a locking arc.
class ShieldLockPainter extends CustomPainter {
  final List<Color> gradientColors;
  final bool isDarkBackground;

  ShieldLockPainter({
    required this.gradientColors,
    required this.isDarkBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2);

    // 1. Draw glowing background circle
    final glowPaint = Paint()
      ..color = (gradientColors.isNotEmpty ? gradientColors.first : Colors.blue).withOpacity(isDarkBackground ? 0.08 : 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width * 0.48, glowPaint);

    final innerGlowPaint = Paint()
      ..color = (gradientColors.isNotEmpty ? gradientColors.first : Colors.blue).withOpacity(isDarkBackground ? 0.12 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width * 0.38, innerGlowPaint);

    // 2. Draw lock shackle (arc on top)
    final shacklePaint = Paint()
      ..color = isDarkBackground ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final shacklePath = Path()
      ..moveTo(width * 0.38, height * 0.44)
      ..quadraticBezierTo(
        width * 0.38,
        height * 0.22,
        width * 0.50,
        height * 0.22,
      )
      ..quadraticBezierTo(
        width * 0.62,
        height * 0.22,
        width * 0.62,
        height * 0.44,
      );
    canvas.drawPath(shacklePath, shacklePaint);

    // 3. Draw Shield
    final shieldPaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors.length >= 2 ? gradientColors : [Colors.blue, Colors.indigo],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(width * 0.25, height * 0.32, width * 0.5, height * 0.48))
      ..style = PaintingStyle.fill;

    final shieldPath = Path()
      ..moveTo(width * 0.50, height * 0.32) // Top center
      ..lineTo(width * 0.75, height * 0.37) // Top right
      ..quadraticBezierTo(
        width * 0.75,
        height * 0.62,
        width * 0.50,
        height * 0.80,
      ) // Bottom center curve
      ..quadraticBezierTo(
        width * 0.25,
        height * 0.62,
        width * 0.25,
        height * 0.37,
      ) // Bottom left curve to top left
      ..close();
    canvas.drawPath(shieldPath, shieldPaint);

    // 4. Draw Checkmark inside the shield
    final checkmarkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkmarkPath = Path()
      ..moveTo(width * 0.42, height * 0.54)
      ..lineTo(width * 0.48, height * 0.60)
      ..lineTo(width * 0.59, height * 0.49);
    canvas.drawPath(checkmarkPath, checkmarkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
