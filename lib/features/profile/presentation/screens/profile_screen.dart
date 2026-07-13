import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_profile_user_avatar.dart';
import '../../../../shared/widgets/app_profile_user_summary.dart';
import '../controllers/profile_controller.dart';
import '../widgets/menu_item_widget.dart';
import '../widgets/profile_screen_layout.dart';
import '../widgets/profile_screen_shimmer.dart';
import '../widgets/wallet_summary_card.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(sl<ProfileController>());

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
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 0),
                        child: _buildSettingsList(context),
                      ),
                      SizedBox(
                        height: ProfileScreenLayout.logoutGapAfterSettings,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Obx(
                          () => controller.isLoadingProfile.value
                              ? ProfileScreenShimmer.logoutButton()
                              : _buildLogoutButton(),
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
                    child: Container(color: AppColors.overlayGray43),
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
        ],
      ),
    );
  }

  Widget _buildNormalModeContent() {
    return Obx(() {
      if (controller.isLoadingProfile.value) {
        return ProfileScreenShimmer.headerContent();
      }
      final user = controller.userModel.value;
      final name = (user?.name ?? '').trim().isNotEmpty
          ? (user?.name ?? '')
          : AppStrings.user.tr;
      final mobile = controller.displayPhone;
      final balance = controller.walletBalance.value;
      final walletNum = controller.walletNumber.value;
      final avgRating = (user?.goAvgRating ?? 0).toDouble();

      return Column(
        key: const ValueKey('normal_mode'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppProfileUserSummary(
            name: name,
            phone: mobile,
            rating: avgRating,
            imageUrl: user?.image,
            onEditTap: controller.toggleEditMode,
          ),

          // Wallet Card
          Padding(
            padding: ProfileScreenLayout.walletPadding,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(27.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(27.r),
                onTap: controller.isLoadingWallet.value
                    ? null
                    : controller.openWallet,
                child: SizedBox(
                  height: ProfileScreenLayout.walletCardHeight,
                  // Balance hidden by default; eye reveals + silent refresh.
                  child: WalletSummaryCard(
                    balance: balance,
                    walletNumber: walletNum,
                    currencyCode: controller.walletCurrency.value,
                    isLoading: controller.isLoadingWallet.value,
                    isRefreshingBalance:
                        controller.isRefreshingWalletBalance.value,
                    isBalanceVisible: controller.isBalanceVisible.value,
                    onToggleBalanceVisibility:
                        controller.toggleWalletBalanceVisibility,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEditModeContent() {
    return Padding(
      key: const ValueKey('edit_mode'),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppProfileUserAvatar(
            size: 100.w,
            imageUrl: controller.userModel.value?.image,
            imageFile: controller.pickedImage.value,
            showCameraBadge: true,
            onCameraTap: controller.pickProfileImage,
          ),
          SizedBox(height: 32.h),

          // User Name Field
          _buildEditTextField(
            label: AppStrings.userName.tr,
            textController: controller.nameTextController,
            focusNode: controller.nameFocusNode,
            isPhone: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.saveProfile(),
          ),
          SizedBox(height: 32.h),

          // Phone Number Field
          _buildEditTextField(
            label: AppStrings.phoneNumber.tr,
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
            color: AppColors.black,
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
          cursorColor: AppColors.black,
          style: AppTextStyles.screenTitle.copyWith(
            color: AppColors.black,
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
                color: AppColors.black.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.black, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: controller.logout,
      borderRadius: BorderRadius.circular(
        ProfileScreenLayout.logoutBorderRadius,
      ),
      child: Container(
        height: ProfileScreenLayout.logoutButtonHeight,
        padding: EdgeInsets.symmetric(
          vertical: ProfileScreenLayout.logoutVerticalPadding,
          horizontal: ProfileScreenLayout.logoutHorizontalPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(
            ProfileScreenLayout.logoutBorderRadius,
          ),
        ),
        child: Row(
          children: [
            Icon(Iconsax.logout, size: 24.w, color: AppColors.error),
            SizedBox(width: 7.w),
            Text(
              AppStrings.logout.tr,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
                height: 20 / 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      padding: ProfileScreenLayout.settingsContainerPadding,
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Obx(() {
        final menuCount = controller.visibleMenuItemCount;
        if (controller.isLoadingProfile.value) {
          return ProfileScreenShimmer.settingsMenu(itemCount: menuCount);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuItemWidget(
              icon: Iconsax.clock,
              title: AppStrings.myRides.tr,
              onTap: controller.openMyRides,
            ),
            MenuItemWidget(
              icon: Iconsax.heart,
              title: AppStrings.savedLocations.tr,
              onTap: controller.openFavoriteLocations,
            ),
            MenuItemWidget(
              icon: Iconsax.card,
              title: "Saved Cards",
              onTap: controller.openPaymentMethods,
            ),
            MenuItemWidget(
              icon: Iconsax.message_question,
              title: AppStrings.help.tr,
              onTap: controller.openContactUs,
            ),
            if (controller.showSafetyOption.value)
              MenuItemWidget(
                icon: Iconsax.security_user4,
                title: AppStrings.safety.tr,
                onTap: controller.openSafety,
              ),

            MenuItemWidget(
              icon: Iconsax.shield_tick,
              title: AppStrings.privacyPolicy.tr,
              onTap: controller.openPrivacyPolicy,
            ),
            MenuItemWidget(
              icon: Iconsax.document_text,
              title: AppStrings.termsAndConditions.tr,
              onTap: controller.openTermsAndConditions,
              showDivider: controller.showSettingsOption.value,
            ),
            if (controller.showSettingsOption.value)
              MenuItemWidget(
                icon: Iconsax.setting_2,
                title: AppStrings.settings.tr,
                onTap: controller.openSettings,
                showDivider: false,
              ),
          ],
        );
      }),
    );
  }
}
