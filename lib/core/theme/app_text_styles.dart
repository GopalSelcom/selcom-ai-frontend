import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final String? fontFamily = GoogleFonts.poppins().fontFamily;

  // Screen titles
  static TextStyle screenTitle = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    fontFamily: fontFamily,
  );

  // Section titles / modal headers
  static TextStyle sectionTitle = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    fontFamily: fontFamily,
  );

  // Card titles / list items
  static TextStyle cardTitle = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    fontFamily: fontFamily,
  );

  // Body text
  static TextStyle body = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    fontFamily: fontFamily,
  );

  // Secondary body
  static TextStyle bodySecondary = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    fontFamily: fontFamily,
  );

  // Small labels, timestamps
  static TextStyle caption = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    fontFamily: fontFamily,
  );

  // Button text
  static TextStyle button = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: fontFamily,
  );

  // Price / fare amount (bold, larger)
  static TextStyle price = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    fontFamily: fontFamily,
  );
}
