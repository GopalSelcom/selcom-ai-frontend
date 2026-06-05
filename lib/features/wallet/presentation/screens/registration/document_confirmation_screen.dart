import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:m7_livelyness_detection/index.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';
import 'package:selcom_rides_frontend/shared/widgets/app_primary_button.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../controllers/registration_controller.dart';
import 'widgets/custom_app_bar.dart';


class DocumentConfirmationScreen extends StatefulWidget {
  const DocumentConfirmationScreen({super.key});

  @override
  State<DocumentConfirmationScreen> createState() =>
      _DocumentConfirmationScreenState();
}

class _DocumentConfirmationScreenState
    extends State<DocumentConfirmationScreen> {
  final RegistrationController _loginController = RegistrationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: const CustomAppBar(
        title: "Document Confirmation",
        showBack: true,
        // leadingIcon: Images.IC_BACK,
        // onTapLeading: appNavigator.pop,
      ),
      body: Obx(
        () => Column(
          children: <Widget>[
            Container(
              width: 150.0.sp,
              height: 160.0.sp,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: _loginController.nidaImageFile != null
                  ? Image.file(
                      _loginController.nidaImageFile!,
                      height: 160.0.sp,
                      width: 150.0.sp,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(AppAssets.placeHolder, fit: BoxFit.cover),
                    )
                  : SizedBox(),
            ),
            SizedBox(height: 30.0.sp),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount:
                    ((_loginController
                                .uploadDocumentsModel
                                .value
                                .data
                                ?.isNotEmpty ??
                            false) &&
                        (_loginController
                                .uploadDocumentsModel
                                .value
                                .data?[0]
                                .documentDetails
                                ?.isNotEmpty ??
                            false))
                    ? (_loginController
                              .uploadDocumentsModel
                              .value
                              .data?[0]
                              .documentDetails
                              ?.length ??
                          0)
                    : 0,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom:
                          !(index ==
                              ((_loginController
                                          .uploadDocumentsModel
                                          .value
                                          .data?[0]
                                          .documentDetails
                                          ?.length ??
                                      0) -
                                  1))
                          ? 15
                          : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "${_loginController.uploadDocumentsModel.value.data?[0].documentDetails?[index].key}",
                          style: AppTextStyles.body.copyWith(color: AppColors.lightGreyColor),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 50,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          width: Get.width,
                          decoration: BoxDecoration(
                            color: AppColors.greyColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${_loginController.uploadDocumentsModel.value.data?[0].documentDetails?[index].value}",
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: Platform.isAndroid ? 0 : 10,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AppPrimaryButton(
                      label:"Cancel",
                      onPressed:()=> Get.back(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppPrimaryButton(
                      label:"Confirm",
                      onPressed: _loginController.confirmAndSubmitDocuments,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ImageHandler {
  Future<File> saveImageFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    // Get the temporary directory of the device
    final directory = await getTemporaryDirectory();

    // Create the path for the image file
    final imagePath = '${directory.path}/$fileName';

    // Create the file and write the bytes to it
    final file = File(imagePath);
    return await file.writeAsBytes(bytes);
  }

  Future<File> decodeAndSaveImage({
    required String base64String,
    required String fileName,
  }) async {
    // Decode the Base64 string to Uint8List
    Uint8List bytes = base64.decode(base64String);

    // Save the bytes to an image file
    return await saveImageFile(bytes: bytes, fileName: fileName);
  }
}
