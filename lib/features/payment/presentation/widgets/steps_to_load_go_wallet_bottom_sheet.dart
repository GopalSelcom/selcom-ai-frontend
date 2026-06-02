import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class StepsToLoadGoWalletBottomSheet extends StatelessWidget {
  const StepsToLoadGoWalletBottomSheet({super.key});
  static const String _goWalletNumber = '7124 12665 765';

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.addMoneyStepsToLoadGoWallet.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: const StepsToLoadGoWalletBottomSheet(),
      footer: AppPrimaryButton(
        label: AppStrings.done.tr,
        onPressed: () => Get.back<void>(),
        width: double.infinity,
        height: 56.h,
      ),
    );
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
          descriptionWidget: RichText(
            text: TextSpan(
              style: AppTextStyles.homeSubtitle,
              children: [
                TextSpan(text: '${AppStrings.addMoneyGoWalletStep3.tr}\n'),
                TextSpan(
                  text: _goWalletNumber,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.iconHeartFilled,
                  ),
                ),
              ],
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
              SizedBox(
                height: _nodeSize,
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
