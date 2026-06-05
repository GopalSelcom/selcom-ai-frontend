import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../controllers/registration_controller.dart' show RegistrationController;
import '../../widgets/common_button.dart';
import '../../widgets/custom_scrollbar_widget.dart';
import 'biometric_authentication_screen.dart';
import 'passport_authentication_screen.dart';
import 'widgets/common_input_field.dart';
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
    if (isNidaSelected.value &&
        registrationController.nidaNumberController.value.text.length == 23) {
      isButtonEnable.value = true;
    } else if (registrationController
            .passportNumberController
            .text
            .isNotEmpty &&
        registrationController.passportNumberController.text.length >= 8 &&
        registrationController.passportDOBController.text.isNotEmpty &&
        registrationController.passportExpiryDateController.text.isNotEmpty) {
      isButtonEnable.value = true;
    } else {
      isButtonEnable.value = false;
    }
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
      backgroundColor: AppColors.boxGray,
      appBar: CustomAppBar(
        title:"Wallet Activation",
        showBack: true,
        // leadingIcon: CommonImages.IC_BACK,
        // onTapLeading: appNavigator.pop
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
        "Choose ID type for registration",
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 20.0.sp, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.0.sp),
                Text(
                  "Choose NIDA or Passport",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textGrayAskleois,
                    fontSize: 13.0.sp,
                  ),
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

            Padding(
              padding: EdgeInsets.all(0.0.sp),
              child: ValueListenableBuilder(
                valueListenable: isButtonEnable,
                builder: (context, enabled, child) => CommonButton(
                  label: "Continue",
                  onTap: enabled
                      ? () async {
                          if (isNidaSelected.value) {
                            nidaFocusNode.unfocus();
                            Get.to(()=>BiometricAuthenticationScreen());
                          } else {
                            passportFocusNode.unfocus();
                            Get.to(()=>PassportAuthenticationScreen());
                          }
                        }
                      : () {},
                  enabledColor: AppColors.walletColor,
                  isEnabled: enabled,
                ) /*OutlineBorderButtonView(
                  fontSize: 15.0.sp,
                  translate(Labels.Continue),
                  fontFamily: FontName.NunitoSansBold,
                  color: AppColors.whiteColor,
                  backgroundColor: enabled
                      ? AppColors.loaderColor
                      : AppColors.textGrey,
                  onPressed: enabled
                      ? () async {
                          if (isNidaSelected.value) {
                            nidaFocusNode.unfocus();
                            appNavigator.to(() => BiometricAuthenticationScreen());
                          } else {
                            passportFocusNode.unfocus();
                            appNavigator.to(() => PassportAuthenticationScreen());
                          }
                        }
                      : () {},
                )*/,
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
                },
                child: Container(
                  height: 55.0.sp,
                  decoration: BoxDecoration(color: AppColors.white),
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
                        "NIDA",
                        style: AppTextStyles.screenTitle.copyWith(
                          height: 1.3,
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
                  "Please enter your nida card number for further registration process",
                  style: AppTextStyles.screenTitle.copyWith(
                    //     color: AppColors
                    //         .lightThemeLightGreyTextColor,
                    //     height: 1.3,
                    // fontSize: 12.0.sp
                    color: AppColors.lightThemeLightGreyTextColor,
                    fontSize: 13.0.sp,
                  ),
                ),
              ),
              Text(
                "Enter NIDA card number",
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.lightThemeLightGreyTextColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0.sp, bottom: 15.0.sp),
                child: CommonInputField(
                  focusNode: nidaFocusNode,
                  maxLength: 23,
                  hintColor: AppColors.lightThemeLightGreyTextColor,
                  textColor: AppColors.blackColor,
                  hintText: "Enter NIDA card number",
                  controller: registrationController.nidaNumberController,
                  textInputAction: TextInputAction.done,

                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  onChange: (value) {
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
                },
                child: Container(
                  height: 55.0.sp,
                  decoration: BoxDecoration(color: AppColors.white),
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
                       "Passport",
                        style: AppTextStyles.screenTitle.copyWith(
                          height: 1.3,
                          color: !isNidaSelected.value
                              ? null
                              : AppColors.lightGreyTextColor,
                        ),
                        /*  style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: !isNidaSelected.value
                                                  ? null
                                                  : AppColors
                                                        .lightGreyTextColor,
                                            )*/
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
                "Enter your passport details to proceed",
                style: AppTextStyles.screenTitle.copyWith(
                  //     color: AppColors
                  //         .lightThemeLightGreyTextColor,
                  //     height: 1.3,
                  // fontSize: 12.0.sp
                  color: AppColors.lightThemeLightGreyTextColor,
                  fontSize: 13.0.sp,
                ),
              ),
              SizedBox(height: 20.0.sp),
              Text(
                "Enter passport number",
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.lightThemeLightGreyTextColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10.0.sp),

              CommonInputField(
                focusNode: passportFocusNode,
                maxLength: 11,
                // autofocus: false,
                // isBorderEnable: false,
                // filled: true,
                // fillColor: AppColors.lightThemeSecondaryColor,
                hintColor: AppColors.lightThemeLightGreyTextColor,
                textColor: AppColors.blackColor,
                hintText:"Enter passport number",
                controller: registrationController.passportNumberController,
                textInputAction: TextInputAction.done,

                onTap: () {
                  nidaFocusNode.unfocus();
                  passportFocusNode.requestFocus();
                },
                onChange: (value) {
                  registrationController.nidaNumberController.clear();
                  isNidaSelected.value = false;
                  validateFields();
                },
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  MaskTextInputFormatter(
                    mask: "AAA AAA AAA",
                    filter: {"A": RegExp(r'[a-zA-Z0-9]')},
                  ),
                ],
              ),
              SizedBox(height: 20.0.sp),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Birth date",
                          style: AppTextStyles.screenTitle.copyWith(
                            color: AppColors.lightThemeLightGreyTextColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5.0.sp),
                        CommonInputField(
                          onTap: () async {
                            nidaFocusNode.unfocus();
                            passportFocusNode.unfocus();
                            await Get.dialog(
                              Dialog(
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          8.0.sp,
                                        ),
                                      ),
                                      height: Get.width * 0.5,
                                      width: Get.height * 0.9,
                                      child: CupertinoDatePicker(
                                        backgroundColor:
                                            AppColors.lightThemeSecondaryColor,
                                        mode: CupertinoDatePickerMode.date,
                                        minimumYear: 1950,
                                        initialDateTime: DateTime.now(),
                                        dateOrder: DatePickerDateOrder.ymd,
                                        maximumDate: DateTime.now(),
                                        maximumYear: DateTime.now().year,
                                        onDateTimeChanged: (DateTime newDate) {
                                          registrationController
                                              .passportDOBController
                                              .text = DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(newDate).toString();
                                          registrationController
                                              .nidaNumberController
                                              .clear();
                                          isNidaSelected.value = false;

                                          validateFields();
                                        },
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fade(
                                    duration: 400.ms,
                                    curve: Curves.fastOutSlowIn,
                                  )
                                  .scale(
                                    duration: 400.ms,
                                    curve: Curves.fastOutSlowIn,
                                  ),
                            );
                          },
                          onChange: (value) {
                            registrationController.nidaNumberController.clear();
                            isNidaSelected.value = false;

                            validateFields();
                          },
                          hintColor: AppColors.lightThemeLightGreyTextColor,
                          textColor: AppColors.blackColor,
                          enable: false,
                          keyboardType: TextInputType.none,
                          controller:
                              registrationController.passportDOBController,
                          // isBorderEnable: false,
                          // filled: true,
                          // fillColor: AppColors
                          //     .lightThemeSecondaryColor,
                          hintText: "YYYY-MM-DD",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20.0.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                    "Expiration date",
                          style: AppTextStyles.screenTitle.copyWith(
                            color: AppColors.lightThemeLightGreyTextColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5.0.sp),
                        CommonInputField(
                          onTap: () async {
                            nidaFocusNode.unfocus();
                            passportFocusNode.unfocus();
                            await Get.dialog(
                              Dialog(
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          8.0.sp,
                                        ),
                                      ),
                                      height: Get.width * 0.5,
                                      width: Get.height * 0.9,
                                      child: CupertinoDatePicker(
                                        backgroundColor:
                                            AppColors.lightThemeSecondaryColor,
                                        mode: CupertinoDatePickerMode.date,
                                        minimumYear: 1950,
                                        initialDateTime: DateTime.now(),
                                        dateOrder: DatePickerDateOrder.ymd,
                                        onDateTimeChanged: (DateTime newDate) {
                                          registrationController
                                              .passportExpiryDateController
                                              .text = DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(newDate).toString();
                                          registrationController
                                              .nidaNumberController
                                              .clear();
                                          isNidaSelected.value = false;

                                          validateFields();
                                        },
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fade(
                                    duration: 400.ms,
                                    curve: Curves.fastOutSlowIn,
                                  )
                                  .scale(
                                    duration: 400.ms,
                                    curve: Curves.fastOutSlowIn,
                                  ),
                            );
                          },
                          onChange: (value) {
                            registrationController.nidaNumberController.clear();
                            isNidaSelected.value = false;
                            validateFields();
                          },
                          hintColor: AppColors.lightThemeLightGreyTextColor,
                          textColor: AppColors.blackColor,
                          enable: false,
                          keyboardType: TextInputType.none,
                          controller: registrationController
                              .passportExpiryDateController,
                          // isBorderEnable: false,
                          // filled: true,
                          // fillColor: AppColors
                          //     .lightThemeSecondaryColor,
                          hintText: "YYYY-MM-DD",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.0.sp),
            ],
          ),
        );
      },
    );
  }
}
