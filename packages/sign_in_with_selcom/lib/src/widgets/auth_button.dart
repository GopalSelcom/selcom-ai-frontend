import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/auth_theme.dart';
import '../services/auth_service.dart';
import 'fallback_bottom_sheet.dart';

/// A custom, highly elegant authentication button for initiating the
/// App-to-App SSO workflow with Selcom ID.
///
/// Implements tap micro-animations (scale transitions), a custom loading spinner,
/// and automated listener hook-ups.
class SelcomAuthButton extends StatefulWidget {
  /// The client ID provided by Selcom for authentication.
  final String clientId;

  /// The custom URL redirect scheme registered by the calling app (e.g., `zomato`).
  final String redirectScheme;

  /// Triggered upon successful authentication with the returned token.
  final ValueChanged<String> onSuccess;

  /// Triggered when authentication fails, supplying the error message.
  final ValueChanged<String> onError;

  /// Optional callback when the flow is explicitly cancelled by the user.
  final VoidCallback? onCancelled;

  /// Text displayed on the button.
  /// Defaults to `'Sign in with Selcom ID'`.
  final String buttonText;

  /// Custom styling configurations.
  /// Defaults to [SelcomAuthTheme.defaultTheme].
  final SelcomAuthTheme? theme;

  /// Additional parameters to pass during authorization.
  final Map<String, String>? additionalParams;

  /// Override scheme of the Selcom ID main app if required.
  final String? selcomAppScheme;

  /// Override Package Name for Play Store.
  final String? androidPackageName;

  /// Override App Store ID for App Store.
  final String? iosAppStoreId;

  // --- Bottom Sheet custom copy overrides ---
  /// Overrides the title in the fallback bottom sheet.
  final String? fallbackTitle;

  /// Overrides the body description in the fallback bottom sheet.
  final String? fallbackDescription;

  /// Overrides the primary button text in the fallback bottom sheet.
  final String? fallbackPrimaryButtonText;

  /// Overrides the secondary button text in the fallback bottom sheet.
  final String? fallbackSecondaryButtonText;

  const SelcomAuthButton({
    super.key,
    required this.clientId,
    required this.redirectScheme,
    required this.onSuccess,
    required this.onError,
    this.onCancelled,
    this.buttonText = 'Sign in with Selcom ID',
    this.theme,
    this.additionalParams,
    this.selcomAppScheme,
    this.androidPackageName,
    this.iosAppStoreId,
    this.fallbackTitle,
    this.fallbackDescription,
    this.fallbackPrimaryButtonText,
    this.fallbackSecondaryButtonText,
  });

  @override
  State<SelcomAuthButton> createState() => _SelcomAuthButtonState();
}

class _SelcomAuthButtonState extends State<SelcomAuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  StreamSubscription<SelcomAuthResult>? _authSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Setup scale controller for tactile tap feedback animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.theme?.buttonScaleFactor ?? 0.96,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut,
      ),
    );

    _initResultListener();
    _registerCurrentConfig();
  }

  @override
  void didUpdateWidget(covariant SelcomAuthButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clientId != oldWidget.clientId ||
        widget.redirectScheme != oldWidget.redirectScheme ||
        widget.selcomAppScheme != oldWidget.selcomAppScheme ||
        widget.androidPackageName != oldWidget.androidPackageName ||
        widget.iosAppStoreId != oldWidget.iosAppStoreId) {
      _registerCurrentConfig();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initResultListener() {
    _authSubscription?.cancel();
    _authSubscription = SelcomAuthService.instance.authResults.listen(
      _handleAuthResult,
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        widget.onError(err.toString());
      },
    );
  }

  void _registerCurrentConfig() {
    final config = _buildConfig();
    SelcomAuthService.instance.registerConfig(config);
  }

  SelcomAuthConfig _buildConfig() {
    return SelcomAuthConfig(
      clientId: widget.clientId,
      redirectScheme: widget.redirectScheme,
      additionalParams: widget.additionalParams,
      selcomAppScheme: widget.selcomAppScheme ?? 'selcomid',
      androidPackageName: widget.androidPackageName ?? 'com.selcom.id',
      iosAppStoreId: widget.iosAppStoreId ?? '1234567890',
    );
  }

  void _handleAuthResult(SelcomAuthResult result) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    switch (result.status) {
      case SelcomAuthStatus.success:
        widget.onSuccess(result.token!);
        break;
      case SelcomAuthStatus.failure:
        if (result.errorMessage == 'AppNotInstalled') {
          _showFallbackSheet(_buildConfig());
        } else {
          widget.onError(result.errorMessage!);
        }
        break;
      case SelcomAuthStatus.cancelled:
        widget.onCancelled?.call();
        break;
    }
  }

  /// Triggers the authorization flow.
  Future<void> _handleTap() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final config = _buildConfig();

    // Trigger the flow. The persistent listener in initState will handle the resulting
    // callback from the broadcast stream.
    SelcomAuthService.instance.startAuthFlow(config);
  }

  /// Displays the fallback dialog/bottom sheet.
  Future<void> _showFallbackSheet(SelcomAuthConfig config) async {
    final activeTheme = widget.theme ?? SelcomAuthTheme.defaultTheme(context);
    final userNavigatedToStore = await SelcomFallbackBottomSheet.show(
      context: context,
      config: config,
      theme: activeTheme,
      titleText: widget.fallbackTitle,
      descriptionText: widget.fallbackDescription,
      primaryButtonText: widget.fallbackPrimaryButtonText,
      secondaryButtonText: widget.fallbackSecondaryButtonText,
    );

    if (userNavigatedToStore == null || !userNavigatedToStore) {
      widget.onCancelled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = widget.theme ?? SelcomAuthTheme.defaultTheme(context);
    
    // Fallback static text style if custom buttonTextStyle is null
    final textStyle = activeTheme.buttonTextStyle ??
        TextStyle(
          fontFamily: 'Inter',
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: activeTheme.buttonTextColor,
        );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: activeTheme.buttonGradient,
          color: activeTheme.buttonGradient == null ? activeTheme.buttonColor : null,
          borderRadius: BorderRadius.circular(activeTheme.buttonBorderRadius),
          boxShadow: [
            BoxShadow(
              color: (activeTheme.buttonGradient != null
                      ? activeTheme.buttonGradient!.colors.first
                      : activeTheme.buttonColor)
                  .withOpacity(0.24),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _handleTap,
            onTapDown: (_) {
              if (!_isLoading) _scaleController.forward();
            },
            onTapUp: (_) {
              _scaleController.reverse();
            },
            onTapCancel: () {
              _scaleController.reverse();
            },
            borderRadius: BorderRadius.circular(activeTheme.buttonBorderRadius),
            splashColor: activeTheme.buttonRippleColor,
            highlightColor: Colors.transparent,
            child: Container(
              padding: activeTheme.buttonPadding,
              alignment: Alignment.center,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading) ...[
                      SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            activeTheme.buttonTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ] else ...[
                      _buildLogo(activeTheme.buttonTextColor),
                      const SizedBox(width: 12.0),
                    ],
                    Text(
                      widget.buttonText,
                      style: textStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a beautifully vector-drawn brand-like logo representing Selcom ID.
  Widget _buildLogo(Color color) {
    return SizedBox(
      width: 20.0,
      height: 20.0,
      child: CustomPaint(
        painter: SelcomButtonLogoPainter(color: color),
      ),
    );
  }
}

/// Custom painter rendering a stylized brand logo for Selcom ID
/// within the button itself.
class SelcomButtonLogoPainter extends CustomPainter {
  final Color color;

  SelcomButtonLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Drawn as a sleek, interlocking double-arc or infinity-like ribbon "S"
    final path = Path()
      ..moveTo(w * 0.72, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.05, w * 0.28, h * 0.22)
      ..quadraticBezierTo(w * 0.12, h * 0.40, w * 0.50, h * 0.50)
      ..quadraticBezierTo(w * 0.88, h * 0.60, w * 0.72, h * 0.78)
      ..quadraticBezierTo(w * 0.50, h * 0.95, w * 0.28, h * 0.78)
      ..lineTo(w * 0.38, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.82, w * 0.62, h * 0.68)
      ..quadraticBezierTo(w * 0.74, h * 0.54, w * 0.50, h * 0.46)
      ..quadraticBezierTo(w * 0.26, h * 0.38, w * 0.38, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.14, w * 0.62, h * 0.22)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
