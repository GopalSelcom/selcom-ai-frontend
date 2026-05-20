import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_animated_reveal.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/utils/tanzania_phone_validation.dart';
import '../controllers/confirm_pickup_controller.dart';

enum BookingFlowStep { choice, details }

class BookingForSomeoneElseFlowBottomSheet extends StatefulWidget {
  const BookingForSomeoneElseFlowBottomSheet({super.key});

  @override
  State<BookingForSomeoneElseFlowBottomSheet> createState() =>
      _BookingForSomeoneElseFlowBottomSheetState();
}

class _BookingForSomeoneElseFlowBottomSheetState
    extends State<BookingForSomeoneElseFlowBottomSheet> {
  BookingFlowStep _currentStep = BookingFlowStep.choice;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onFieldsChanged);
    _phone.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });
  }

  bool get _canConfirm =>
      _name.text.trim().isNotEmpty &&
      TanzaniaPhoneValidation.isCompleteValid(_phone.text);

  @override
  void dispose() {
    _name.removeListener(_onFieldsChanged);
    _phone.removeListener(_onFieldsChanged);
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep == BookingFlowStep.details) {
      setState(() {
        _currentStep = BookingFlowStep.choice;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomReserve = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom
        : mq.padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, bottomReserve + 24.h),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
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
            child: _currentStep == BookingFlowStep.choice
                ? _buildChoiceStep()
                : _buildDetailsStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceStep() {
    return Column(
      key: const ValueKey(BookingFlowStep.choice),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.bookingForSomeoneElsePrompt.tr,
          textAlign: TextAlign.start,
          style: AppTextStyles.homeTitle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            color: AppColors.textHeading,
            height: 20 / 18,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          AppStrings.bookingForSomeoneElseSubtitle.tr,
          textAlign: TextAlign.start,
          style: AppTextStyles.homeCaption.copyWith(
            color: AppColors.textBody,
            fontSize: 12.sp,
            height: 20 / 12,
          ),
        ),
        SizedBox(height: 20.h),
        _bookingChoiceRow(
          icon: Iconsax.user,
          title: AppStrings.bookingRideOptionForMe.tr,
          onTap: () {
            Navigator.of(context).pop({
              'mode': BookingMode.self,
            });
          },
        ),
        SizedBox(height: 12.h),
        _bookingChoiceRow(
          icon: Iconsax.user_add,
          title: AppStrings.bookingRideOptionForSomeoneElse.tr,
          onTap: () {
            setState(() {
              _currentStep = BookingFlowStep.details;
            });
          },
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      key: const ValueKey(BookingFlowStep.details),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back, color: AppColors.textHeading),
              onPressed: _goBack,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                AppStrings.passengerDetailsTitle.tr,
                textAlign: TextAlign.start,
                style: AppTextStyles.homeTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: AppColors.textHeading,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          AppStrings.notificationPhoneSubtitle.tr,
          textAlign: TextAlign.start,
          style: AppTextStyles.homeCaption.copyWith(
            color: AppColors.textBody,
            fontSize: 14.sp,
            height: 1.35,
          ),
        ),
        SizedBox(height: 20.h),
        AppTextField(
          controller: _name,
          label: AppStrings.passengerNameLabel.tr,
          hintText: AppStrings.enterPassengerFullName.tr,
          keyboardType: TextInputType.name,
          errorText: _nameError,
          onChanged: (_) {},
        ),
        SizedBox(height: 16.h),
        AppTextField(
          controller: _phone,
          label: AppStrings.passengerPhoneLabel.tr,
          hintText: PhoneNationalRules.hintForIso(
            TanzaniaPhoneValidation.iso2,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: PhoneNationalRules.inputFormattersForIso(
            TanzaniaPhoneValidation.iso2,
          ),
          prefixIcon: Container(
            width: 82.w,
            padding: EdgeInsets.only(left: 14.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: SvgPictureAsset(
                    AppAssets.icTanzaniaFlag,
                    height: 14.h,
                    width: 22.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '+255',
                  style: AppTextStyles.homeSubtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
          errorText: _phoneError,
          onChanged: (_) {},
        ),
        AppAnimatedReveal(
          show: _canConfirm,
          visibleKey: const ValueKey('passenger_details_confirm_on'),
          hiddenKey: const ValueKey('passenger_details_confirm_off'),
          child: Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: AppPrimaryButton(
              label: AppStrings.confirm.tr,
              onPressed: _onConfirmPressed,
            ),
          ),
        ),
      ],
    );
  }

  void _onConfirmPressed() {
    final trimmedName = _name.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _nameError = AppStrings.nameIsRequired.tr;
      });
      return;
    }

    final e164 = TanzaniaPhoneValidation.e164DigitsOrNull(_phone.text);
    if (e164 == null) {
      setState(() {
        _phoneError = _phone.text.trim().isEmpty
            ? AppStrings.notificationPhoneRequired.tr
            : AppStrings.pleaseEnterAValidPhoneNumber.tr;
      });
      return;
    }

    Navigator.of(context).pop({
      'mode': BookingMode.other,
      'name': trimmedName,
      'phone': e164,
    });
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
