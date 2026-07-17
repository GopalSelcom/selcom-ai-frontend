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
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../wallet/presentation/utils/wallet_format_utils.dart';

class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.balance,
    required this.walletNumber,
    this.currencyCode,
    this.isLoading = false,
    this.isRefreshingBalance = false,
    this.isBalanceVisible = false,
    this.onToggleBalanceVisibility,
    this.onCopyWalletNumber,
  });

  final String balance;
  final String walletNumber;
  final String? currencyCode;

  /// First-load shimmer for account number and amount.
  final bool isLoading;

  /// Eye-tap API in flight: keep amount text, replace eye icon with a spinner.
  final bool isRefreshingBalance;

  /// When false, amount is masked but currency stays visible (e.g. `TZS ••••••`).
  final bool isBalanceVisible;

  /// Toggles hide/show; while refreshing, the gesture is ignored.
  final VoidCallback? onToggleBalanceVisibility;

  /// Delegates copy to controller; feedback handled in [copyToClipboardWithFeedback].
  final VoidCallback? onCopyWalletNumber;

  static const String _accountNumberWidthTemplate = '000 000 000 00';

  static double get amountGroupWidth => 96.w;

  TextStyle get _accountNumberStyle => AppTextStyles.caption.copyWith(
    color: AppColors.textBody,
    fontSize: 12.sp,
    height: 20 / 12,
  );

  double _textWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _accountNumberTemplateWidth() =>
      _textWidth(_accountNumberWidthTemplate, _accountNumberStyle);

  String _displayAccountNumber() {
    if (walletNumber.isEmpty) return '—';
    final clean = walletNumber.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return '—';
    return formatWalletAccountNumber(clean);
  }

  TextStyle get _amountStyle => AppTextStyles.price.copyWith(
    color: AppColors.black,
    fontWeight: FontWeight.w600,
    fontSize: 17.sp,
    height: 23.11 / 17,
    letterSpacing: -0.27,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(27.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 51.w,
                height: 51.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(12.w),
                child: const SvgPictureAsset(
                  AppAssets.icWallet,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 13.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.wallet.tr,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHeading,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildAccountNumberRow(),
                ],
              ),
            ],
          ),
          _buildAmountRow(),
        ],
      ),
    );
  }

  Widget _buildAccountNumberRow() {
    final displayNumber = _displayAccountNumber();
    final hasNumber = walletNumber.trim().isNotEmpty;
    final templateWidth = _accountNumberTemplateWidth();

    if (isLoading) {
      return AppShimmer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppShimmerBox(
              width: templateWidth,
              height: 12.h,
              borderRadius: 6.r,
            ),
            SizedBox(width: 2.w),
            AppShimmerBox(width: 14.w, height: 14.w, borderRadius: 4.r),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayNumber,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _accountNumberStyle,
        ),
        if (hasNumber && onCopyWalletNumber != null) ...[
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: onCopyWalletNumber,
            child: SvgPictureAsset(
              AppAssets.icCopy,
              width: 14.w,
              height: 14.w,
              placeholderBuilder: (_) => Icon(
                Iconsax.copy,
                size: 14.w,
                color: AppColors.textHeading.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatBalanceLabel() {
    if (balance.isEmpty) return '—';
    final code = currencyCode?.trim();
    if (code != null && code.isNotEmpty) {
      final amount = double.tryParse(balance.replaceAll(',', '')) ?? 0;
      return CurrencyFormatter.formatWithApiCurrency(amount, code);
    }
    return '${CurrencyFormatter.displaySymbol} $balance';
  }

  String _loadingCurrencySymbol() {
    final code = currencyCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    return CurrencyFormatter.displaySymbol;
  }

  Widget _buildAmountRow() {
    // During eye refresh, keep the previous amount visible (no shimmer).
    final showAmount =
        (isBalanceVisible || isRefreshingBalance) && balance.isNotEmpty;
    // Hidden: currency + dots; visible: full formatted balance from API/cache.
    final amountLabel = showAmount
        ? _formatBalanceLabel()
        : formatHiddenWalletBalance(currencyCode);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: amountGroupWidth,
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(_loadingCurrencySymbol(), style: _amountStyle),
                    SizedBox(width: 4.w),
                    AppShimmer(
                      child: AppShimmerBox(
                        width: 52.w,
                        height: 20.h,
                        borderRadius: 8.r,
                      ),
                    ),
                  ],
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _amountStyle,
                  ),
                ),
        ),
        // Eye / eye-slash; Cupertino spinner while balance refresh is in flight.
        if (!isLoading && onToggleBalanceVisibility != null) ...[
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: isRefreshingBalance ? null : onToggleBalanceVisibility,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: isRefreshingBalance
                    ? CupertinoActivityIndicator(
                        radius: 9.r,
                        color: AppColors.black,
                      )
                    : Icon(
                        isBalanceVisible ? Iconsax.eye_slash : Iconsax.eye,
                        size: 18.w,
                        color: AppColors.textHeading.withValues(alpha: 0.5),
                      ),
              ),
            ),
          ),
        ],
        SizedBox(width: 8.w),
        SvgPictureAsset(
          AppAssets.icArrowForward,
          width: 20.w,
          height: 20.w,
          color: AppColors.textHeading.withValues(alpha: 0.5),
          placeholderBuilder: (_) => Icon(
            Icons.arrow_forward_ios_rounded,
            size: 24.w,
            color: AppColors.textHeading.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
