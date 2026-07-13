import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import 'wallet_icon_label_button.dart';

class WalletInfoCard extends StatelessWidget {
  const WalletInfoCard({
    super.key,
    required this.balanceText,
    this.reservedBalanceText,
    required this.walletNumberText,
    required this.isBalanceVisible,
    required this.isRefreshingBalance,
    this.onToggleBalanceVisibility,
    required this.onCopyWalletNumber,
    required this.onAddMoney,
    required this.onEStatement,
  });

  final String balanceText;
  final String? reservedBalanceText;
  final String walletNumberText;
  final bool isBalanceVisible;
  final bool isRefreshingBalance;
  final VoidCallback? onToggleBalanceVisibility;
  final VoidCallback onCopyWalletNumber;
  final VoidCallback onAddMoney;
  final VoidCallback onEStatement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(28.w, 17.h, 28.w, 26.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPictureAsset(
                  AppAssets.icWallet,
                  color: AppColors.primary,
                  width: 66.w,
                  height: 64.h,
                ),
                SizedBox(width: 21.5.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              balanceText,
                              style: AppTextStyles.homeTitle.copyWith(
                                fontSize: 30.sp,
                                letterSpacing: -0.3,
                                height: 38 / 30,
                              ),
                            ),
                          ),
                          if (onToggleBalanceVisibility != null) ...[
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: isRefreshingBalance
                                  ? null
                                  : onToggleBalanceVisibility,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: EdgeInsets.all(2.w),
                                child: SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  // Cupertino spinner while go_card_balance refresh runs.
                                  child: isRefreshingBalance
                                      ? CupertinoActivityIndicator(
                                          radius: 11.r,
                                          color: AppColors.black,
                                        )
                                      : Icon(
                                          isBalanceVisible
                                              ? Iconsax.eye_slash
                                              : Iconsax.eye,
                                          size: 22.w,
                                          color: AppColors.textHeading
                                              .withValues(alpha: 0.5),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (reservedBalanceText != null &&
                          reservedBalanceText!.isNotEmpty) ...[
                        // Reserved amount visibility is driven by the controller
                        // (masked/unmasked together with the main balance).
                        SizedBox(height: 4.h),
                        Text(
                          reservedBalanceText!,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            fontSize: 12.sp,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                      Text(
                        AppStrings.walletNumberLabel.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      Row(
                        children: [
                          Text(
                            walletNumberText,
                            style: AppTextStyles.homeSubtitle,
                          ),
                          SizedBox(width: 6.w),
                          GestureDetector(
                            onTap: onCopyWalletNumber,
                            child: SvgPictureAsset(
                              AppAssets.icCopy,
                              width: 18.w,
                              height: 18.w,
                              color: AppColors.textHint,
                              placeholderBuilder: (_) => Icon(
                                Icons.copy_rounded,
                                size: 18.sp,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1.h, color: AppColors.borderWalletCard),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 39.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                WalletIconLabelButton(
                  label: AppStrings.addMoney.tr,
                  iconAsset: AppAssets.icCardReceive,
                  onTap: onAddMoney,
                ),
                WalletIconLabelButton(
                  label: AppStrings.eStatement.tr,
                  iconAsset: AppAssets.icEStatement,
                  onTap: onEStatement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
