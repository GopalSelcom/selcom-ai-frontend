import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/map_widgets.dart';
import '../../../../core/routes/app_routes.dart';
import '../controllers/home_controller.dart';

class CheckPickupPointScreen extends StatefulWidget {
  const CheckPickupPointScreen({super.key});

  @override
  State<CheckPickupPointScreen> createState() => _CheckPickupPointScreenState();
}

class _CheckPickupPointScreenState extends State<CheckPickupPointScreen> {
  late final HomeController controller;
  late final Map<String, dynamic> args;
  late final String label;
  late final String placeId;

  // Reactive state for map-driven location
  final RxString _title = ''.obs;
  final RxString _subtitle = ''.obs;
  final RxDouble _lat = 0.0.obs;
  final RxDouble _lng = 0.0.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
    args = Get.arguments as Map<String, dynamic>? ?? {};
    label = args['label'] ?? AppStrings.homeLabel.tr;
    _title.value = args['title'] ?? '';
    _subtitle.value = args['subtitle'] ?? '';
    _lat.value = args['lat'] ?? controller.mapCenter.value.latitude;
    _lng.value = args['lng'] ?? controller.mapCenter.value.longitude;
    placeId = args['placeId'] ?? '';

    // Sync controller's map center to prevent auto-jump in onMapCreated
    // Wrapped in addPostFrameCallback to avoid "setState() called during build" exception
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.mapCenter.value = LatLng(_lat.value, _lng.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: AppGoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_lat.value, _lng.value),
                zoom: 16,
              ),
              onMapCreated: (mapController) {
                controller.onMapCreated(mapController);
              },
              onCameraMove: (position) {
                _lat.value = position.target.latitude;
                _lng.value = position.target.longitude;
              },
              onCameraIdle: () async {
                await controller.onCameraIdle();
                _subtitle.value = controller.currentMapAddress.value;
              },
              padding: EdgeInsets.only(bottom: 350.h),
              markers: const {},
            ),
          ),

          // Custom "Pickup point" overlay precisely centered on the visible map area
          Positioned.fill(
            bottom: 350.h, // Match the map padding to align visually
            child: IgnorePointer(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // This dot is centered exactly on the map's target LatLng
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // The rest of the UI is positioned relative to the centered dot
                    Positioned(
                      bottom: 4.h, // Starts from the center of the dot
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              AppStrings.pickupPoint.tr,
                              style: AppTextStyles.homeCaption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            width: 2.w,
                            height: 12.h,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Back Button
          if (canGoBack)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.h,
              left: 16.w,
              child: CircleAvatar(
                backgroundColor: AppColors.cardBackground,
                child: AppBackButton(
                  color: AppColors.textHeading,
                  alignment: Alignment.center,
                  size: 22.w,
                  hitSize: 40.w,
                ),
              ),
            ),

          // Bottom Sheet
          Align(alignment: Alignment.bottomCenter, child: _buildBottomSheet()),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 50.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                        color: AppColors.bgMintLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.place,
                        color: AppColors.successMint,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.checkYourPickupPoint.tr,
                            style: AppTextStyles.homeTitle.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            AppStrings.selectANearbyPointForEasierPickup.tr,
                            style: AppTextStyles.homeCaption.copyWith(
                              color: AppColors.textBody,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Address Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.bgSoftCircle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title.value,
                                style: AppTextStyles.homeSubtitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textHeading,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _subtitle.value,
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.textBody,
                                  fontSize: 13.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    label: AppStrings.confirmPickup.tr,
                    height: 56.h,
                    iconAsset: AppAssets.locationIcArrowRight,
                    iconColor: AppColors.white,
                    onPressed: () {
                      _showConfirmationDialog(
                        title: _title.value,
                        subtitle: _subtitle.value,
                        onConfirm: () async {
                          await controller.savePlace(
                            label: label,
                            name: _title.value,
                            placeId: placeId,
                            lat: _lat.value,
                            lng: _lng.value,
                          );
                          // Navigate back to the most relevant previous screen
                          Get.until(
                            (route) =>
                                route.settings.name ==
                                    AppRoutes.locationSelection ||
                                route.settings.name == AppRoutes.home ||
                                route.isFirst,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String subtitle,
    required VoidCallback onConfirm,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Green Circle and Label Badge
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 120.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bgMintLight,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: const BoxDecoration(
                          color: AppColors.successMint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 40.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _getLabelIcon(),
                            SizedBox(width: 8.w),
                            Text(
                              label,
                              style: AppTextStyles.homeSubtitle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Text(
                      AppStrings.areYouSureYouWantToAddThisAddressAs.trParams({
                        'label': label,
                      }),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeTitle.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Address Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.bgSoftCircle),
                      ),
                      child: Row(
                        children: [
                          SvgPictureAsset(
                            AppAssets.locationIcPickupPin,
                            width: 16.w,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.homeSubtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textHeading,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.homeCaption.copyWith(
                                    color: AppColors.textBody,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: Obx(
                        () => AppPrimaryButton(
                          label: AppStrings.yes.tr,
                          height: 50.h,
                          borderRadius: 25.r,
                          isLoading: controller.isSavingPlace.value,
                          onPressed: controller.isSavingPlace.value
                              ? null
                              : onConfirm,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: Obx(
                        () => AppPrimaryButton(
                          label: AppStrings.changeLocation.tr,
                          height: 50.h,
                          borderRadius: 25.r,
                          outlined: true,
                          backgroundColor: AppColors.white,
                          textColor: AppColors.textBody,
                          outlinedTextColor: AppColors.textBody,
                          outlinedBorderColor: AppColors.skeletonBase,
                          outlinedBorderWidth: 1,
                          onPressed: controller.isSavingPlace.value
                              ? null
                              : () => Get.back(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _getLabelIcon() {
    String asset = AppAssets.icHomeChip;
    if (label.toLowerCase() == 'work') asset = AppAssets.icWorkChip;
    if (label.toLowerCase() == 'office') asset = AppAssets.icOfficeChip;
    if (label.toLowerCase() == 'other') asset = AppAssets.icOtherChip;

    return SvgPictureAsset(
      asset,
      width: 16.w,
      color: AppColors.iconAmber,
    );
  }
}
