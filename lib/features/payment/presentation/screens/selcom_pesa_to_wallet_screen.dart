import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_skeleton_loader.dart';
import '../../../profile/data/models/selcom_pesa_link_models.dart';
import '../../../profile/presentation/controllers/payment_methods_controller.dart';
import '../widgets/selcom_pesa_account_action_bottom_sheet.dart';
import '../widgets/selcom_pesa_another_number_bottom_sheet.dart';
import '../widgets/selcom_pesa_self_bottom_sheet.dart';

/// Selcom Pesa link + Go wallet top-up on one screen.
///
/// Flow: `docs/flows/selcom-pesa-link-flow.md`
class SelcomPesaToWalletScreen extends StatefulWidget {
  const SelcomPesaToWalletScreen({super.key});

  static Future<void> open() async {
    await Get.toNamed<void>(AppRoutes.selcomPesaToWallet);
  }

  @override
  State<SelcomPesaToWalletScreen> createState() =>
      _SelcomPesaToWalletScreenState();
}

class _SelcomPesaToWalletScreenState extends State<SelcomPesaToWalletScreen> {
  PaymentMethodsController get _paymentController {
    if (Get.isRegistered<PaymentMethodsController>()) {
      return Get.find<PaymentMethodsController>();
    }
    return Get.put(PaymentMethodsController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(
            title: AppStrings.selcomPesaToGoWallet.tr,
            onBack: () => Get.back<void>(),
            bottomPadding: 16.h,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _paymentController.refreshLinkedAccounts,
              child: Obx(() {
                final paymentController = _paymentController;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.paymentMethodsTitle.tr,
                          style: AppTextStyles.homeSubtitle,
                        ),
                        if (paymentController.canLinkAnother &&
                            paymentController.linkedAccountsList.isNotEmpty)
                          GestureDetector(
                            onTap: paymentController.linkSelcomPesa,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              AppStrings.selcomPesaLinkNumber.tr,
                              style: AppTextStyles.homeSubtitle.copyWith(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _linkedAccountsHorizontalList(paymentController),
                    _orDivider(),
                    _actionOption(
                      title: AppStrings.selcomPesaSelfTitle.tr,
                      subtitle: AppStrings.selcomPesaSelfSubtitle.tr,
                      onTap: () => unawaited(SelcomPesaSelfBottomSheet.show()),
                    ),
                    SizedBox(height: 12.h),
                    _actionOption(
                      title: AppStrings.selcomPesaOtherTitle.tr,
                      subtitle: AppStrings.selcomPesaOtherSubtitle.tr,
                      onTap: () =>
                          unawaited(SelcomPesaAnotherNumberBottomSheet.show()),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedAccountsHorizontalList(
    PaymentMethodsController paymentController,
  ) {
    if (paymentController.isLoadingLinkedAccount.value) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            AppSkeletonLoader(width: 280.w, height: 135.h, borderRadius: 16.r),
            SizedBox(width: 12.w),
            AppSkeletonLoader(width: 280.w, height: 135.h, borderRadius: 16.r),
          ],
        ),
      );
    }

    final accounts = paymentController.linkedAccountsList;
    if (accounts.isEmpty) {
      return _selcomCard(paymentController);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < accounts.length; i++) ...[
            if (i > 0) SizedBox(width: 12.w),
            _selcomCard(paymentController, account: accounts[i]),
          ],
        ],
      ),
    );
  }

  Widget _selcomCard(
    PaymentMethodsController paymentMethodsController, {
    Account? account,
  }) {
    final linked = account != null;
    final isSelected =
        linked && paymentMethodsController.isLinkedAccountSelected(account);

    return Container(
      width: 280.w,
      // height: 135.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: isSelected
              ? AppColors.successBadge
              : AppColors.borderWalletCard,
          width: isSelected ? 1.5 : 0.8,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (linked) {
              paymentMethodsController.toggleLinkedAccountSelection(account);
              unawaited(SelcomPesaSelfBottomSheet.show(account: account));
            } else {
              paymentMethodsController.linkSelcomPesa();
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: linked
                ? _linkedSelcomCardContent(paymentMethodsController, account)
                : _unlinkedSelcomCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _linkedSelcomCardContent(
    PaymentMethodsController paymentMethodsController,
    Account account,
  ) {
    final phoneDisplay = paymentMethodsController.phoneDisplayFor(account);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.selcomPesa.tr,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (account.isDefault ?? false) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successBadge,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                GestureDetector(
                  onTap: () => unawaited(
                    SelcomPesaAccountActionBottomSheet.show(
                      account: account,
                      paymentMethodsController: paymentMethodsController,
                    ),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.more_vert,
                    size: 20.sp,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              phoneDisplay,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textBody,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.0.sp),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Obx(
                () => Text(
                  paymentMethodsController.linkedAccountBalanceDisplay(account),
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ),
            Obx(() {
              final loading = paymentMethodsController
                  .isLinkedAccountBalanceLoading(account);
              return GestureDetector(
                onTap: loading
                    ? null
                    : () => unawaited(
                        paymentMethodsController.revealLinkedAccountBalance(
                          account,
                        ),
                      ),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: loading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          // Cupertino spinner for Selcom Pesa main_balance eye reveal.
                          child: CupertinoActivityIndicator(
                            radius: 8.r,
                            color: AppColors.black,
                          ),
                        )
                      : Obx(() {
                          return Icon(
                            _paymentController.isAmountVisible.value
                                ? Iconsax.eye
                                : Iconsax.eye_slash,
                            size: 18.sp,
                            color: AppColors.textBody,
                          );
                        }),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _unlinkedSelcomCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.selcomPesa.tr,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              AppStrings.connectSelcomPesaRideChargesSubtitle.tr,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textBody,
                fontSize: 12.sp,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Text(
          AppStrings.linkAccount.tr,
          style: AppTextStyles.homeSubtitle.copyWith(color: AppColors.brandRed),
        ),
      ],
    );
  }

  Widget _orDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.borderWalletCard, thickness: 1),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'OR',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.borderWalletCard, thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _actionOption({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.homeTitle.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHeading,
            ),
          ],
        ),
      ),
    );
  }
}
