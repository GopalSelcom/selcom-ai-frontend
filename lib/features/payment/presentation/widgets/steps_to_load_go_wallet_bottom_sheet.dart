import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet_gesture_pad.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../controllers/steps_to_load_go_wallet_controller.dart';

class StepsToLoadGoWalletBottomSheet extends StatelessWidget {
  const StepsToLoadGoWalletBottomSheet({super.key, required this.controllerTag});

  final String controllerTag;

  StepsToLoadGoWalletController get _controller =>
      Get.find<StepsToLoadGoWalletController>(tag: controllerTag);

  static Future<void> show() {
    final tag = 'steps_load_wallet_${DateTime.now().millisecondsSinceEpoch}';
    Get.put(StepsToLoadGoWalletController(), tag: tag);

    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.addMoneyStepsToLoadGoWallet.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: StepsToLoadGoWalletBottomSheet(controllerTag: tag),
      footer: AppPrimaryButton(
        label: AppStrings.done.tr,
        onPressed: () => Get.back<void>(),
        width: double.infinity,
        height: 56.h,
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<StepsToLoadGoWalletController>(tag: tag)) {
          Get.delete<StepsToLoadGoWalletController>(tag: tag);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepItem(
          step: '1',
          isLast: false,
          description: AppStrings.addMoneyGoWalletStep1.tr,
        ),
        _StepItem(
          step: '2',
          isLast: false,
          description: AppStrings.addMoneyGoWalletStep2.tr,
        ),
        _StepItem(
          step: '3',
          isLast: false,
          descriptionWidget: Obx(
            () => _StepThreeWalletNumber(
              isLoading: _controller.isLoading.value,
              walletNumber: _controller.formattedWalletNumber,
              onCopy: _controller.copyWalletNumber,
            ),
          ),
        ),
        _StepItem(
          step: '4',
          isLast: false,
          description: AppStrings.addMoneyGoWalletStep4.tr,
        ),
        _StepItem(
          step: '5',
          isLast: true,
          description: AppStrings.addMoneyGoWalletStep5.tr,
        ),
        const AppStandardBottomSheetGesturePad(),
      ],
    );
  }
}

class _StepThreeWalletNumber extends StatelessWidget {
  const _StepThreeWalletNumber({
    required this.isLoading,
    required this.walletNumber,
    required this.onCopy,
  });

  final bool isLoading;
  final String walletNumber;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.addMoneyGoWalletStep3.tr,
          style: AppTextStyles.homeSubtitle,
        ),
        SizedBox(height: 4.h),
        if (isLoading)
          AppShimmer(
            child: AppShimmerBox(
              width: 160.w,
              height: 16.h,
              borderRadius: 6.r,
            ),
          )
        else if (walletNumber.trim().isEmpty)
          Text(
            '—',
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.iconHeartFilled,
            ),
          )
        else
          GestureDetector(
            onTap: onCopy,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    walletNumber,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.iconHeartFilled,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                SvgPictureAsset(
                  AppAssets.icCopy,
                  width: 16.w,
                  height: 16.w,
                  color: AppColors.iconHeartFilled,
                  placeholderBuilder: (_) => Icon(
                    Icons.copy_rounded,
                    size: 16.sp,
                    color: AppColors.iconHeartFilled,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.step,
    required this.isLast,
    this.description,
    this.descriptionWidget,
  });

  final String step;
  final bool isLast;
  final String? description;
  final Widget? descriptionWidget;
  static final double _nodeSize = 48.w;
  static final double _connectorHeight = 32.h;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _nodeSize,
          child: Column(
            children: [
              Container(
                width: _nodeSize,
                height: _nodeSize,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderWalletCard,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHeading,
                    fontSize: 15.sp,
                    height: 20 / 15,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 10.w,
                  height: _connectorHeight,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    border: Border.symmetric(
                      vertical: BorderSide(color: AppColors.borderWalletCard),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: _nodeSize),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: descriptionWidget ??
                      Text(description ?? '', style: AppTextStyles.homeSubtitle),
                ),
              ),
              if (!isLast) SizedBox(height: _connectorHeight),
            ],
          ),
        ),
      ],
    );
  }
}
