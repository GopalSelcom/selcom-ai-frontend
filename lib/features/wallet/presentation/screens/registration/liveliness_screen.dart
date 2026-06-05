import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:m7_livelyness_detection/index.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/device_info.dart';
import '../../../../../core/utils/permissions/camera.dart';

import '../../../../home/presentation/screens/home_screen.dart';

import '../../controllers/registration_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/common_button.dart';
import 'widgets/custom_app_bar.dart';

class FaceDetectionScreen extends StatefulWidget {
  final String? leadingIcon;
  final bool testMode;

  const FaceDetectionScreen({
    super.key,
    this.leadingIcon,
    this.testMode = false,
  });

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  RegistrationController registrationController = RegistrationController();
  WalletController? get walletController =>
      Get.isRegistered<WalletController>()
          ? Get.find<WalletController>()
          : null;
  @override
  void initState() {
    RegistrationController().verifyDocumentSelfieCalledCount = 0;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<File> getAssetFile({required String assetPath}) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last; // Extract the filename
    final tempFile = File(
      '${tempDir.path}/$fileName',
    ); // Use the extracted filename

    await tempFile.writeAsBytes(bytes);

    return tempFile;
  }

  void onBackPress() {
    if (Get.key.currentState?.canPop()??false) {
      Get.back();
    } else {
      Get.offAll(()=>const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // onBackPress();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.boxGray,
        appBar: CustomAppBar(
          title: "Face Scan Process",
          showBack: true,
          // leadingIcon: widget.leadingIcon ?? CommonImages.IC_BACK,
          // onTapLeading: onBackPress,
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 15.0.sp),
          child: Column(
            children: [
              SizedBox(height: 30.0.sp),
              Image.asset(AppAssets.walletLinkFaceScan, height: Get.height * 0.27),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Your selfie will be captured to help us validate you against your ID. Please hold your phone steady, ensure your face is within the circular frame, and follow the prompts.",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textGrey,
                    // fontFamily: FontName.NunitoSansRegular,
                    fontSize: 15.0.sp,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: CommonButton(
                  label: "Continue",
                  onTap: () async {
                    Future<void> startFaceScanning() async {
                      final val = await CameraService.instance
                          .requestPermission(force: true);
                      if (!val) {
                        return;
                      }
                      M7LivelynessDetection.instance.configure(
                        displayDots: true,
                        displayLines: true,
                        thresholds: [
                          M7BlinkDetectionThreshold(
                            leftEyeProbability: 0.5,
                            rightEyeProbability: 0.5,
                          ),
                        ],
                        dotColor: Colors.blue.shade200,
                        lineColor: Colors.blue.shade200,
                      );
                      var response = await M7LivelynessDetection.instance.detectLivelyness(
                        context,
                        config: M7DetectionConfig(
                          maxSecToDetect: 120,
                          allowAfterMaxSec: true,
                          steps: [
                            // M7LivelynessStepItem(
                            //   step: M7LivelynessStep.turnLeft,
                            //   title: Platform.isAndroid
                            //       ? Languages.of(context).(Labels.turnLeft)
                            //       : Languages.of(context).(Labels.turnRight),
                            //   isCompleted: false,
                            //   detectionColor: Colors.blue.shade200,
                            // ),
                            // M7LivelynessStepItem(
                            //   step: M7LivelynessStep.turnRight,
                            //   title: Platform.isAndroid
                            //       ? Languages.of(context).(Labels.turnRight)
                            //       : Languages.of(context).(Labels.turnLeft),
                            //   isCompleted: false,
                            //   detectionColor: Colors.blue.shade200,
                            // ),
                            M7LivelynessStepItem(
                              step: M7LivelynessStep.smile,
                              title: "Smile",
                              isCompleted: false,
                              detectionColor: Colors.blue.shade200,
                            ),
                            M7LivelynessStepItem(
                              step: M7LivelynessStep.blink,
                              title: "Blink your eyes",
                              isCompleted: false,
                              detectionColor: Colors.blue.shade200,
                            ),
                          ],
                          captureButtonColor: AppColors.primary,
                          startWithInfoScreen: false,
                        ),
                      );
                      debugPrint(response!.didCaptureAutomatically.toString());
                      debugPrint(response.imgPath.toString());
                      if (response.imgPath.isNotEmpty) {
                        registrationController.verifyDocumentPath =
                            response.imgPath;
                        registrationController.verifyDocumentSelfie();
                      }
                    }

                    registrationController.verifyDocumentSelfieCalledCount++;


                    bool testIt =
                        (walletController?.isTestingMode.value??false)&&
                        !DeviceInfo().isPhysicalDevice;

                    if (testIt) {
                      // emulator
                      File file1 = await getAssetFile(
                        assetPath: "assets/images/1.jpeg",
                      );
                      File file2 = await getAssetFile(
                        assetPath: "assets/images/2.webp",
                      );
                      if (file1.path.isNotEmpty && file2.path.isNotEmpty) {
                        registrationController.verifyDocumentPath = file1.path;
                        registrationController.nidaImageFile = file2;
                        await registrationController.verifyDocumentSelfie();
                      }
                    } else {
                      // real device
                      await startFaceScanning();
                    }
                  },
                  enabledColor: AppColors.walletColor,
                  isEnabled: true,
                ) /* OutlineBorderButtonView(
                  fontSize: 15.0.h,
                  Languages.of(context).(Labels.Continue),
                  fontFamily: FontName.NunitoSansBold,
                  color: AppColors.whiteColor,
                  backgroundColor: AppColors.loaderColor,
                  onPressed: () async {

                  },
                ),*/,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
