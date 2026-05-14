import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';
import '../../features/ride/presentation/controllers/vehicle_selection_controller.dart';

/// Bottom sheet: enter promo + inline Apply (same row pattern as [PromocodeScreen]).
class RidePromoCodeSheet extends StatefulWidget {
  const RidePromoCodeSheet({super.key, required this.controller});

  final VehicleSelectionController controller;

  @override
  State<RidePromoCodeSheet> createState() => _RidePromoCodeSheetState();
}

class _RidePromoCodeSheetState extends State<RidePromoCodeSheet> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: widget.controller.appliedPromoCode.value,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: bottom + 16.h,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _text,
        builder: (context, tv, __) {
          return Obx(() {
            final loading = widget.controller.promoSheetLoading.value;
            final err = widget.controller.promoSheetInlineError.value;
            final applied = widget.controller.appliedPromoCode.value.trim();
            final trimmed = tv.text.trim().toUpperCase();
            final canApply =
                trimmed.isNotEmpty && trimmed != applied && !loading;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.skeletonBase,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.havePromoCode.tr,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                    height: 34 / 20,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppStrings.ridePromoSheetSubtitle.tr,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.textMutedStrong,
                    fontWeight: FontWeight.w500,
                    height: 20 / 15,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildPromoInputRow(loading: loading, canApply: canApply),
                if (err != null && err.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    widget.controller.userMessageForPromoSheetError(err),
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.error,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildPromoInputRow({required bool loading, required bool canApply}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.inputBorderDefault.withValues(alpha: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SvgPictureAsset(
              AppAssets.icPromoCode,
              width: 24.w,
              height: 24.w,
              placeholderBuilder: (_) => Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  color: AppColors.promotionBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.percent, color: AppColors.white, size: 14.sp),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _text,
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                enabled: !loading,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textHeading,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: AppColors.primary,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]')),
                ],
                onChanged: (v) {
                  final u = v.toUpperCase();
                  if (u != v) {
                    _text.value = TextEditingValue(
                      text: u,
                      selection: TextSelection.collapsed(offset: u.length),
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: AppStrings.enterPromoCode.tr,
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            const VerticalDivider(
              color: AppColors.divider,
              width: 1,
              thickness: 1,
            ),
            SizedBox(width: 10.w),
            if (loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: canApply
                    ? () => widget.controller.applyPromoFromSheet(_text.text)
                    : null,
                child: Text(
                  AppStrings.apply.tr,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
