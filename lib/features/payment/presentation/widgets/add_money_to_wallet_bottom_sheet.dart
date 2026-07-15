import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../screens/selcom_pesa_to_wallet_screen.dart';
import 'local_bank_instructions_bottom_sheet.dart';
import 'mobile_money_topup_bottom_sheet.dart';
import 'saved_cards_bottom_sheet.dart';

/// Add-money options after insufficient-balance "Top up Wallet" (Figma sheet).
class AddMoneyToWalletBottomSheet extends StatelessWidget {
  const AddMoneyToWalletBottomSheet({super.key});

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      sheet: const AddMoneyToWalletBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStandardBottomSheet(
      title: AppStrings.addMoneyToWallet.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: false,
      content: const _OptionsContent(),
    );
  }
}

class _OptionsContent extends StatelessWidget {
  const _OptionsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AddMoneyOptionTile(
          title: AppStrings.selcomPesa.tr,
          subtitle: AppStrings.addMoneySelcomPesaSubtitle.tr,
          onTap: _onSelcomPesaTap,
        ),
        SizedBox(height: 12.h),
        _AddMoneyOptionTile(
          title: 'Local banks to Wallet',
          subtitle: AppStrings.addMoneyLocalBanksSubtitle.tr,
          onTap: _onLocalBanksTap,
        ),
        SizedBox(height: 12.h),
        _AddMoneyOptionTile(
          title: AppStrings.mobileMoney.tr,
          subtitle: AppStrings.addMoneyMobileMoneySubtitle.tr,
          onTap: _onMobileMoneyTap,
        ),
        SizedBox(height: 12.h),
        _AddMoneyOptionTile(
          title: AppStrings.savedCardLabel.tr,
          subtitle: AppStrings.savedCardSubtitle.tr,
          onTap: _onSavedCardTap,
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  void _onSelcomPesaTap() {
    Get.back<void>();
    unawaited(SelcomPesaToWalletScreen.open());
  }

  void _onLocalBanksTap() {
    Get.back<void>();
    unawaited(LocalBankInstructionsBottomSheet.show());
  }

  void _onMobileMoneyTap() {
    Get.back<void>();
    unawaited(MobileMoneyTopupBottomSheet.show());
  }

  // ignore: unused_element
  void _onSavedCardTap() {
    Get.back<void>();
    unawaited(SavedCardsBottomSheet.show());
  }
}

class _AddMoneyOptionTile extends StatelessWidget {
  const _AddMoneyOptionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderWalletCard, width: 0.8.w),
          color: AppColors.surfaceSubtle,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
          minimumSize: Size.zero,
          alignment: Alignment.centerLeft,
          onPressed: onTap,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.textHeading,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(subtitle, style: AppTextStyles.homeSubtitle),
                  ],
                ),
              ),
              SvgPictureAsset(
                AppAssets.icArrowForward,
                width: 20.w,
                height: 20.w,
                color: AppColors.iconHeartOutline,
                placeholderBuilder: (_) => Icon(
                  Icons.arrow_forward_ios,
                  size: 20.sp,
                  color: AppColors.textMapHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
