import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_loader_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/payment_dialog_header_section.dart';
import '../../../../shared/widgets/app_primary_button.dart';

/// Animated wallet top-up success dialog.
///
/// Mirrors Duka Direct bill-pay success motion (Lottie check + delayed confetti
/// + slide-in content) while using Selcom Go payment dialog theming.
class WalletTopupSuccessDialog extends StatefulWidget {
  const WalletTopupSuccessDialog({
    super.key,
    this.title,
    this.message,
    this.confirmLabel,
    this.onConfirm,
    this.enableAnimation = true,
  });

  final String? title;
  final String? message;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final bool enableAnimation;

  @override
  State<WalletTopupSuccessDialog> createState() =>
      _WalletTopupSuccessDialogState();
}

class _WalletTopupSuccessDialogState extends State<WalletTopupSuccessDialog>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final AnimationController _contentController;
  late final AnimationController _buttonController;

  late final Animation<Offset> _contentSlide;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _contentFade;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(vsync: this);

    _contentController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.enableAnimation ? 800 : 0),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.enableAnimation ? 400 : 0),
    );

    final contentCurve = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOutCubic,
    );
    final buttonCurve = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOutBack,
    );

    _contentSlide = Tween<Offset>(
      begin: widget.enableAnimation ? const Offset(0, 0.35) : Offset.zero,
      end: Offset.zero,
    ).animate(contentCurve);
    _contentFade = Tween<double>(begin: 0, end: 1).animate(contentCurve);

    _buttonSlide = Tween<Offset>(
      begin: widget.enableAnimation ? const Offset(0, 0.6) : Offset.zero,
      end: Offset.zero,
    ).animate(buttonCurve);
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(buttonCurve);

    if (!widget.enableAnimation) {
      _contentController.value = 1;
      _buttonController.value = 1;
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      _contentController.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _contentController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    widget.onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? AppStrings.walletFundsReceivedTitle.tr;
    final message = (widget.message ?? '').trim().isNotEmpty
        ? widget.message!.trim()
        : AppStrings.walletFundsReceivedSubtitle.tr;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PaymentSuccessDialogHeader(
                  headerHeight: 168.h,
                  centerChild: Align(
                    alignment: const Alignment(0, -0.1),
                    child: SizedBox(
                      width: 128.w,
                      height: 128.w,
                      child: Lottie.asset(
                        AppLoaderAssets.paymentSuccessLottie,
                        repeat: false,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.homeTitle.copyWith(
                              height: 26 / 20,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.homeSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _buttonFade,
                  child: SlideTransition(
                    position: _buttonSlide,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 26.h),
                      child: AppPrimaryButton(
                        label: widget.confirmLabel?.tr ?? AppStrings.gotIt.tr,
                        onPressed: _handleConfirm,
                        width: double.infinity,
                        height: 56.h,
                        borderRadius: 16.r,
                        backgroundColor: AppColors.successBadge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.enableAnimation)
            Positioned(
              top: -24.h,
              left: -8.w,
              right: -8.w,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.55,
                  child: Lottie.asset(
                    AppLoaderAssets.confettiLottie,
                    controller: _confettiController,
                    repeat: false,
                    fit: BoxFit.contain,
                    onLoaded: (composition) {
                      _confettiController.duration = composition.duration;
                      Future<void>.delayed(
                        const Duration(milliseconds: 1100),
                        () {
                          if (mounted) {
                            _confettiController.forward(from: 0);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
