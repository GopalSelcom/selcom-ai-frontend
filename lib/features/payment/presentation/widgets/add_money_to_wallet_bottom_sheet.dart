import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../settings/data/models/settings_models.dart';
import '../screens/selcom_pesa_to_wallet_screen.dart';
import 'local_bank_instructions_bottom_sheet.dart';
import 'mobile_money_topup_bottom_sheet.dart';
import 'saved_cards_bottom_sheet.dart';

/// Add-money options after insufficient-balance "Top up Wallet" (Figma sheet).
///
/// Option list, titles, subtitles, order, and visibility come from
/// `/go/settings` → `topup_methods` (via [AppSettingsService.enabledTopupMethods]).
/// Each entry's `key` maps to an existing top-up flow in this app.
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

  /// Builds tiles from enabled, ordered API methods with a known flow key.
  /// Skips disabled entries, empty titles, and unknown keys.
  List<_AddMoneyOption> _resolveOptions() {
    return sl<AppSettingsService>()
        .enabledTopupMethods
        .map(_optionFromApiMethod)
        .whereType<_AddMoneyOption>()
        .toList(growable: false);
  }

  _AddMoneyOption? _optionFromApiMethod(TopupMethodSettings method) {
    final title = method.title.trim();
    if (title.isEmpty) return null;

    final onTap = _flowForKey(method.key);
    if (onTap == null) return null;

    return _AddMoneyOption(
      title: title,
      subtitle: method.subtitle.trim(),
      onTap: onTap,
    );
  }

  /// Maps `/go/settings` `topup_methods[].key` → in-app top-up flow.
  VoidCallback? _flowForKey(String key) {
    switch (key) {
      case TopupMethodSettings.keySelcomPesa:
        return _onSelcomPesaTap;
      case TopupMethodSettings.keyLocalBank:
        return _onLocalBanksTap;
      case TopupMethodSettings.keyMobileMoney:
        return _onMobileMoneyTap;
      case TopupMethodSettings.keyCard:
        return _onSavedCardTap;
    }
    // Unknown key from a newer backend — no flow in this app version.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = _resolveOptions();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(height: 12.h),
          _AddMoneyOptionTile(
            title: options[i].title,
            subtitle: options[i].subtitle,
            onTap: options[i].onTap,
          ),
        ],
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

  void _onSavedCardTap() {
    Get.back<void>();
    unawaited(SavedCardsBottomSheet.show());
  }
}

class _AddMoneyOption {
  const _AddMoneyOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
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
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(subtitle, style: AppTextStyles.homeSubtitle),
                    ],
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
