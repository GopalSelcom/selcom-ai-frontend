import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/app_animated_reveal.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../controllers/registration_controller.dart'
    show RegistrationController;
import '../../widgets/custom_scrollbar_widget.dart';
import 'biometric_authentication_screen.dart';
import 'passport_scan_method_screen.dart';
import 'widgets/custom_app_bar.dart';

class EnterNidaNumberScreen extends StatefulWidget {
  const EnterNidaNumberScreen({super.key});

  @override
  State<EnterNidaNumberScreen> createState() => _EnterNidaNumberScreenState();
}

class _EnterNidaNumberScreenState extends State<EnterNidaNumberScreen> {
  RegistrationController registrationController = RegistrationController();
  ValueNotifier<bool> isNidaSelected = ValueNotifier(true);
  ValueNotifier<bool> isButtonEnable = ValueNotifier(false);
  FocusNode nidaFocusNode = FocusNode();
  FocusNode passportFocusNode = FocusNode();

  void validateFields() {
    if (isNidaSelected.value) {
      isButtonEnable.value =
          registrationController.nidaNumberController.text.length == 23;
    } else {
      isButtonEnable.value =
          registrationController.passportNumberController.text.length >= 8 &&
          registrationController.passportDOBController.text.isNotEmpty &&
          registrationController.passportExpiryDateController.text.isNotEmpty;
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _openDatePicker({
    required TextEditingController targetController,
    DateTime? maxDate,
  }) async {
    final max = maxDate != null ? _dateOnly(maxDate) : null;
    var pickedDate = targetController.text.isNotEmpty
        ? DateTime.tryParse(targetController.text) ?? _dateOnly(DateTime.now())
        : _dateOnly(DateTime.now());
    pickedDate = _dateOnly(pickedDate);
    if (max != null && pickedDate.isAfter(max)) {
      pickedDate = max;
    }

    await Get.dialog<void>(
      Dialog(
        backgroundColor: AppColors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Brightness.light,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                color: AppColors.textHeading,
                fontSize: 18.sp,
              ),
            ),
          ),
          child: SizedBox(
            height: 280.h,
            child: Column(
              children: [
                SizedBox(
                  height: 220.h,
                  child: CupertinoDatePicker(
                    backgroundColor: AppColors.white,
                    mode: CupertinoDatePickerMode.date,
                    minimumYear: 1950,
                    initialDateTime: pickedDate,
                    maximumDate: max,
                    dateOrder: DatePickerDateOrder.ymd,
                    onDateTimeChanged: (DateTime value) => pickedDate = value,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    targetController.text = DateFormat(
                      'yyyy-MM-dd',
                    ).format(pickedDate);
                    registrationController.nidaNumberController.clear();
                    isNidaSelected.value = false;
                    setState(() {});
                    validateFields();
                    Get.back();
                  },
                  child: Text(
                    AppStrings.done.tr,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.walletColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    registrationController.nidaNumberController.clear();
    registrationController.passportNumberController.clear();
    registrationController.passportDOBController.clear();
    registrationController.passportExpiryDateController.clear();
    registrationController.nidaControllerListener();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Future.delayed(
        const Duration(milliseconds: 300),
      ).then((value) => nidaFocusNode.requestFocus());
    });
  }

  @override
  void dispose() {
    nidaFocusNode.unfocus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: CustomAppBar(
        title: AppStrings.enterNidaWalletActivation.tr,
        showBack: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 15.0.sp,
          right: 15.0.sp,
          bottom: 20.0.sp,
          top: 10.0.sp,
        ),
        child: Column(
          children: [
            Column(
              children: [
                Text(
                  AppStrings.enterNidaChooseIdTypeTitle.tr,
                  style: AppTextStyles.homeTitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.0.sp),
                Text(
                  AppStrings.enterNidaChooseNidaOrPassport.tr,
                  style: AppTextStyles.homeSubtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            SizedBox(height: 20.0.sp),

            Expanded(
              child: CustomScrollBar(
                // module: Module.home,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  // padding: EdgeInsets.only(top: 16.0.sp),
                  // padding: EdgeInsets.symmetric(horizontal: 15.0.sp),
                  children: [
                    nidaInputWidget(),
                    SizedBox(height: 20.0.sp),
                    passportInputWidget(),
                  ],
                ),
              ),
            ),

            ValueListenableBuilder<bool>(
              valueListenable: isButtonEnable,
              builder: (context, showContinue, _) => AppAnimatedReveal(
                show: showContinue,
                visibleKey: const ValueKey('nida-continue-visible'),
                hiddenKey: const ValueKey('nida-continue-hidden'),
                child: AppPrimaryButton(
                  label: AppStrings.continueLabel.tr,
                  backgroundColor: AppColors.walletColor,
                  onPressed: () {
                    if (isNidaSelected.value) {
                      nidaFocusNode.unfocus();
                      Get.to(() => const BiometricAuthenticationScreen());
                    } else {
                      passportFocusNode.unfocus();
                      Get.to(() => const PassportScanMethodScreen());
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget nidaInputWidget() {
    return ValueListenableBuilder(
      valueListenable: isNidaSelected,
      builder: (context, v, c) {
        return AnimatedContainer(
          duration: 300.ms,
          height: isNidaSelected.value ? null : 55.0.sp,
          padding: EdgeInsets.only(left: 15.0.sp, right: 15.0.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0.sp),
            color: AppColors.white,
          ),
          child: ListView(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  isNidaSelected.value = true;
                  validateFields();
                },
                child: Container(
                  height: 55.0.sp,
                  decoration: const BoxDecoration(color: AppColors.white),
                  child: Row(
                    children: [
                      Icon(
                        isNidaSelected.value
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isNidaSelected.value
                            ? AppColors.walletColor
                            : AppColors.lightGreyTextColor,
                      ),
                      SizedBox(width: 15.0.sp),
                      Text(
                        AppStrings.walletLinkNida.tr,
                        style: AppTextStyles.homeTitle.copyWith(
                          color: isNidaSelected.value
                              ? null
                              : AppColors.lightGreyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 0,
                color: AppColors.lightGreyTextColor.withOpacity(0.3),
                thickness: 1,
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0.sp, bottom: 20.0.sp),
                child: Text(
                  AppStrings.enterNidaRegistrationHint.tr,
                  style: AppTextStyles.homeCaption.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(top: 10.0.sp, bottom: 15.0.sp),
                child: AppTextField(
                  focusNode: nidaFocusNode,
                  maxLength: 23,
                  textColor: AppColors.blackColor,
                  label: AppStrings.walletLinkNidaFieldHint.tr,
                  hintText: AppStrings.walletLinkNidaMaskHint.tr,
                  controller: registrationController.nidaNumberController,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  onChanged: (value) {
                    registrationController.passportNumberController.clear();
                    registrationController.passportDOBController.clear();
                    registrationController.passportExpiryDateController.clear();
                    isNidaSelected.value = true;
                    validateFields();
                  },
                  inputFormatters: [
                    MaskTextInputFormatter(
                      mask: "########-#####-#####-##",
                      filter: {"#": RegExp(r'[0-9]')},
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget passportInputWidget() {
    return ValueListenableBuilder(
      valueListenable: isNidaSelected,
      builder: (context, v, c) {
        return AnimatedContainer(
          duration: 300.ms,
          height: isNidaSelected.value ? 55.0.sp : null,
          padding: EdgeInsets.only(left: 15.0.sp, right: 15.0.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0.sp),
            color: AppColors.white,
          ),
          child: ListView(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  isNidaSelected.value = false;
                  validateFields();
                },
                child: Container(
                  height: 55.0.sp,
                  decoration: const BoxDecoration(color: AppColors.white),
                  child: Row(
                    children: [
                      Icon(
                        !isNidaSelected.value
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: !isNidaSelected.value
                            ? AppColors.walletColor
                            : AppColors.lightGreyTextColor,
                      ),
                      SizedBox(width: 15.0.sp),
                      Text(
                        AppStrings.walletLinkPassport.tr,
                        style: AppTextStyles.homeTitle.copyWith(
                          color: !isNidaSelected.value
                              ? null
                              : AppColors.lightGreyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 0,
                color: AppColors.lightGreyTextColor.withOpacity(0.3),
                thickness: 1,
              ),
              SizedBox(height: 10.0.sp),
              Text(
                AppStrings.walletLinkPassportDetailsHint.tr,
                style: AppTextStyles.homeCaption.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.0.sp),

              AppTextField(
                focusNode: passportFocusNode,
                maxLength: 11,
                textColor: AppColors.blackColor,
                label: AppStrings.walletLinkPassportNumberHint.tr,
                hintText: AppStrings.walletLinkPassportMaskHint.tr,
                controller: registrationController.passportNumberController,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  registrationController.nidaNumberController.clear();
                  isNidaSelected.value = false;
                  validateFields();
                },
                inputFormatters: [
                  MaskTextInputFormatter(
                    mask: "AAA AAA AAA",
                    filter: {"A": RegExp(r'[a-zA-Z0-9]')},
                  ),
                ],
              ),
              SizedBox(height: 20.0.sp),
              Padding(
                padding: EdgeInsets.only(right: 8.0.sp),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.enterNidaBirthDate.tr,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.textMutedStrong,
                              fontWeight: FontWeight.w500,
                              fontSize: 15.h,
                            ),
                          ),
                          SizedBox(height: 5.0.sp),
                          GestureDetector(
                            onTap: () async {
                              nidaFocusNode.unfocus();
                              passportFocusNode.unfocus();
                              await _openDatePicker(
                                targetController: registrationController
                                    .passportDOBController,
                                maxDate: DateTime.now(),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: AbsorbPointer(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: registrationController
                                    .passportDOBController,
                                builder: (context, _, __) => AppTextField(
                                  readOnly: true,
                                  fontSize: 12.sp,
                                  textColor: AppColors.textHeading,
                                  textFieldBackgroundColor: AppColors.white,
                                  controller: registrationController
                                      .passportDOBController,
                                  hintText: AppStrings.walletLinkDatePlaceholder.tr,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.0.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.enterNidaExpirationDate.tr,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.textMutedStrong,
                              fontWeight: FontWeight.w500,
                              fontSize: 15.h,
                            ),
                          ),
                          SizedBox(height: 5.0.sp),
                          GestureDetector(
                            onTap: () async {
                              nidaFocusNode.unfocus();
                              passportFocusNode.unfocus();
                              await _openDatePicker(
                                targetController: registrationController
                                    .passportExpiryDateController,
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: AbsorbPointer(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: registrationController
                                    .passportExpiryDateController,
                                builder: (context, _, __) => AppTextField(
                                  readOnly: true,
                                  fontSize: 12.sp,
                                  textColor: AppColors.textHeading,
                                  textFieldBackgroundColor: AppColors.white,
                                  controller: registrationController
                                      .passportExpiryDateController,
                                  hintText: AppStrings.walletLinkDatePlaceholder.tr,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15.0.sp),
            ],
          ),
        );
      },
    );
  }
}
