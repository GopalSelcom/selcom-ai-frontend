import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'payment_dialog_header_clipper.dart';
import 'svg_picture_asset.dart';

/// Header strip used by [PaymentStatusDialog] and any dialog that must match it visually.
///
/// Keep this widget in sync with payment UX — do not duplicate the layout elsewhere.
class PaymentDialogHeaderSection extends StatelessWidget {
  const PaymentDialogHeaderSection({
    super.key,
    required this.backgroundColor,
    required this.iconAsset,
    required this.iconColor,
    required this.placeholderIcon,
    this.topCornerRadius = 28,
    this.headerHeight,
    this.centerChild,
    this.overlay,
  });

  final Color backgroundColor;
  final String iconAsset;
  final Color iconColor;
  final IconData placeholderIcon;

  /// Matches [PaymentStatusDialog] outer radius (`28.r`).
  final double topCornerRadius;

  /// Optional layer above the icon (e.g. label pill). When non-null, [Stack] uses
  /// [Clip.none] so overlays can extend slightly past the header bounds if needed.
  final Widget? overlay;

  /// Defaults to `132.h` ([PaymentStatusDialog]).
  final double? headerHeight;

  /// When set, replaces the default centered SVG (e.g. solid circle + check).
  final Widget? centerChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight ?? 132.h,
      width: double.infinity,
      child: Stack(
        clipBehavior: overlay != null ? Clip.none : Clip.hardEdge,
        children: [
          ClipPath(
            clipper: PaymentDialogHeaderClipper(),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(topCornerRadius.r),
                ),
              ),
            ),
          ),
          centerChild ??
              Align(
                alignment: const Alignment(0, -0.05),
                child: SvgPictureAsset(
                  iconAsset,
                  width: 75.w,
                  height: 75.w,
                  color: iconColor,
                  placeholderBuilder: (_) => Icon(
                    placeholderIcon,
                    color: iconColor,
                    size: 75.sp,
                  ),
                ),
              ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

/// Success-state header matching payment completion dialog (fixed assets/colors).
class PaymentSuccessDialogHeader extends StatelessWidget {
  const PaymentSuccessDialogHeader({
    super.key,
    this.overlay,
    this.headerHeight,
    this.centerChild,
  });

  final Widget? overlay;

  /// When set (e.g. saved-place confirmation), slightly taller than payment dialog.
  final double? headerHeight;

  /// Optional replacement for the default success SVG (e.g. filled circle + check).
  final Widget? centerChild;

  @override
  Widget build(BuildContext context) {
    return PaymentDialogHeaderSection(
      backgroundColor: AppColors.bgPaymentSuccess,
      iconAsset: AppAssets.icSuccess,
      iconColor: AppColors.iconPaymentSuccess,
      placeholderIcon: Icons.check_circle,
      headerHeight: headerHeight,
      centerChild: centerChild,
      overlay: overlay,
    );
  }
}
