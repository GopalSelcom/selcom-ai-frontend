import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/wallet_enter_nida_controller.dart';
import '../utils/mask_text_input_formatter.dart';

/// Select ID — same flow/layout as selcom_auth, styled with Duka Go theme tokens.
class WalletEnterNidaScreen extends GetView<WalletEnterNidaController> {
  const WalletEnterNidaScreen({super.key});

  static const double _sectionHeaderHeight = 55;
  static const double _sectionRadius = 15;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Obx(
        () => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            20.w,
            8.h,
            20.w,
            bottomInset > 0 ? bottomInset + 12.h : 16.h,
          ),
          child: SafeArea(
            top: false,
            child: controller.isButtonEnabled.value
                ? AppPrimaryButton(
                    label: AppStrings.continueLabel.tr,
                    width: double.infinity,
                    height: 52.h,
                    onPressed: controller.submitVerification,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 0),
              child: AppBackButton(
                color: AppColors.textHeading,
                size: 22.w,
                onPressed: Get.back,
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: SvgPictureAsset(
                AppAssets.selcomGoLogo,
                width: 154.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                AppStrings.walletLinkSelectId.tr,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 24.sp,
                  height: 30 / 24,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  children: [
                    _NidaSection(controller: controller),
                    SizedBox(height: 16.h),
                    _PassportSection(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NidaSection extends StatelessWidget {
  const _NidaSection({required this.controller});

  final WalletEnterNidaController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final expanded = controller.isNidaSelected.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bgVerificationSurface,
            borderRadius: BorderRadius.circular(
              WalletEnterNidaScreen._sectionRadius.r,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                selected: expanded,
                label: AppStrings.walletLinkNida.tr,
                onTap: controller.selectNida,
              ),
              if (expanded) ...[
                Divider(
                  height: 1,
                  color: AppColors.borderDefault.withValues(alpha: 0.6),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 15.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.walletLinkEnterNidaHint.tr,
                        style: AppTextStyles.bodySecondary.copyWith(
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      AppTextField(
                        label: AppStrings.walletLinkNidaFieldHint.tr,
                        hintText: AppStrings.walletLinkNidaFieldHint.tr,
                        controller: controller.nidaNumberController,
                        focusNode: controller.nidaFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 23,
                        onChanged: (_) => controller.onNidaFieldChanged(),
                        inputFormatters: [
                          MaskTextInputFormatter(
                            mask: '########-#####-#####-##',
                            filter: {'#': RegExp(r'[0-9]')},
                          ),
                        ],
                        textFieldBackgroundColor: AppColors.cardBackground,
                        borderColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PassportSection extends StatelessWidget {
  const _PassportSection({required this.controller});

  final WalletEnterNidaController controller;

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime minimumDate,
    required DateTime maximumDate,
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    controller.unfocusAll();
    DateTime picked = initialDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280.h,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                initialDateTime: initialDate,
                dateOrder: DatePickerDateOrder.ymd,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: AppPrimaryButton(
                label: AppStrings.continueLabel.tr,
                width: double.infinity,
                height: 48.h,
                onPressed: () {
                  onSelected(picked);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final expanded = !controller.isNidaSelected.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bgVerificationSurface,
            borderRadius: BorderRadius.circular(
              WalletEnterNidaScreen._sectionRadius.r,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                selected: expanded,
                label: AppStrings.walletLinkPassport.tr,
                onTap: controller.selectPassport,
              ),
              if (expanded) ...[
                Divider(
                  height: 1,
                  color: AppColors.borderDefault.withValues(alpha: 0.6),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 15.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.walletLinkPassportDetailsHint.tr,
                        style: AppTextStyles.bodySecondary.copyWith(
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      AppTextField(
                        label: AppStrings.walletLinkPassportNumber.tr,
                        hintText: AppStrings.walletLinkPassportNumberHint.tr,
                        controller: controller.passportNumberController,
                        focusNode: controller.passportFocusNode,
                        textInputAction: TextInputAction.done,
                        maxLength: 11,
                        onChanged: (_) => controller.onPassportNumberChanged(),
                        inputFormatters: [
                          MaskTextInputFormatter(
                            mask: 'AAA AAA AAA',
                            filter: {'A': RegExp(r'[a-zA-Z0-9]')},
                          ),
                        ],
                        textFieldBackgroundColor: AppColors.cardBackground,
                        borderColor: Colors.transparent,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DateField(
                              label: AppStrings.walletLinkDateOfBirth.tr,
                              controller: controller.passportDobController,
                              hintText: AppStrings.walletLinkDatePlaceholder.tr,
                              onTap: () {
                                final now = DateTime.now();
                                _pickDate(
                                  context,
                                  minimumDate: DateTime(1950),
                                  maximumDate: now,
                                  initialDate: now,
                                  onSelected: controller.setPassportDateOfBirth,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _DateField(
                              label: AppStrings.walletLinkDateOfExpiry.tr,
                              controller: controller.passportExpiryController,
                              hintText: AppStrings.walletLinkDatePlaceholder.tr,
                              onTap: () {
                                final now = DateTime.now();
                                final today =
                                    DateTime(now.year, now.month, now.day);
                                _pickDate(
                                  context,
                                  minimumDate: today,
                                  maximumDate: DateTime(today.year + 20),
                                  initialDate: today,
                                  onSelected: controller.setPassportExpiry,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: WalletEnterNidaScreen._sectionHeaderHeight.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.primaryButton
                      : AppColors.textBody,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppColors.textHeading
                        : AppColors.textBody,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(
        child: AppTextField(
          label: label,
          hintText: hintText,
          controller: controller,
          readOnly: true,
          textFieldBackgroundColor: AppColors.cardBackground,
          borderColor: Colors.transparent,
        ),
      ),
    );
  }
}
