import 'dart:io';


import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';
import 'package:selcom_rides_frontend/shared/widgets/app_primary_button.dart';

// import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';
import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/localization/languages/languages.dart';
import '../../../../../shared/widgets/app_profile_header.dart';
import '../../controllers/registration_controller.dart';
import 'hand_selection_screen.dart';
import 'widgets/custom_app_bar.dart';

class BiometricAuthenticationScreen extends StatefulWidget {
  const BiometricAuthenticationScreen({super.key});

  @override
  State<BiometricAuthenticationScreen> createState() =>
      _BiometricAuthenticationScreenState();
}

class _BiometricAuthenticationScreenState
    extends State<BiometricAuthenticationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  RegistrationController registrationController = RegistrationController();
  SelcomIdentyPlugin selcomIdentyPlugin = SelcomIdentyPlugin();

  Future<void> getDeviceName() async {
    final _ios = await DeviceInfoPlugin().iosInfo;
    var tempString = _ios.utsname.machine.split(",");
    RegistrationController().deviceName.value = tempString.first ?? "";
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      getDeviceName();

      selcomIdentyPlugin.options.licenseFile =
          registrationController.getIdentyLicense;
      selcomIdentyPlugin.options.leftHandSelected = true;
      selcomIdentyPlugin.options.rightHandSelected = false;
      selcomIdentyPlugin.options.isLeftMissingFingerSelected = false;
      selcomIdentyPlugin.options.isRightMissingFingerSelected = false;
      selcomIdentyPlugin.options.leftHandMissingArray = [];
      selcomIdentyPlugin.options.rightHandMissingArray = [];
      debugPrint(
        "selcomIdentyPlugin.options.licenseFile: ${selcomIdentyPlugin.options.licenseFile}",
      );
      // devLog("selcomIdentyPlugin package name: ${AppInfo().package.packageName}");

      registrationController.isLeftHandSelected.value = true;

      registrationController.isRightHandSelected.value = false;

      registrationController.isIndexFingerMissing.value = false;
      registrationController.isMiddleFingerMissing.value = false;
      registrationController.isRingFingerMissing.value = false;
      registrationController.isLittleFingerMissing.value = false;

      registrationController.flashStatus.value = true;
      if (Platform.isAndroid) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
        );
      } else {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: CustomAppBar(
        title:AppStrings.wallet.tr,
        showBack: true,

        // leadingIcon: Images.IC_BACK,
        // onTapLeading: appNavigator.pop
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 15.0.sp),
        child: Column(
          children: [
            // AppProfileHeader(
            //   title: AppStrings.wallet.tr,
            // ),
            Lottie.asset(
              Lotties.fingerScan,
              height: Get.height * 0.28,
              controller: _controller,
              frameRate: FrameRate.max, // Smoothest frame rate
              onLoaded: (composition) {
                _controller
                  ..duration =
                      composition.duration *
                      2 // Half speed
                  ..forward()
                  ..repeat(); // Smooth looping
              },
            ),
            SizedBox(height: 30.0.sp),
            SizedBox(
              width: Get.width * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                   "Instructions to scan your fingerprints.",
                    maxLines: 2,
                    style: AppTextStyles.screenTitle.copyWith(
                      color: AppColors.black,
                      fontSize: 20.0.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.0.sp),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                       "1. Place your hand on a flat surface in a well-lit environment.",
                        maxLines: 2,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 14.0.sp,
                        )
                      ),
                      const SizedBox(height: 10),
                      Text(
                          "2. Keep your hand still during the scan.",
                        maxLines: 2,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 14.0.sp,
                        )
                      ),
                      const SizedBox(height: 10),
                      Text(
                          "3. Make minor adjustments in case the camera cannot focus",
                        maxLines: 2,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 14.0.sp,
                        )
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "4. Wait for the scanner to take the picture automatically",
                        maxLines: 2,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 14.0.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: AppPrimaryButton(
                label: Languages.of(context).continueLabel,

                onPressed: () async {
                  Get.to(()=>BiometricsSelectionScree());
                },

                // enabledColor: AppColors.walletColor,
                // isEnabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
