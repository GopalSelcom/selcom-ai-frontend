import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/registration_controller.dart';



class WalletWaitingScreen extends StatefulWidget {
  const WalletWaitingScreen({super.key});

  @override
  State<WalletWaitingScreen> createState() => _WalletWaitingScreenState();
}

class _WalletWaitingScreenState extends State<WalletWaitingScreen> {
  RegistrationController registrationController = RegistrationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      registrationController.uploadOcrDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future(() => false);
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Padding(
          padding: EdgeInsets.only(top: 15.0.sp),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 200.0.sp),
                Lottie.asset(
                  Lotties.walletAnimation,
                  height: Get.height * 0.2,
                  repeat: true,
                ),
                SizedBox(height: 50.0.sp),
                Text(
                  "Please wait while we create your wallet",
                  style: AppTextStyles.screenTitle.copyWith(
                    color: AppColors.textGrey,
                    // fontFamily: FontName.NunitoSansRegular,
                    fontSize: 18.0.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.0.sp),
                Text(
                 "This may take a moment...",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.walletColor,
                    // fontFamily: FontName.NunitoSansRegular,
                    fontSize: 18.0.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
