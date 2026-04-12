import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/auth_controller.dart';

class PhoneInputScreen extends GetView<AuthController> {
  const PhoneInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30.h),

                        // Title
                        Text(
                          'Enter Phone number for verification',
                          style: AppTextStyles.onboardingTitle.copyWith(
                            fontSize: 28.sp,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // Subtitle
                        Text(
                          'We’ll text a code to verify your phone number',
                          style: AppTextStyles.onboardingSubtitle,
                        ),

                        SizedBox(height: 24.h),

                        // Phone Input Field
                        Row(
                          children: [
                            // Country Selector
                            Container(
                              height: 54.h,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3.r),
                                    child: SvgPicture.asset(
                                      AppAssets.icTanzaniaFlag,
                                      height: 15.h,
                                      width: 23.w,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '+255',
                                    style: AppTextStyles.body.copyWith(
                                      fontFamily: AppTextStyles.metropolisFont,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.shade1,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20.sp,
                                    color: AppColors.shade2,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.w),

                            // Number Input
                            Expanded(
                              child: Container(
                                height: 54.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    TanzaniaPhoneFormatter(),
                                  ],
                                  style: AppTextStyles.body.copyWith(
                                    fontFamily: AppTextStyles.metropolisFont,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18.sp,
                                    color: AppColors.shade1,
                                    letterSpacing: 1.2,
                                  ),
                                  maxLength: 11,
                                  onChanged: (v) {
                                    controller.mobileNumber.value =
                                        v.replaceAll(' ', '');
                                  },
                                  decoration: InputDecoration(
                                    hintText: '7XX XX XXX',
                                    counterText: "",
                                    hintStyle: AppTextStyles.body.copyWith(
                                      color: AppColors.textLight,
                                      fontFamily: AppTextStyles.metropolisFont,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Email Input Field
                        Container(
                          height: 56.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 16.w),
                              SvgPicture.asset(
                                AppAssets.icSms,
                                height: 20.h,
                                width: 20.w,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.shade2,
                                  BlendMode.srcIn,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.emailAddress,
                                  style: AppTextStyles.body.copyWith(
                                    fontFamily: AppTextStyles.metropolisFont,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.sp,
                                    color: AppColors.shade1,
                                  ),
                                  onChanged: (v) => controller.email.value = v,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: AppTextStyles.body.copyWith(
                                      color: AppColors.textLight,
                                      fontFamily: AppTextStyles.metropolisFont,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Error Message
                        Obx(
                          () => controller.errorMessage.isNotEmpty
                              ? Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: Text(
                                    controller.errorMessage.value,
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Legal Note
                        Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: Text(
                            'Note: By proceeding, you consent to get calls, WhatsApp or SMS messages, including by automated means, from GoChauffeur and its affiliates to the number provided.',
                            style: AppTextStyles.onboardingFooter.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.shade2.withOpacity(0.7),
                            ),
                          ),
                        ),

                        // Button
                        Obx(
                          () => AppPrimaryButton(
                            label: 'Get Verification Code',
                            isLoading: controller.isLoading.value,
                            onPressed: controller.mobileNumber.value.length >= 9
                                ? () async {
                                    final success = await controller.sendOtp();
                                    if (success) {
                                      controller.startResendTimer();
                                      Get.toNamed(AppRoutes.otp);
                                    }
                                  }
                                : null,
                          ),
                        ),

                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
