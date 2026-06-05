import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';
import 'package:selcom_rides_frontend/shared/widgets/app_standard_bottom_sheet.dart';
// import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';


import '../../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../../core/services/progress_indicator/loader.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../controllers/registration_controller.dart';
import 'missing_finger_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/finger_scan_instruction_sheet.dart';

class BiometricsSelectionScree extends StatefulWidget {
  const BiometricsSelectionScree({super.key});

  @override
  State<BiometricsSelectionScree> createState() =>
      _BiometricsSelectionScreeState();
}

class _BiometricsSelectionScreeState extends State<BiometricsSelectionScree> {
  RegistrationController registrationController = RegistrationController();

  SelcomIdentyPlugin selcomIdentyPlugin = SelcomIdentyPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.boxGray,
      appBar:const CustomAppBar(
        title: "Biometric Authentication",
        showBack: true,
        // leadingIcon: CommonImages.IC_BACK,
        // onTapLeading: appNavigator.pop
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 13.0.sp),
          Obx(
            () => GestureDetector(
              onTap: () {
                registrationController.resetMissingFingers();

                // left hand
                selcomIdentyPlugin.options.leftHandSelected = true;
                selcomIdentyPlugin.options.rightHandSelected = false;
                registrationController.isLeftHandSelected.value = true;

                // right hand
                registrationController.isRightHandSelected.value = false;
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 28.0.sp),
                    child: CircleAvatar(
                      backgroundColor:
                          registrationController.isLeftHandSelected.value
                          ? AppColors.greenColor
                          : AppColors.textGrey,
                      radius: 15,
                      child: Icon(
                        Icons.check,
                        color: registrationController.isLeftHandSelected.value
                            ? AppColors.whiteColor
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0.sp),
                  Column(
                    children: [
                      Text(
                        "Left Hand",
                        style: AppTextStyles.screenTitle.copyWith(
                          color: AppColors.textGrey,
                          // fontFamily: FontName.NunitoSansRegular,
                          fontSize: 15.0.sp,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10.0.sp),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0.sp),
                          color: registrationController.isLeftHandSelected.value
                              ? AppColors.lightGreenColor
                              : AppColors.textGrey,
                          border: Border.all(
                            color:
                                registrationController.isLeftHandSelected.value
                                ? AppColors.greenColor
                                : AppColors.textGrey,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Image.asset(
                            AppAssets.walletLinkLeftHand,
                            height: Get.height * 0.25,
                            width: Get.width * 0.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => GestureDetector(
              onTap: () {
                registrationController.resetMissingFingers();

                selcomIdentyPlugin.options.leftHandSelected = false;
                selcomIdentyPlugin.options.rightHandSelected = true;
                registrationController.isLeftHandSelected.value = false;
                registrationController.isRightHandSelected.value = true;
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 28.0.sp),
                    child: CircleAvatar(
                      backgroundColor:
                          registrationController.isRightHandSelected.value
                          ? AppColors.greenColor
                          : AppColors.textGrey,
                      radius: 15,
                      child: Icon(
                        Icons.check,
                        color: registrationController.isRightHandSelected.value
                            ? AppColors.whiteColor
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0.sp),
                  Column(
                    children: [
                      Text(
                        "Right Hand",
                        style: AppTextStyles.screenTitle.copyWith(
                          color: AppColors.textGrey,
                          // fontFamily: FontName.NunitoSansRegular,
                          fontSize: 15.0.sp,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10.0.sp),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0.sp),
                          color:
                              registrationController.isRightHandSelected.value
                              ? AppColors.lightGreenColor
                              : AppColors.textGrey,
                          border: Border.all(
                            color:
                                registrationController.isRightHandSelected.value
                                ? AppColors.greenColor
                                : AppColors.textGrey,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Image.asset(
                            AppAssets.walletLinkRightHand,
                            height: Get.height * 0.25,
                            width: Get.width * 0.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(15.0.sp, 0, 15.0.sp, 15.0.sp),
            child: Column(
              children: [
                CommonButton(
                  label:"Continue",
                  bottomSpace: 10.0.sp,
                  onTap: () async {
                    registrationController.resetMissingFingers();

                    // showLoaderDialog(context);
                    Loader.instance.show();
                    debugPrint("showLoaderDialog", );
                    Position? position;
                    try {
                      debugPrint("position getting started", );
                      position = await LocationService.instance
                          .getCurrentPosition(force: true, precise: true);
                      debugPrint("position getting ended", );
                    } catch (e, stackTrace) {
                      ErrorReporter.instance.report(
                        error: e,
                        stackTrace: stackTrace,
                      );
                      debugPrint("location getting exception: $e");
                    }
                    debugPrint("before hide loader", );
                    // hideLoaderDialog();
                    Loader.instance.hide();
                    debugPrint("after hide loader");
                    if (position != null) {
                      debugPrint("before instruction dialog", );
                      AppStandardBottomSheet(content:  ShowFingerScanInstructionSheet());

                      debugPrint("after instruction dialog",);
                    }
                  },
                  enabledColor: AppColors.walletColor,
                  isEnabled: true,
                ),

                // SizedBox(height: 10.0.sp),
                CommonButton(
                  label: "Have missing fingers?",
                  // bottomSpace: 16.sp,
                  enabledColor: AppColors.white,
                  borderColor: AppColors.textGrayAskleois,
                  iconColor: Colors.transparent,
                  labelTextStyle: TextStyle(
                    // fontFamily: Fonts.plusJakartaSansBold,
                    color: AppColors.textGrayAskleois,
                    fontSize: 15.sp,
                  ),

                  isButtonAnimationEnable: false,
                  onTap: () {
                    Get.to(()=>const HaveMissingFingersWidget());
                  },
                  isEnabled: true,
                ),
                // CommonButton(
                //   label: Languages.of(context).haveMissingFingers,
                //   onTap: () async {
                //     appNavigator.to(() => const HaveMissingFingersWidget());
                //   },
                //   enabledColor: AppColors.walletColor,
                //   isEnabled: true,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
