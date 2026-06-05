import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';


import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/localization/languages/languages.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../controllers/registration_controller.dart';
import '../../utils/numeric_formatter.dart';
import '../../widgets/common_button.dart';
import '../../widgets/custom_scrollbar_widget.dart';
import 'widgets/common_input_field.dart';
import 'widgets/custom_app_bar.dart';

class PassportScanConfirmationScreen extends StatefulWidget {
  const PassportScanConfirmationScreen({super.key});

  @override
  State<PassportScanConfirmationScreen> createState() =>
      _PassportScanConfirmationScreenState();
}

class _PassportScanConfirmationScreenState
    extends State<PassportScanConfirmationScreen> {
  RegistrationController registrationController = RegistrationController();
  ValueNotifier<bool> isButtonEnable = ValueNotifier(false);

  void validateFields() {
    final isCityValid =
        registrationController.passportFieldCityController.text.trim().length >
        2;
    final isAddressValid =
        registrationController.passportFieldAddressController.text
            .trim()
            .length >
        2;

    if (isCityValid && isAddressValid) {
      isButtonEnable.value = true;
    } else {
      isButtonEnable.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      registrationController.passportFieldCityController.clear();
      registrationController.passportFieldAddressController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.boxGray,
      appBar: const CustomAppBar(
        title: "Document Confirmation",
        // leadingIcon: Images.IC_BACK,
        // onTapLeading: appNavigator.pop
        showBack: true,
      ),
      body: Obx(
        () => Column(
          children: <Widget>[
            SizedBox(height: 13.0.sp),
            Container(
              width: 150.0.sp,
              height: 160.0.sp,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Image.file(
                File(registrationController.nfcPassportImage?.path ?? ""),
                height: 160.0.sp,
                width: 150.0.sp,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset(AppAssets.placeHolder, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 16.0.sp),
            Expanded(
              child: CustomScrollBar(
                // module: Module.home,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.0.sp),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0.sp),
                  ),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0.sp,
                      vertical: 16.0.sp,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      passportField(
                        context: context,
                        label:"First Name",
                        value:
                            registrationController
                                .passportScanningData
                                .value
                                .data
                                ?.name ??
                            "",
                      ),
                      passportField(
                        context: context,
                        label: "Last Name",
                        value:
                            registrationController
                                .passportScanningData
                                .value
                                .data
                                ?.surname ??
                            "",
                      ),
                      passportField(
                        context: context,
                        label: "Passport Number",
                        value:
                            registrationController
                                .passportScanningData
                                .value
                                .data
                                ?.documentNumber ??
                            "",
                      ),
                      passportField(
                        context: context,
                        label: "Nationality",
                        value:
                            registrationController
                                .passportScanningData
                                .value
                                .data
                                ?.nationality ??
                            "",
                      ),
                      passportField(
                        context: context,
                        label:"Place of Birth",
                        value:
                            registrationController
                                .passportScanningData
                                .value
                                .data
                                ?.placeOfBirth
                                ?.trim() ??
                            "",
                      ),
                      passportField(
                        context: context,
                        label: "Birth Date",
                        value: registrationController.yyMMddDateParser(
                          date:
                              registrationController
                                  .passportScanningData
                                  .value
                                  .data
                                  ?.dob
                                  ?.trim() ??
                              "",
                        ),
                      ),
                      passportField(
                        context: context,
                        label: "Expiration Date",
                        value: registrationController.yyMMddDateParser(
                          date:
                              registrationController
                                  .passportScanningData
                                  .value
                                  .data
                                  ?.dateOfExpiry
                                  ?.trim() ??
                              "",
                        ),
                      ),
                      passportField(
                        context: context,
                        label: "Gender",
                        value:
                            registrationController
                                .passportScanningData
                                .value
                                .data
                                ?.gender ??
                            "",
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 15.0.sp),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "City",
                                    style: AppTextStyles.screenTitle.copyWith(
                                      color: AppColors
                                          .lightThemeLightGreyTextColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "*",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 13.0.sp,
                                          // fontFamily: FontName.NunitoSansRegular,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.0.sp),
                            Container(
                              alignment: Alignment.centerLeft,
                              width: Get.width,
                              // height: 50.0.sp,
                              // decoration: BoxDecoration(
                              //   color: AppColors.textGreyF3F3F3,
                              //   borderRadius: BorderRadius.circular(10.0.sp),
                              // ),
                              child: CommonInputField(
                                // maxLength: 500,
                                // autofocus: false,
                                // isBorderEnable: false,
                                // filled: false,
                                // fillColor: AppColors.lightThemeSecondaryColor,
                                hintColor:
                                    AppColors.lightThemeLightGreyTextColor,
                                textColor: AppColors.blackColor,
                                hintText: "Please enter your city",
                                controller: registrationController
                                    .passportFieldCityController,
                                onChange: (value) {
                                  validateFields();
                                },
                                inputFormatters: [AllCapsTextFormatter()],
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.streetAddress,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 15.0.sp),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Address",
                                    style: AppTextStyles.screenTitle.copyWith(
                                      color: AppColors
                                          .lightThemeLightGreyTextColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "*",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 13.0.sp,
                                          // fontFamily: FontName.NunitoSansRegular,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.0.sp),
                            Container(
                              alignment: Alignment.centerLeft,
                              width: Get.width,
                              // height: 50.0.sp,
                              // decoration: BoxDecoration(
                              //   color: AppColors.textGreyF3F3F3,
                              //   borderRadius: BorderRadius.circular(10.0.sp),
                              // ),
                              child: CommonInputField(
                                maxLength: 500,
                                // autofocus: false,
                                // isBorderEnable: false,
                                // filled: false,
                                // fillColor: AppColors.lightThemeSecondaryColor,
                                hintColor:
                                    AppColors.lightThemeLightGreyTextColor,
                                textColor: AppColors.blackColor,
                                hintText: "Enter address",
                                controller: registrationController
                                    .passportFieldAddressController,
                                textInputAction: TextInputAction.done,
                                onChange: (value) {
                                  validateFields();
                                },
                                inputFormatters: [AllCapsTextFormatter()],
                                keyboardType: TextInputType.streetAddress,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.sp),
              child: ValueListenableBuilder<bool>(
                valueListenable: isButtonEnable,
                builder: (context, enabled, _) => CommonButton(
                  label: Languages.of(context).confirm,
                  onTap: () async {
                    await registrationController.uploadNFCPasportData();
                  },
                  enabledColor: enabled
                      ? AppColors.walletColor
                      : AppColors.textGrey,
                  isEnabled: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget passportField({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.0.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.lightThemeLightGreyTextColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.0.sp),
          Container(
            alignment: Alignment.centerLeft,
            width: Get.width,
            height: 50.0.sp,
            padding: EdgeInsets.symmetric(horizontal: 15.0.sp),
            decoration: BoxDecoration(
              color: AppColors.textGrey,
              borderRadius: BorderRadius.circular(12.0.sp),
            ),
            child: Text(
              value,
              style: AppTextStyles.screenTitle.copyWith(color: AppColors.black, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
