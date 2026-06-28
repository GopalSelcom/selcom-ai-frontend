import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/bottom_inset_helper.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/phone_country_picker_chip.dart';
import '../controllers/booking_for_someone_else_flow_controller.dart';

export '../controllers/booking_for_someone_else_flow_controller.dart'
    show BookingMode, BookingFlowStep;

class BookingForSomeoneElseFlowBottomSheet extends StatelessWidget {
  const BookingForSomeoneElseFlowBottomSheet({
    super.key,
    required this.controllerTag,
  });

  final String controllerTag;

  BookingForSomeoneElseFlowController get controller =>
      Get.find<BookingForSomeoneElseFlowController>(tag: controllerTag);

  /// Opens the multi-step booking sheet via [AppDialogs.showStandardBottomSheet].
  static Future<Map<String, dynamic>?> show() {
    final controllerTag =
        'booking_for_someone_else_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(BookingForSomeoneElseFlowController(), tag: controllerTag);

    return AppDialogs.showStandardBottomSheet<Map<String, dynamic>>(
      sheet: BookingForSomeoneElseFlowBottomSheet(controllerTag: controllerTag),
      barrierDismissible: true,
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (Get.isRegistered<BookingForSomeoneElseFlowController>(
          tag: controllerTag,
        )) {
          Get.delete<BookingForSomeoneElseFlowController>(tag: controllerTag);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.currentStep.value;
      controller.canConfirm.value;
      controller.nameError.value;
      controller.phoneError.value;
      controller.selectedCountry.value;
      controller.phoneFieldKey.value;

      final isDetails =
          controller.currentStep.value == BookingFlowStep.details;
      final showFooter = isDetails && controller.canConfirm.value;

      return AppStandardBottomSheet(
        title: controller.sheetTitle,
        subtitle: controller.sheetSubtitle,
        headerTextAlign: TextAlign.start,
        maxHeightFactor: 0.75,
        hasBottomWidget: isDetails,
        liftBodyForKeyboard: !isDetails,
        bottomBodyWidget:
            isDetails ? null : const _BookingSheetBottomPad(),
        content: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.1, 0.0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          child: controller.currentStep.value == BookingFlowStep.choice
              ? _BookingChoiceStep(controller: controller)
              : _BookingDetailsStep(controller: controller),
        ),
        footer: isDetails
            ? AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                child: showFooter
                    ? AppPrimaryButton(
                        key: const ValueKey('booking-confirm-footer'),
                        label: AppStrings.confirm.tr,
                        iconAsset: AppAssets.locationIcArrowRight,
                        alignIconToTrailingEnd: true,
                        onPressed: controller.onConfirmPressed,
                      )
                    : const SizedBox(
                        key: ValueKey('booking-footer-spacer'),
                        width: double.infinity,
                      ),
              )
            : null,
      );
    });
  }
}

class _BookingChoiceStep extends StatelessWidget {
  const _BookingChoiceStep({required this.controller});

  final BookingForSomeoneElseFlowController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(BookingFlowStep.choice),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bookingChoiceRow(
          icon: Iconsax.user,
          title: AppStrings.bookingRideOptionForMe.tr,
          onTap: controller.confirmSelfBooking,
        ),
        SizedBox(height: 12.h),
        _bookingChoiceRow(
          icon: Iconsax.user_add,
          title: AppStrings.bookingRideOptionForSomeoneElse.tr,
          onTap: controller.goToDetailsStep,
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _bookingChoiceRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textBody,
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDetailsStep extends StatefulWidget {
  const _BookingDetailsStep({required this.controller});

  final BookingForSomeoneElseFlowController controller;

  @override
  State<_BookingDetailsStep> createState() => _BookingDetailsStepState();
}

class _BookingDetailsStepState extends State<_BookingDetailsStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  BookingForSomeoneElseFlowController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _nameController.addListener(controller.onFieldsChanged);
    _phoneController.addListener(controller.onFieldsChanged);
    controller.bindDetailFields(
      name: _nameController,
      phone: _phoneController,
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(controller.onFieldsChanged);
    _phoneController.removeListener(controller.onFieldsChanged);
    controller.unbindDetailFields();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(BookingFlowStep.details),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _nameController,
          label: AppStrings.passengerNameLabel.tr,
          hintText: AppStrings.enterPassengerFullName.tr,
          keyboardType: TextInputType.name,
          errorText: controller.nameError.value,
          onChanged: (_) {},
          suffixIcon: IconButton(
            icon: Icon(Iconsax.user_add, color: AppColors.primary, size: 22.sp),
            onPressed: controller.pickContact,
          ),
        ),
        SizedBox(height: 16.h),
        AppTextField(
          key: ValueKey(
            'passenger-phone-${controller.selectedCountry.value.code}-${controller.phoneFieldKey.value}',
          ),
          controller: _phoneController,
          label: AppStrings.passengerPhoneLabel.tr,
          hintText: PhoneNationalRules.hintForIso(
            controller.selectedCountry.value.code,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: PhoneNationalRules.inputFormattersForIso(
            controller.selectedCountry.value.code,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.only(left: 12.w, right: 2.w),
            child: PhoneCountryPickerChip(
              inline: true,
              selected: controller.selectedCountry.value,
              onChanged: controller.onCountrySelected,
            ),
          ),
          errorText: controller.phoneError.value,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

/// Nav clearance for the **choice** step when there is no footer slot.
///
/// On the details step, an empty footer + [AppAdaptiveBottomInsetLayout]
/// footer padding keeps nav clearance without toggling layout flags.
class _BookingSheetBottomPad extends StatelessWidget {
  const _BookingSheetBottomPad();

  /// Ignore small residual [MediaQuery.viewInsets] from the route under the sheet.
  static const double _keyboardOpenThreshold = 48;

  @override
  Widget build(BuildContext context) {
    if (_isKeyboardOpen(context)) {
      return const SizedBox.shrink();
    }

    final helper = BottomInsetHelper.instance;
    final double height;

    if (helper.isAndroidGestureNavigation) {
      height = BottomInsetHelper.gestureFallbackPadding +
          BottomInsetHelper.footerMinGap;
    } else if (Platform.isAndroid && helper.shouldApplyAndroidSpacingSync()) {
      height = helper.resolveAndroidThreeButtonNavInset(context) +
          BottomInsetHelper.footerMinGap;
    } else {
      height = helper.resolveFooterSafeAreaInset(context, true) +
          BottomInsetHelper.footerMinGap;
    }

    if (height <= 0) return const SizedBox.shrink();
    return SizedBox(height: height);
  }

  bool _isKeyboardOpen(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset > _keyboardOpenThreshold) return true;

    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus && keyboardInset > 0) {
      return true;
    }

    return false;
  }
}
