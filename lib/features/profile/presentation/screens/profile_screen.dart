import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_profile_header.dart';

import '../controllers/profile_controller.dart';
import '../widgets/menu_item_widget.dart';
import '../widgets/wallet_summary_card.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(sl<ProfileController>());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
                      SizedBox(height: 32.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'App Settings',
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.shade2,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _buildSettingsList(),
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
                              color: Colors.white,
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
                                  'Logout',
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
                      color: const Color(0x6D808080), // Dim color
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
                    color: Colors.black26,
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
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.screenTitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: controller.toggleEditMode,
                    child: Icon(
                      Iconsax.user_edit,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                mobile,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32.h),

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
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            color: Colors.white,
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
            color: Colors.white,
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
                color: Colors.white.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          MenuItemWidget(
            icon: Iconsax.clock,
            title: 'My Rides',
            onTap: controller.openMyRides,
          ),
          MenuItemWidget(
            icon: Iconsax.card,
            title: 'Payment',
            onTap: controller.openPaymentMethods,
          ),
          MenuItemWidget(
            icon: Iconsax.gift,
            title: 'Promotions',
            onTap: controller.openPromotions,
          ),
          MenuItemWidget(
            icon: Iconsax.message_question,
            title: 'Help',
            onTap: controller.openContactUs,
          ),
          MenuItemWidget(
            icon: Iconsax.shield_tick,
            title: 'Safety & Privacy',
            onTap: controller.openPrivacyPolicy,
          ),
          MenuItemWidget(
            icon: Iconsax.heart,
            title: 'Favourite Locations',
            onTap: controller.openFavoriteLocations,
          ),
          MenuItemWidget(
            icon: Iconsax.reserve,
            title: 'Notification',
            onTap: controller.openNotifications,
            showDivider: false, // Last item has no divider
          ),
        ],
      ),
    );
  }
}
