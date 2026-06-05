import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:selcom_passport_plugin/selcom_passport_plugin.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../controllers/registration_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/common_button.dart';
import 'test/passport_scanning_data.dart';
import 'widgets/custom_app_bar.dart';

class PassportAuthenticationScreen extends StatefulWidget {
  const PassportAuthenticationScreen({super.key});

  @override
  State<PassportAuthenticationScreen> createState() =>
      _PassportAuthenticationScreenState();
}

class _PassportAuthenticationScreenState
    extends State<PassportAuthenticationScreen> {
  RegistrationController registrationController = RegistrationController();
  WalletController walletController = WalletController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.boxGray,
      appBar: CustomAppBar(
        title: "Passport Scanning",
        // leadingIcon: Images.IC_BACK,
        // onTapLeading: appNavigator.pop
        showBack: true,
      ),
      body: Container(
        width: Get.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Lottie.asset(
              Lotties.passportScanning,
              height: Get.height * 0.28,
              frameRate: FrameRate.max, // Smoothest frame rate
              repeat: true,
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 30.0.sp),
                // mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Instructions to scan your passport",
                    style: AppTextStyles.screenTitle.copyWith(
                      color: AppColors.blackColor,
                      fontSize: 20.0.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.0.sp),
                  ListView(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      Text(
                        "1. To proceed, please ensure that NFC is enabled on your phone. To enable it, go to Settings > Connections > NFC and switch it on.",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey595959,
                          fontSize: 14.0.sp,
                        ),
                      ),
                      SizedBox(height: 10.0.sp),
                      Text(
                        "2. Place your mobile phone on top of the front cover of your passport, then hover your phone up and down until the passport is detected.",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey595959,
                          fontSize: 14.0.sp,
                        ),
                      ),
                      SizedBox(height: 10.0.sp),
                      Text(
                        "3. Hold still until passport reading is completed and scanned successfully.",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey595959,
                          fontSize: 14.0.sp,
                        ),
                      ),
                      SizedBox(height: 10.0.sp),
                      Text(
                        "4. Once your passport details appear on the screen, click 'Confirm' to continue with registration.",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey595959,
                          fontSize: 14.0.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(15.0.sp),
              child: CommonButton(
                label: "Proceed",
                onTap: () async {
                  bool testIt = walletController.isTestingMode.value;

                  if (testIt) {
                    registrationController.processPassportResult(
                      result: nfcPassportData,
                    );
                  } else {
                    final result = await SelcomPassportPlugin().readPassport(
                      documentNumber: registrationController
                          .passportNumberController
                          .text
                          .replaceAll(" ", ""),
                      dateOfBirth: DateFormat('yyMMdd').format(
                        DateFormat('yyyy-MM-dd').parse(
                          registrationController.passportDOBController.text,
                        ),
                      ),
                      dateOfExpiry: DateFormat('yyMMdd').format(
                        DateFormat('yyyy-MM-dd').parse(
                          registrationController
                              .passportExpiryDateController
                              .text,
                        ),
                      ),
                      languageCode: "en",
                    );
                    registrationController.processPassportResult(
                      result: result,
                    );
                  }
                },
                enabledColor: AppColors.walletColor,
                isEnabled: true,
              ),

              /* OutlineBorderButtonView(
                fontSize: 15.0.h,
                Languages.of(context).(Labels.proceed),
                fontFamily: FontName.NunitoSansBold,
                color: AppColors.whiteColor,
                backgroundColor: AppColors.loaderColor,
                onPressed: () async {

                },
              )*/
            ),
          ],
        ),
      ),
    );
  }
}
