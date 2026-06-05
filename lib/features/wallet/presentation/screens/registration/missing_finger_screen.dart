import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/features/wallet/presentation/screens/registration/widgets/check_box_with_text.dart';
import 'package:selcom_rides_frontend/shared/utils/app_dialogs.dart';

import '../../../../../core/services/progress_indicator/loader.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/registration_controller.dart';
import '../../widgets/common_button.dart';
import 'widgets/bouncing_selcom_pesa.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/finger_scan_instruction_sheet.dart';

class HaveMissingFingersWidget extends StatefulWidget {
  const HaveMissingFingersWidget({super.key});

  @override
  State<HaveMissingFingersWidget> createState() =>
      _HaveMissingFingersWidgetState();
}

class _HaveMissingFingersWidgetState extends State<HaveMissingFingersWidget> {
  RegistrationController registrationController = RegistrationController();

  SelcomIdentyPlugin selcomIdentyPlugin = SelcomIdentyPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      registrationController.resetMissingFingers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CustomAppBar(
        title: registrationController.isLeftHandSelected.value
            ? "Select Left Missing Fingers"
            : "Select Right Missing Fingers",
        // leadingIcon: CommonImages.IC_BACK,
        // onTapLeading: appNavigator.pop
        showBack: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                SizedBox(height: 50.0.sp),
                Obx(
                  () => GestureDetector(
                    onTap: () {
                      registrationController.isIndexFingerMissing.toggle();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(bottom: 15),
                      child: CheckboxWithText(
                        onTap: () {
                          registrationController.isIndexFingerMissing.value =
                              !registrationController
                                  .isIndexFingerMissing
                                  .value;
                        },
                        textSize: 16.0.sp,
                        checkBoxColor: AppColors.textGrey.withOpacity(0.3),
                        textColor: AppColors.textGrey,
                        value:
                            registrationController.isIndexFingerMissing.value,
                        text: registrationController.isLeftHandSelected.value
                            ? "Left hand index finger missing?"
                            : "Right hand index finger missing?",
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onTap: () {
                      registrationController.isMiddleFingerMissing.toggle();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(bottom: 15),
                      child: CheckboxWithText(
                        onTap: () {
                          registrationController.isMiddleFingerMissing.value =
                              !registrationController
                                  .isMiddleFingerMissing
                                  .value;
                        },
                        textSize: 16.0.sp,
                        checkBoxColor: AppColors.textGrey.withOpacity(0.3),
                        textColor: AppColors.textGrey,
                        value:
                            registrationController.isMiddleFingerMissing.value,
                        text: registrationController.isLeftHandSelected.value
                            ? "Left hand middle finger missing?"
                            : "Right hand middle finger missing?",
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onTap: () {
                      registrationController.isRingFingerMissing.toggle();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(bottom: 15),
                      child: CheckboxWithText(
                        onTap: () {
                          registrationController.isRingFingerMissing.value =
                              !registrationController.isRingFingerMissing.value;
                        },
                        textSize: 16.0.sp,
                        checkBoxColor: AppColors.textGrey.withOpacity(0.3),
                        textColor: AppColors.textGrey,
                        value: registrationController.isRingFingerMissing.value,
                        text: registrationController.isLeftHandSelected.value
                            ? "Left hand ring finger missing?"
                            : "Right hand ring finger missing?",
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onTap: () {
                      registrationController.isLittleFingerMissing.toggle();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(bottom: 15),
                      child: CheckboxWithText(
                        onTap: () {
                          registrationController.isLittleFingerMissing.value =
                              !registrationController
                                  .isLittleFingerMissing
                                  .value;
                        },
                        textSize: 16.0.sp,
                        checkBoxColor: AppColors.textGrey.withOpacity(0.3),
                        textColor: AppColors.textGrey,
                        value:
                            registrationController.isLittleFingerMissing.value,
                        text: registrationController.isLeftHandSelected.value
                            ? "Left hand pinky finger missing?"
                            : "Right hand pinky finger missing?",
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 50.0.sp),
                Container(
                  padding: const EdgeInsets.only(top: 40, right: 15, left: 15),
                  decoration: BoxDecoration(
                    color: AppColors.textGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            registrationController.isIndexFingerMissing
                                .toggle();
                          },
                          child: BouncingWidget(
                            isEnabled: true,
                            child: SizedBox(
                              width: Get.width * 0.12,
                              child: Image.asset(
                                AppAssets.finger1,
                                color:
                                    registrationController
                                        .isIndexFingerMissing
                                        .value
                                    ? AppColors.primary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            registrationController.isMiddleFingerMissing
                                .toggle();
                          },
                          child: BouncingWidget(
                            isEnabled: true,
                            child: SizedBox(
                              width: Get.width * 0.13,
                              child: Image.asset(
                                Images.finger2,
                                color:
                                    registrationController
                                        .isMiddleFingerMissing
                                        .value
                                    ? AppColors.primary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            registrationController.isRingFingerMissing.toggle();
                          },
                          child: BouncingWidget(
                            isEnabled: true,
                            child: SizedBox(
                              width: Get.width * 0.125,
                              child: Image.asset(
                                Images.finger3,
                                color:
                                    registrationController
                                        .isRingFingerMissing
                                        .value
                                    ? AppColors.primary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            registrationController.isLittleFingerMissing
                                .toggle();
                          },
                          child: BouncingWidget(
                            isEnabled: true,
                            child: SizedBox(
                              width: Get.width * 0.11,
                              child: Image.asset(
                                Images.finger4,
                                color:
                                    registrationController
                                        .isLittleFingerMissing
                                        .value
                                    ? AppColors.primary
                                    : null,
                              ),
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
          Spacer(),
          Obx(
            () => Padding(
              padding: EdgeInsets.all(15.0.sp),
              child: CommonButton(
                label: "Cancel",
                onTap:
                    !((registrationController.isIndexFingerMissing.value &&
                            registrationController
                                .isMiddleFingerMissing
                                .value &&
                            registrationController.isRingFingerMissing.value &&
                            registrationController
                                .isLittleFingerMissing
                                .value) ||
                        (!registrationController.isIndexFingerMissing.value &&
                            !registrationController
                                .isMiddleFingerMissing
                                .value &&
                            !registrationController.isRingFingerMissing.value &&
                            !registrationController
                                .isLittleFingerMissing
                                .value))
                    ? () async {
                        registrationController.isMissingFingerSelected.value =
                            true;
                        if ((registrationController
                                .isIndexFingerMissing
                                .value ||
                            registrationController
                                .isMiddleFingerMissing
                                .value ||
                            registrationController.isRingFingerMissing.value ||
                            registrationController
                                .isLittleFingerMissing
                                .value)) {
                          if (registrationController.isLeftHandSelected.value) {
                            selcomIdentyPlugin
                                    .options
                                    .isLeftMissingFingerSelected =
                                true;
                          } else {
                            selcomIdentyPlugin
                                    .options
                                    .isRightMissingFingerSelected =
                                true;
                          }
                        }
                        Loader.instance.show();
                        // showLoaderDialog(context);
                        Position? position = await LocationService.instance
                            .getCurrentPosition(force: true, precise: true);
                        // hideLoaderDialog();
                        Loader.instance.hide();
                        if (position != null) {
                          // hideLoaderDialog();
                          /* await Get.bottomSheet(
                            enterBottomSheetDuration: const Duration(
                              milliseconds: 300,
                            ),
                            exitBottomSheetDuration: const Duration(
                              milliseconds: 300,
                            ),
                            const ShowFingerScanInstructionSheet(),
                            elevation: 0,
                            backgroundColor: Colors.white,
                            enableDrag: true,
                          );*/
                          AppDialogs.showAnimatedBottomSheet(
                            child: ShowFingerScanInstructionSheet(),
                          );
                        }
                      }
                    : () {},
                enabledColor:
                    !((registrationController.isIndexFingerMissing.value &&
                            registrationController
                                .isMiddleFingerMissing
                                .value &&
                            registrationController.isRingFingerMissing.value &&
                            registrationController
                                .isLittleFingerMissing
                                .value) ||
                        (!registrationController.isIndexFingerMissing.value &&
                            !registrationController
                                .isMiddleFingerMissing
                                .value &&
                            !registrationController.isRingFingerMissing.value &&
                            !registrationController
                                .isLittleFingerMissing
                                .value))
                    ? AppColors.primary
                    : AppColors.textGrey,
                isEnabled: true,
              ),

              /*OutlineBorderButtonView(
                Languages.of(context).(Labels.Continue),
                fontSize: 15.0.sp,
                fontFamily: FontName.NunitoSansBold,
                color: AppColors.whiteColor,
                backgroundColor:
                    !((registrationController.isIndexFingerMissing.value &&
                            registrationController
                                .isMiddleFingerMissing
                                .value &&
                            registrationController.isRingFingerMissing.value &&
                            registrationController
                                .isLittleFingerMissing
                                .value) ||
                        (!registrationController.isIndexFingerMissing.value &&
                            !registrationController
                                .isMiddleFingerMissing
                                .value &&
                            !registrationController.isRingFingerMissing.value &&
                            !registrationController
                                .isLittleFingerMissing
                                .value))
                    ? AppColors.loaderColor
                    : AppColors.textGrey,
                onPressed:
                    !((registrationController.isIndexFingerMissing.value &&
                            registrationController
                                .isMiddleFingerMissing
                                .value &&
                            registrationController.isRingFingerMissing.value &&
                            registrationController
                                .isLittleFingerMissing
                                .value) ||
                        (!registrationController.isIndexFingerMissing.value &&
                            !registrationController
                                .isMiddleFingerMissing
                                .value &&
                            !registrationController.isRingFingerMissing.value &&
                            !registrationController
                                .isLittleFingerMissing
                                .value))
                    ? () async {
                        registrationController.isMissingFingerSelected.value =
                            true;
                        if ((registrationController
                                .isIndexFingerMissing
                                .value ||
                            registrationController
                                .isMiddleFingerMissing
                                .value ||
                            registrationController.isRingFingerMissing.value ||
                            registrationController
                                .isLittleFingerMissing
                                .value)) {
                          if (registrationController.isLeftHandSelected.value) {
                            selcomIdentyPlugin
                                    .options
                                    .isLeftMissingFingerSelected =
                                true;
                          } else {
                            selcomIdentyPlugin
                                    .options
                                    .isRightMissingFingerSelected =
                                true;
                          }
                        }
                        Loader.instance.show();
                        // showLoaderDialog(context);
                        Position? position = await LocationService.instance
                            .getCurrentPosition(force: true, precise: true);
                        // hideLoaderDialog();
                        Loader.instance.hide();
                        if (position != null) {
                          // hideLoaderDialog();
                          await Get.bottomSheet(
                            enterBottomSheetDuration: const Duration(
                              milliseconds: 300,
                            ),
                            exitBottomSheetDuration: const Duration(
                              milliseconds: 300,
                            ),
                            const ShowFingerScanInstructionSheet(),
                            elevation: 0,
                            backgroundColor: Colors.white,
                            enableDrag: true,
                          );
                        }
                      }
                    : () {},
              ),*/
            ),
          ),
        ],
      ),
    );
  }
}
