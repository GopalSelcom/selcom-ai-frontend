import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:selcom_rides_frontend/core/localization/localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/profile_controller.dart';
import '../widgets/menu_item_widget.dart';
import '../widgets/wallet_summary_card.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(sl<ProfileController>());

  Future<void> _toggleLanguage(BuildContext context) async {
    final current = Get.locale ?? Get.deviceLocale ?? const Locale('en');
    final nextCode = current.languageCode == 'sw' ? 'en' : 'sw';
    await Localization.instance.changeLanguage(context, nextCode);
    Get.snackbar(
      AppStrings.language.tr,
      nextCode == 'sw'
          ? AppStrings.switchedToSwahili.tr
          : AppStrings.switchedToEnglish.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  String _currentLanguageLabel(BuildContext context) {
    final current = Get.locale ?? Get.deviceLocale ?? const Locale('en');
    return current.languageCode == 'sw'
        ? AppStrings.swahili.tr
        : AppStrings.english.tr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 1. Underlying Layout (Static spacing header + List)
          Column(
            children: [
              // Invisible spacer perfectly matching the normal collapsed header height
              Obx(
                () => AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCirc,
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: 0.0,
                    child: AppProfileHeader(
                      onBack: controller.handleBack,
                      child: controller.isEditing.value
                          ? _buildEditModeContent()
                          : _buildNormalModeContent(),
                    ),
                  ),
                ),
              ),

              // App Settings List Area
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          AppStrings.appSettings.tr,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w500,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _buildSettingsList(context),
                      ),
                      SizedBox(height: 24.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: InkWell(
                          onTap: controller.logout,
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.h,
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(color: AppColors.divider),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.logout,
                                  size: 24.w,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 16.w),
                                Text(
                                  AppStrings.logout.tr,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Dim & Blur Overlay (Appears only during edit mode)
          Obx(
            () => AnimatedOpacity(
              opacity: controller.isEditing.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              child: IgnorePointer(
                ignoring: !controller.isEditing.value,
                child: GestureDetector(
                  onTap: controller.cancelEdit,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                    child: Container(
                      color: AppColors.overlayGray43,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Foreground Animated Red Header (Pinned top, expands over stack)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCirc,
                alignment: Alignment.topCenter,
                child: AppProfileHeader(
                  onBack: controller.handleBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, -0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: controller.isEditing.value
                        ? _buildEditModeContent()
                        : _buildNormalModeContent(),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          Obx(
            () => controller.isLoading.value
                ? Container(
                    color: AppColors.black.withValues(alpha: 0.26),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalModeContent() {
    final user = controller.userModel.value;
    final name = user?.name ?? '';
    final mobile = user?.mobileNumber != null
        ? '+${user!.countryCode} ${TanzaniaPhoneFormatter.formatString(user.mobileNumber.toString())}'
        : '';
    final balance = controller.walletBalance.value;
    final walletNum = controller.walletNumber.value;

    return Column(
      key: const ValueKey('normal_mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Info
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              // Profile Image
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  color: AppColors.white.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: user?.image != null && user!.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.image!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Iconsax.user,
                            color: AppColors.white,
                            size: 30.w,
                          ),
                        )
                      : Icon(
                          Iconsax.user,
                          color: AppColors.white,
                          size: 30.w,
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTextStyles.screenTitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: controller.toggleEditMode,
                          child: Icon(
                            Iconsax.user_edit,
                            color: AppColors.white,
                            size: 20.w,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      mobile,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Wallet Card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: WalletSummaryCard(balance: balance, walletNumber: walletNum),
        ),
      ],
    );
  }

  Widget _buildEditModeContent() {
    return Padding(
      key: const ValueKey('edit_mode'),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Profile Image with Edit Option
          Stack(
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  color: AppColors.white.withValues(alpha: 0.2),
                ),
                child: ClipOval(
                  child: controller.pickedImage.value != null
                      ? Image.file(
                          controller.pickedImage.value!,
                          fit: BoxFit.cover,
                        )
                      : controller.userModel.value?.image != null &&
                              controller.userModel.value!.image!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: controller.userModel.value!.image!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Iconsax.user,
                                color: AppColors.white,
                                size: 50.w,
                              ),
                            )
                          : Icon(
                              Iconsax.user,
                              color: AppColors.white,
                              size: 50.w,
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: controller.pickProfileImage,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.camera,
                      color: AppColors.primary,
                      size: 18.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // User Name Field
          _buildEditTextField(
            label: 'User name',
            textController: controller.nameTextController,
            focusNode: controller.nameFocusNode,
            isPhone: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.saveProfile(),
          ),
          SizedBox(height: 32.h),

          // Phone Number Field
          _buildEditTextField(
            label: 'Phone number',
            textController: controller.phoneTextController,
            focusNode: controller.phoneFocusNode,
            isPhone: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => {},
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildEditTextField({
    required String label,
    required TextEditingController textController,
    required FocusNode focusNode,
    required bool isPhone,
    required TextInputAction textInputAction,
    required void Function(String) onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: textController,
          focusNode: focusNode,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.name,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: AppTextStyles.screenTitle.copyWith(
            color: AppColors.white,
            fontSize: 30.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          decoration: InputDecoration(
            isDense: true,
            enabled: !isPhone,
            contentPadding: EdgeInsets.only(bottom: 8.h),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Obx(
        () => Column(
          children: [
            MenuItemWidget(
              icon: Iconsax.clock,
              title: AppStrings.myRides.tr,
              onTap: controller.openMyRides,
            ),
            MenuItemWidget(
              icon: Iconsax.card,
              title: AppStrings.payment.tr,
              onTap: controller.openPaymentMethods,
            ),
            MenuItemWidget(
              icon: Iconsax.gift,
              title: AppStrings.promotions.tr,
              onTap: controller.openPromotions,
            ),
            MenuItemWidget(
              icon: Iconsax.message_question,
              title: AppStrings.help.tr,
              onTap: controller.openContactUs,
            ),
            MenuItemWidget(
              icon: Iconsax.shield_tick,
              title: AppStrings.safetyAndPrivacy.tr,
              onTap: controller.openPrivacyPolicy,
            ),
            MenuItemWidget(
              icon: Iconsax.heart,
              title: AppStrings.favouriteLocations.tr,
              onTap: controller.openFavoriteLocations,
            ),
            MenuItemWidget(
              icon: Iconsax.reserve,
              title: AppStrings.notification.tr,
              onTap: controller.openNotifications,
              showDivider: controller.showSettingsOption.value,
            ),
            if (controller.showSettingsOption.value)
              MenuItemWidget(
                icon: Iconsax.setting_2,
                title: AppStrings.settings.tr,
                onTap: controller.openSettings,
              ),
            MenuItemWidget(
              icon: Iconsax.language_square,
              title:
                  '${AppStrings.language.tr} (${_currentLanguageLabel(context)})',
              onTap: () => _toggleLanguage(context),
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}
