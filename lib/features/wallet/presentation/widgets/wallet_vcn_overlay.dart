import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../controllers/wallet_controller.dart';

/// Full-screen blur overlay with virtual card details (Figma Show VCN).
class WalletVcnOverlay extends GetView<WalletController> {
  const WalletVcnOverlay({super.key});

  static Future<void> show() {
    return AppDialogs.showAnimatedDialog<void>(
      barrierDismissible: true,
      child: const WalletVcnOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.asset(
                    AppAssets.imgVcnCard,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 130.h),
                _CardNumberField(
                  cardNumber: controller.formattedVcnCardNumber,
                  onCopy: controller.copyVcnCardNumber,
                ),
                SizedBox(height: 7.h),
                Row(
                  children: [
                    Expanded(
                      child: _LabelValueField(
                        label: AppStrings.expiry.tr,
                        value: controller.vcnExpiry,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: _LabelValueField(
                        label: AppStrings.cvv.tr,
                        value: controller.vcnCvv,
                        onCopy: controller.copyVcnCvv,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 23.h),
                _CloseButton(onPressed: controller.closeShowVcn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardNumberField extends StatelessWidget {
  const _CardNumberField({required this.cardNumber, required this.onCopy});

  final String cardNumber;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(13.w, 17.h, 17.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(child: Text(cardNumber, style: AppTextStyles.homeTitle)),
          _CopyIconButton(onTap: onCopy),
        ],
      ),
    );
  }
}

class _LabelValueField extends StatelessWidget {
  const _LabelValueField({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(13.w, 17.h, 17.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.homeSubtitle),
          const Spacer(),
          Text(value, style: AppTextStyles.homeTitle),
          if (onCopy != null) ...[
            SizedBox(width: 5.w),
            _CopyIconButton(onTap: onCopy!),
          ],
        ],
      ),
    );
  }
}

class _CopyIconButton extends StatelessWidget {
  const _CopyIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPictureAsset(
        AppAssets.icCopy,
        width: 20.w,
        height: 20.w,
        color: AppColors.secondary,
        placeholderBuilder: (_) =>
            Icon(Icons.copy_rounded, size: 20.sp, color: AppColors.secondary),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Icon(Icons.close, size: 24.sp, color: AppColors.black),
        ),
      ),
    );
  }
}
