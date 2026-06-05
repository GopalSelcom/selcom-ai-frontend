import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../controllers/registration_controller.dart';
import 'passport_authentication_screen.dart';
import 'widgets/custom_app_bar.dart';

/// Entry point: user chooses NFC chip read or camera capture of the data page.
class PassportScanMethodScreen extends StatefulWidget {
  const PassportScanMethodScreen({super.key});

  @override
  State<PassportScanMethodScreen> createState() =>
      _PassportScanMethodScreenState();
}

class _PassportScanMethodScreenState extends State<PassportScanMethodScreen> {
  RegistrationController registrationController = RegistrationController();

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.pageBackground,
      appBar: const CustomAppBar(title: "Passport", showBack: true),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    Text(
                      'How do you want to read your passport?',
                      style: AppTextStyles.homeSubtitle.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Choose one option. NFC reads the electronic chip on the passport cover. '
                      'Camera captures the printed data page so text can be read on this device.',
                      style: AppTextStyles.homeSubtitle.copyWith(
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _MethodCard(
                      icon: CupertinoIcons.waveform_path,
                      title: 'NFC chip scan',
                      instructions:
                          'Enable NFC in system settings. Enter passport number and dates on the next screen, '
                          'then place your phone on the passport cover until reading finishes.',
                      buttonLabel: 'Continue with NFC',
                      onPressed: () {
                        Get.to(() => const PassportAuthenticationScreen());
                      },
                    ),
                    const SizedBox(height: 20),
                    _MethodCard(
                      icon: CupertinoIcons.camera,
                      title: 'Camera scan',
                      instructions:
                          'Photograph the passport data page in good light. Align the page inside the frame '
                          'with the MRZ lines in the highlighted band, then review extracted details before saving.',
                      buttonLabel: 'Open camera',
                      onPressed: () => registrationController
                          .openPassportCameraScan(context),
                    ),
                    const SizedBox(height: 20),
                    // _MethodCard(
                    //   icon: CupertinoIcons.viewfinder,
                    //   title: 'MRZ scanner',
                    //   instructions:
                    //       'Automatic capture when the passport is steady and the bottom MRZ lines are readable. '
                    //       'Review and edit fields before continuing.',
                    //   buttonLabel: 'Start MRZ scanner',
                    //   onPressed: () {
                    //     Get.put(PassportMrzScanController());
                    //     Get.to(() => const PassportMrzCameraScreen());
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.instructions,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String instructions;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderWalletCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: AppColors.blackColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              instructions,
              style: AppTextStyles.homeCaption.copyWith(
                fontSize: 14.sp,
                height: 1.4,
                color: AppColors.textBody.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
