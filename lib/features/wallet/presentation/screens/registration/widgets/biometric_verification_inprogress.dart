import 'package:duka_direct_4_flutter/core/extensions/formatting_extensions.dart';
import 'package:duka_direct_4_flutter/core/services/responsive/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/functions/date_format.dart';
import '../../../../../core/resources/images.dart';
import '../../../../../core/services/localization/language/languages.dart';
import '../../../../../core/services/localization/localization.dart';
import '../../../../../core/services/router/app_navigator.dart';
import '../../../../../core/services/theme/theme.dart';
import '../../../../../core/utils/manager/device_info.dart';
import '../../../../../core/widgets/blur_bottomsheet.dart';
import '../../../../../core/widgets/common_bottomsheet.dart';
import '../../../../../core/widgets/common_button.dart';
import '../../../controller/registration_controller.dart';
import '../../../controller/wallet_controller.dart';
import '../../../controllers/registration_controller.dart';
import '../../../controllers/wallet_controller.dart';
import '../../../test/finger_scan_body.dart';
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

  @override
  void initState() {
    super.initState();
    bool testIt =
        WalletController().isTestingMode && DeviceInfo().isPhysicalDevice;
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
                              Languages.of(Get.context!).nidaVerificationMsg,
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
                              Languages.of(Get.context!).waitingForVerification,
                              style: titleStyle(
                                context,
                              )?.copyWith(fontSize: 16.0.sp),
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
                                      text:
                                          Localization
                                                  .instance
                                                  .currentLanguage
                                                  ?.languageCode ==
                                              "sw"
                                          ? "Dakika"
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
                                      text:
                                          Localization
                                                  .instance
                                                  .currentLanguage
                                                  ?.languageCode ==
                                              "en"
                                          ? "sec"
                                          : "",
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
                          Languages.of(context).nidaFailedMsg,
                          style: titleStyle(
                            context,
                          )?.copyWith(fontSize: 16.0.sp),

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
                        label: Languages.of(context).tryAgain,
                        onTap: () async {
                          appNavigator.pop();
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
                          );*/ BlurBottomSheet.show(
                            context: context,
                            child: CustomBottomSheet(
                              child: ShowFingerScanInstructionSheet(),
                            ),
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
                      label: Languages.of(context).cancel,
                      onTap: () async {
                        appNavigator.pop();
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
