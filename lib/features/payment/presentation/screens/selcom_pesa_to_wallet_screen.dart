import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../../shared/widgets/app_cupertino_text_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../profile/domain/entities/selcom_pesa_linked_account_entity.dart';
import '../../../profile/presentation/controllers/payment_methods_controller.dart';
import '../bindings/selcom_pesa_to_wallet_binding.dart';
import '../controllers/selcom_pesa_topup_controller.dart';
import '../widgets/selcom_pesa_another_number_bottom_sheet.dart';
import '../widgets/wallet_topup_sheet_lifecycle.dart';

/// Selcom Pesa link + Go wallet top-up on one screen.
///
/// Flow: `docs/flows/selcom-pesa-link-flow.md`
/// - Link / linked list / selection / balance / unlink → [PaymentMethodsController]
/// - Amount + Done top-up → [SelcomPesaTopupController] (tag from [SelcomPesaToWalletBinding])
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
  late final TextEditingController _selfAmountController;

  String? get _topupTag => SelcomPesaToWalletBinding.topupTag;

  SelcomPesaTopupController? get _topupController {
    final tag = _topupTag;
    if (tag == null || !Get.isRegistered<SelcomPesaTopupController>(tag: tag)) {
      return null;
    }
    return Get.find<SelcomPesaTopupController>(tag: tag);
  }

  PaymentMethodsController get _paymentController {
    if (Get.isRegistered<PaymentMethodsController>()) {
      return Get.find<PaymentMethodsController>();
    }
    return Get.put(PaymentMethodsController(), permanent: true);
  }

  @override
  void initState() {
    super.initState();
    _selfAmountController = TextEditingController();
  }

  @override
  void dispose() {
    final tag = _topupTag;
    if (tag != null) {
      unawaited(disposeSelcomPesaTopupAfterSheetClosed(tag));
    }
    _selfAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topup = _topupController;
    final topupTag = _topupTag;

    if (topupTag == null || topup == null || topup.textFieldsDisposed) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          AppProfileHeader(
            title: AppStrings.selcomPesaToGoWallet.tr,
            onBack: () => Get.back<void>(),
            bottomPadding: 16.h,
          ),
          Expanded(
            // Pull-to-refresh reloads linked accounts from GET linked_accounts.
            child: RefreshIndicator(
              onRefresh: _paymentController.refreshLinkedAccounts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 8.h),
                    Text(
                      AppStrings.paymentMethodsTitle.tr,
                      style: AppTextStyles.homeSubtitle,
                    ),
                    SizedBox(height: 8.h),
                    Obx(() => _linkedAccountsSection(_paymentController)),
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () =>
                            unawaited(SelcomPesaAnotherNumberBottomSheet.show()),
                        child: Text(
                          AppStrings.useAnotherNumber.tr,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            color: AppColors.iconHeartFilled,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Obx(() => _selfAmountSection(topup)),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: _SelcomPesaSelfFooter(
                controllerTag: topupTag,
                amountController: _selfAmountController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selfAmountSection(SelcomPesaTopupController topup) {
    if (topup.textFieldsDisposed) return const SizedBox.shrink();
    final apiError = topup.apiError.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.amount.tr,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: AppColors.textMutedStrong,
          ),
        ),
        SizedBox(height: 4.h),
        AppTextField(
          readOnly: false,
          enabled: !topup.isSubmitting.value,
          hintText: '5,000',
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          textFieldBackgroundColor: AppColors.surfaceSubtle,
          borderColor: AppColors.borderWalletCard,
          controller: _selfAmountController,
          errorText: topup.amountError.value,
          onChanged: topup.onAmountChanged,
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16.w, right: 8.w),
            child: Center(
              widthFactor: 1,
              child: Text(
                AppStrings.defaultCurrencyTzs.tr,
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 16.sp,
                  height: 22 / 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ),
          ),
          textColor: AppColors.textHeading,
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
        ),
        if (apiError != null && apiError.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            apiError,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.error,
              fontSize: 13.sp,
            ),
          ),
        ],
        SizedBox(height: 25.h),
      ],
    );
  }

  /// Empty → single unlinked card; otherwise one card per LINKED account + optional link-another.
  Widget _linkedAccountsSection(PaymentMethodsController paymentController) {
    final accounts = paymentController.linkedAccountsList;
    if (accounts.isEmpty) {
      return _selcomCard(paymentController);
    }
    return Column(
      children: [
        for (var i = 0; i < accounts.length; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          _selcomCard(
            paymentController,
            account: accounts[i],
            // showDefaultBadge: i == 0, // No default linked account for now.
          ),
        ],
        if (paymentController.canLinkAnother) ...[
          SizedBox(height: 8.h),
          _linkAnotherAccountCard(paymentController),
        ],
      ],
    );
  }

  Widget _linkAnotherAccountCard(PaymentMethodsController paymentController) {
    return InkWell(
      onTap: paymentController.linkSelcomPesa,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.linkAnotherAccount.tr,
                style: AppTextStyles.homeSubtitle.copyWith(
                  color: AppColors.iconHeartFilled,
                ),
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              size: 22.sp,
              color: AppColors.iconHeartFilled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _selcomCard(
    PaymentMethodsController paymentMethodsController, {
    SelcomPesaLinkedAccountEntity? account,
    // bool showDefaultBadge = false, // No default linked account for now.
  }) {
    final linked = account != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: linked
          ? _linkedSelcomCardContent(paymentMethodsController, account)
          : InkWell(
              onTap: paymentMethodsController.linkSelcomPesa,
              child: _unlinkedSelcomCardContent(),
            ),
    );
  }

  /// Linked card: title + selector, phone, hidden balance + eye, Remove account.
  Widget _linkedSelcomCardContent(
    PaymentMethodsController paymentMethodsController,
    SelcomPesaLinkedAccountEntity account,
  ) {
    final phoneDisplay = paymentMethodsController.phoneDisplayFor(account);

    return Column(
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
                ),
              ),
            ),
            _linkedAccountSelectionControl(paymentMethodsController, account),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          AppStrings.selcomPesaLinkedNumber.trParams({
            'number': phoneDisplay,
          }),
          style: AppTextStyles.bodySecondary.copyWith(height: 20 / 14),
        ),
        SizedBox(height: 10.h),
        Row(
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
              final loading =
                  paymentMethodsController.isLinkedAccountBalanceLoading(
                account,
              );
              return GestureDetector(
                onTap: loading
                    ? null
                    : () => unawaited(
                        paymentMethodsController.revealLinkedAccountBalance(
                          account,
                        ),
                      ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 4.h, 0, 4.h),
                  child: loading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Iconsax.eye,
                          size: 20.sp,
                          color: AppColors.textBody,
                        ),
                ),
              );
            }),
          ],
        ),
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerRight,
          child: AppCupertinoTextButton(
            label: AppStrings.removeAccount.tr,
            onPressed: () => unawaited(
              paymentMethodsController.unlinkLinkedAccount(account),
            ),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerRight,
            textStyle: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.iconHeartFilled,
            ),
          ),
        ),
      ],
    );
  }

  Widget _unlinkedSelcomCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selcomPesa.tr,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          AppStrings.connectSelcomPesaRideChargesSubtitle.tr,
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textBody,
            fontSize: 12.sp,
            height: 20 / 12,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          AppStrings.linkAccount.tr,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: AppColors.iconHeartFilled,
          ),
        ),
      ],
    );
  }

  Widget _linkedAccountSelectionControl(
    PaymentMethodsController paymentMethodsController,
    SelcomPesaLinkedAccountEntity account,
  ) {
    return Obx(() {
      final selected = paymentMethodsController.isLinkedAccountSelected(account);
      return GestureDetector(
        onTap: () => paymentMethodsController.toggleLinkedAccountSelection(
          account,
        ),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? AppColors.textVerified
                  : AppColors.borderWalletCard,
              width: 2,
            ),
            color: selected ? AppColors.textVerified : AppColors.white,
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 16.sp,
                  color: AppColors.white,
                )
              : null,
        ),
      );
    });
  }
}

/// Done branches: selected linked card → other-number top-up API; else self top-up (opens SP app).
class _SelcomPesaSelfFooter extends GetView<SelcomPesaTopupController> {
  const _SelcomPesaSelfFooter({
    required this.controllerTag,
    required this.amountController,
  });

  final String controllerTag;
  final TextEditingController amountController;

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.isRegistered<SelcomPesaTopupController>(tag: controllerTag) ||
          controller.textFieldsDisposed) {
        return const SizedBox.shrink();
      }
      return AppPrimaryButton(
        label: AppStrings.done.tr,
        onPressed: controller.canSubmitSelf ? _onDonePressed : null,
        isLoading: controller.isSubmitting.value,
        borderRadius: 16.r,
        height: 56.h,
      );
    });
  }

  void _onDonePressed() {
    controller.onAmountChanged(amountController.text);
    controller.amountError.value = controller.validateAmountForDisplay();
    if (controller.amountError.value != null) return;

    final paymentController = Get.isRegistered<PaymentMethodsController>()
        ? Get.find<PaymentMethodsController>()
        : null;
    final selectedAccount = paymentController?.selectedLinkedAccount;

    if (selectedAccount != null) {
      unawaited(
        controller.submitSelectedLinkedAccountTopUp(
          account: selectedAccount,
          closeSheetFirst: false,
        ),
      );
      return;
    }

    unawaited(controller.submitSelfTopUp(closeSheetFirst: true));
  }
}
