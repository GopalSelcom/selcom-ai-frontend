import 'dart:io';

import 'package:duka_direct_4_flutter/core/services/responsive/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';
// import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';
import '../../../../../core/functions/log.dart';
import '../../../../../core/resources/images.dart';
import '../../../../../core/services/localization/language/languages.dart';
import '../../../../../core/services/localization/localization.dart';
import '../../../../../core/services/progress_indicator/loader.dart';
import '../../../../../core/services/router/app_navigator.dart';
import '../../../../../core/services/theme/theme.dart';
import '../../../../../core/utils/manager/device_info.dart';
import '../../../../../core/utils/manager/modules.dart';
import '../../../../../core/utils/permissions/camera.dart';
import '../../../../../core/widgets/common_button.dart';
import '../../../controller/registration_controller.dart';
import '../../../controller/wallet_controller.dart';
import '../../../test/finger_scan_body.dart';
import '../widgets/biometric_verification_inprogress.dart';

class ShowFingerScanInstructionSheet extends StatefulWidget {
  const ShowFingerScanInstructionSheet({super.key});

  @override
  State<ShowFingerScanInstructionSheet> createState() =>
      _ShowFingerScanInstructionSheetState();
}

class _ShowFingerScanInstructionSheetState
    extends State<ShowFingerScanInstructionSheet> {
  RegistrationController registrationController = RegistrationController();

  SelcomIdentyPlugin selcomIdentyPlugin = SelcomIdentyPlugin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 16.0.sp,
            top: 13.0.sp,
            right: 16.0.sp,
            bottom: 13.0.sp,
          ),
          // decoration: BoxDecoration(
          //   color: AppColors.drawerWhiteColor,
          //   border: Border(bottom: BorderSide(color: AppColors.borderColor)),
          // ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                Languages.of(context).howToScanFingers,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: headlineStyle(context)?.copyWith(
                  // color: AppColors.lightGreyColor,
                  // fontSize: 14.0.sp,
                  // fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.0.sp, right: 10.0.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          Images.fingerRightScan,
                          height: Get.width * 0.4,
                          width: Get.width * 0.4,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          Languages.of(context).correct,
                          style: AppTextStyles.screenTitle.copyWith(
                            color: AppColors.blackColor,
                            fontSize: 15.0.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 10.0.sp),
                      child: Container(
                        width: 2,
                        height: Get.width * 0.4,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          Images.finerWrongScan,
                          height: Get.width * 0.4,
                          width: Get.width * 0.4,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          Languages.of(context).wrong,
                          style: AppTextStyles.screenTitle.copyWith(
                            color: AppColors.blackColor,
                            fontSize: 15.0.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20.0.sp),
                    Text(
                      Languages.of(context).fingerScanInstruction1,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 13.0.sp,
                      ),
                    ),
                    SizedBox(height: 10.0.sp),
                    Text(
                      Languages.of(context).fingerScanInstruction2,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 13.0.sp,
                      ),
                    ),
                    SizedBox(height: 10.0.sp),
                  ],
                ),
              ),
              // Expanded(
              //   child: ListView(
              //     padding: EdgeInsets.zero,
              //     physics: const BouncingScrollPhysics(),
              //     children: [
              //
              //     ],
              //   ),
              // ),
              Padding(
                padding: EdgeInsets.all(15.0.sp),
                child: CommonButton(
                  label: Languages.of(context).continueLabel,
                  onTap: () async {
                    bool testIt =
                        WalletController().isTestingMode &&
                        !DeviceInfo().isPhysicalDevice;

                    if (testIt) {
                      appNavigator.pop();
                      registrationController.nidaNumberString.value =
                          "19990102-61401-00001-20";
                      (fingerScanBody["data"] as Map).remove("finger1");
                      (fingerScanBody["data"] as Map).remove("finger3");
                      (fingerScanBody["data"] as Map).remove("finger4");
                      await showDialog(
                        context: Get.context!,
                        barrierDismissible: false,
                        builder: (context) {
                          return BiometricVerificationInprogrees(
                                fingerScanData: fingerScanBody,
                              )
                              .animate()
                              .fade(
                                duration: 400.ms,
                                curve: Curves.fastOutSlowIn,
                              )
                              .scale(
                                duration: 400.ms,
                                curve: Curves.fastOutSlowIn,
                              );
                        },
                      );
                      return;
                    }

                    appNavigator.pop();

                    bool result = await CameraService.instance
                        .requestPermission(module: Module.wallet, force: true);
                    if (result) {
                      debugPrint("Premissionnnnnnnnnnnn granted");
                      if (registrationController
                          .isMissingFingerSelected
                          .value) {
                        if (registrationController.isLeftHandSelected.value) {
                          selcomIdentyPlugin.options.leftHandMissingArray =
                              registrationController.getMissingFingers();
                        } else {
                          selcomIdentyPlugin.options.rightHandMissingArray =
                              registrationController.getMissingFingers();
                        }
                      }
                      if (Platform.isAndroid) {
                        Loader.instance.show();
                        // showLoaderDialog(context);
                      }
                      selcomIdentyPlugin.options.licenseFile =
                          registrationController.getIdentyLicense;
                      selcomIdentyPlugin.options.languageCode =
                          Localization.instance.currentLanguage?.languageCode ??
                          "en";
                      var result = await selcomIdentyPlugin.enrollFinger();
                      if (Platform.isAndroid) {
                        // hideLoaderDialog();
                        Loader.instance.hide();
                      }
                      await registrationController.processIdentyResult(
                        result: result,
                      );
                    }
                  },
                  enabledColor: AppColors.walletColor,
                  isEnabled: true,
                ),
              ),

              /*  OutlineBorderButtonView(
                  translate(Labels.Continue),
                  fontSize: 15.0.h,
                  fontFamily: FontName.NunitoSansBold,
                  color: AppColors.whiteColor,
                  backgroundColor: AppColors.loaderColor,
                  onPressed: () async {

                  },
                ),
              )*/
            ],
          ),
        ),
      ],
    );
  }
}
