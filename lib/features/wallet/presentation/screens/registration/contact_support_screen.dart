
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';
import 'package:selcom_rides_frontend/shared/widgets/app_primary_button.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../utils/media_viewer.dart';



class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MediaViewer(path: AppAssets.selcomGoLogoRedSvg, height: 50.0.sp),
              Spacer(flex: 1),
              Lottie.asset(
                Lotties.contactSupportTicketAnimation,
                height: 200.0.sp,
              ),
              SizedBox(height: 23.0.sp),
              Text(
                message,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 20.0.sp),
                textAlign: TextAlign.center,
              ),
              Spacer(flex: 2),
              AppPrimaryButton(
                label:"Okay",
                onPressed: () async {
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
