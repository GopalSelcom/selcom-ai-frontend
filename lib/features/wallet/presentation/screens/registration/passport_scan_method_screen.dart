import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/screen_title_widget.dart';
import '../../controllers/registration_controller.dart';
import 'passport_authentication_screen.dart';

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
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: AppTheme.isDarkMode.value
              ? Brightness.light
              : Brightness.dark,
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
    final muted = AppTheme.isDarkMode.value
        ? AppColors.whiteColor.withValues(alpha: 0.72)
        : AppColors.lightGreyTextColor;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.isDarkMode.value
          ? Theme.of(context).scaffoldBackgroundColor
          : Theme.of(context).colorScheme.secondary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenTitleWidget(
              leftIconColor: AppTheme.isDarkMode.value
                  ? AppColors.whiteColor
                  : AppColors.blackColor,
              screenTitle: 'Passport',
              isLeftIconOnTap: true,
              titleStyle: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(height: 1.4),
              onLeftIconTap: () => Get.back(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How do you want to read your passport?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose one option. NFC reads the electronic chip on the passport cover. '
                      'Camera captures the printed data page so text can be read on this device.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),
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
    final border = AppTheme.isDarkMode.value
        ? AppColors.whiteColor.withValues(alpha: 0.12)
        : AppColors.blackColor.withValues(alpha: 0.08);
    final fill = AppTheme.isDarkMode.value
        ? AppColors.darkThemeTextFieldColor.withValues(alpha: 0.45)
        : AppColors.lightThemeTextFieldColor;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: AppTheme.isDarkMode.value
                      ? AppColors.whiteColor
                      : AppColors.blackColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              instructions,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: AppTheme.isDarkMode.value
                    ? AppColors.whiteColor.withValues(alpha: 0.75)
                    : AppColors.lightGreyTextColor,
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
