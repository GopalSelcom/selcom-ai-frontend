import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String metropolisFont = 'Metropolis';
  static final String? fontFamily = GoogleFonts.poppins().fontFamily;

  // Screen titles
  static TextStyle screenTitle = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    fontFamily: metropolisFont,
  );

  // Section titles / modal headers
  static TextStyle sectionTitle = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    fontFamily: metropolisFont,
  );

  // Card titles / list items
  static TextStyle cardTitle = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    fontFamily: fontFamily,
  );

  // Body text
  static TextStyle body = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.progressTrack,
    fontFamily: metropolisFont,
  );

  // Secondary body
  static TextStyle bodySecondary = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    fontFamily: fontFamily,
  );

  // Small labels, timestamps
  static TextStyle caption = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    fontFamily: fontFamily,
  );

  // Button text
  static TextStyle button = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: fontFamily,
  );

  // Price / fare amount (bold, larger)
  static TextStyle price = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    fontFamily: fontFamily,
  );

  // Onboarding Styles (Metropolis)
  static TextStyle onboardingTitle = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    fontFamily: metropolisFont,
    // height: 1.2,
  );

  static TextStyle onboardingSubtitle = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    fontFamily: metropolisFont,
    // height: 1.5,
  );

  static TextStyle onboardingFooter = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    fontFamily: metropolisFont,
    height: 1.4,
  );

  static TextStyle onboardingButton = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: metropolisFont,
  );

  // Home Screen Styles (Metropolis)
  static TextStyle homeTitle = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    fontFamily: metropolisFont,
  );

  static TextStyle homeSubtitle = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
    fontFamily: metropolisFont,
  );

  static TextStyle homeChip = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    fontFamily: metropolisFont,
  );

  static TextStyle homeCaption = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
    fontFamily: metropolisFont,
  );

  static TextStyle hint = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    fontFamily: metropolisFont,
  );
}
