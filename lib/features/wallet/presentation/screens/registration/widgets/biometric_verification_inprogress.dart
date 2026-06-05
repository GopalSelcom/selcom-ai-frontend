
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:selcom_rides_frontend/shared/utils/app_dialogs.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/device_info.dart';

import '../../../controllers/registration_controller.dart';
import '../../../controllers/wallet_controller.dart';

import '../../../widgets/common_button.dart';
import '../test/finger_scan_body.dart';
import 'finger_scan_instruction_sheet.dart';

class BiometricVerificationInprogrees extends StatefulWidget {
  final Map<String, dynamic> fingerScanData;

  const BiometricVerificationInprogrees({
    super.key,
    required this.fingerScanData,
  });

  @override
  State<BiometricVerificationInprogrees> createState() =>
      _BiometricVerificationInprogreesState();
}

class _BiometricVerificationInprogreesState
    extends State<BiometricVerificationInprogrees> {
  RegistrationController registrationController = RegistrationController();
  WalletController? get walletController =>
      Get.isRegistered<WalletController>()
          ? Get.find<WalletController>()
          : null;

  @override
  void initState() {
    super.initState();
    bool testIt =
        (walletController?.isTestingMode.value??false) && DeviceInfo().isPhysicalDevice;
    if (testIt) {
      registrationController.nidaNumberString.value = "19990102-61401-00001-20";
      (fingerScanBody["data"] as Map).remove("finger1");
      (fingerScanBody["data"] as Map).remove("finger3");
      (fingerScanBody["data"] as Map).remove("finger4");
      registrationController.uploadFingerScanData(
        fingerScanData: fingerScanBody,
      );
    } else {
      registrationController.uploadFingerScanData(
        fingerScanData: widget.fingerScanData,
      );
    }
    registrationController.timerForNIDAAuth();
  }

  @override
  void dispose() {
    registrationController.cancelTimerDisplay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(
            () => Container(
              padding: const EdgeInsets.all(20),
              width: Get.width * 0.9,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(Images.appLogo, height: 60.0.sp),
                  SizedBox(height: 10.0.sp),
                  Lottie.asset(
                    Lotties.waitingForVerification3,
                    height: Get.height * 0.15,
                  ),
                  SizedBox(height: 10.0.sp),
                  registrationController.displaySeconds.value != 0
                      ? Column(
                          children: [
                            Text(
                              "NIDA verification in progress. This can take up to 2 minutes to complete. Don't press back or close the app.",
                              style: AppTextStyles.screenTitle.copyWith(
                                fontSize: 16.0.sp,
                                height: 1.1,
                                fontWeight: FontWeight.normal,
                                color: AppColors.lightThemeBlackColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10.0.sp),
                            Text(
                              "Waiting for verification",
                              style: AppTextStyles.screenTitle.copyWith(fontSize: 16.0.sp),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 3.0.sp),
                            SizedBox(
                              width: Get.width * 0.9,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text
                                          : "",
                                      style: TextStyle(
                                        fontSize: 16.0.sp,
                                        height: 1.4,
                                        // fontFamily: FontName.NunitoSansRegular,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          " ${formatHHMMSS(registrationController.displaySeconds.value)} ",
                                      style: TextStyle(
                                        fontSize: 16.0.sp,
                                        height: 1.4,
                                        // fontFamily: FontName.NunitoSansRegular,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "sec",
                                      style: TextStyle(
                                        fontSize: 16.0.sp,
                                        height: 1.4,
                                        // fontFamily: FontName.NunitoSansRegular,
                                        color: AppColors.blackColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
      "NIDA verification is taking longer then usual. Please try again to proceed.",
                          style: AppTextStyles.screenTitle.copyWith(fontSize: 16.0.sp),

                          textAlign: TextAlign.center,
                        ),
                  SizedBox(
                    height: registrationController.displaySeconds.value == 0
                        ? 15
                        : 0,
                  ),
                  Visibility(
                    visible: registrationController.displaySeconds.value == 0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: CommonButton(
                        label: "Try again",
                        onTap: () async {
Get.back();
                          await Future.delayed(300.ms);
                          await /*Get.bottomSheet(
                            enterBottomSheetDuration: const Duration(
                              milliseconds: 300,
                            ),
                            exitBottomSheetDuration: const Duration(
                              milliseconds: 300,
                            ),
                            const ShowFingerScanInstructionSheet(),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            enableDrag: true,
                          );*/ AppDialogs.showAnimatedBottomSheet(


                              child: ShowFingerScanInstructionSheet()

                          );
                        },
                        enabledColor: AppColors.walletColor,
                        isEnabled: true,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: registrationController.displaySeconds.value == 0,
                    child: CommonButton(
                      label: "Cancel",
                      onTap: () async {
                        Get.back();
                      },
                      enabledColor: AppColors.walletColor,
                      isEnabled: true,
                    ),

                    /* OutlineBorderButtonView(
                          Languages
                              .of(context)
                              .cancel,
                          padding: EdgeInsets.zero,
                          borderColor: AppColors.dukaThemeColor,
                          color: AppColors.dukaThemeColor,
                          onPressed: () {
                             appNavigator.pop();
                          },
                        ),*/
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
