import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../controllers/home_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  HomeController get controller => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          // 1. Map Layer (Static Image from Figma)
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapBackground,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Top Header (Address + Profile)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              children: [
                _buildModernAddressBox(),
                SizedBox(width: 12.w),
                _buildProfileIcon(),
              ],
            ),
          ),

          // 3. Floating Action Buttons (GPS)
          Positioned(
            bottom: 370.h, // Adjusted based on initial bottom sheet height
            right: 20.w,
            child: _buildGpsButton(),
          ),

          // 4. Interactive Bottom UI
          _buildFigmaDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildModernAddressBox() {
    return Expanded(
      child: Obx(() {
        if (controller.savedPlaces.isEmpty) {
          return Container(
            padding: EdgeInsets.all(12.w),
            height: 60.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: controller.isLoadingHomeData.value
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'No saved places',
                      style: AppTextStyles.homeSubtitle.copyWith(
                        color: AppColors.shade2,
                      ),
                    ),
            ),
          );
        }

        final placesToShow = controller.isSavedPlacesExpanded.value
            ? controller.savedPlaces
            : [controller.savedPlaces.first];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(placesToShow.length, (index) {
              final place = placesToShow[index];
              return InkWell(
                onTap: () {
                  controller.isSavedPlacesExpanded.toggle();
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == placesToShow.length - 1 ? 0 : 12.h,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  place.label ?? 'Place',
                                  style: AppTextStyles.homeSubtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.shade1,
                                  ),
                                ),
                                if (index == 0) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    controller.isSavedPlacesExpanded.value
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 18.sp,
                                    color: AppColors.shade2,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              place.address ??
                                  place.name ??
                                  'No address provided',
                              style: AppTextStyles.homeCaption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: () => Get.to(() => ProfileScreen()),
      child: Container(
        width: 64.w,
        height: 61.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFD3DDE7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.person, color: Colors.black, size: 28.sp),
        ),
      ),
    );
  }

  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: () => controller.recenterMap(),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SvgPicture.asset(
          AppAssets.icGps,
          width: 24.w,
          height: 24.w,
          colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildFigmaDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              SizedBox(height: 12.h),
              Center(
                child: Container(
                  width: 48.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(37.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Where to?',
                style: AppTextStyles.homeTitle.copyWith(fontSize: 20.sp),
              ),
              SizedBox(height: 16.h),
              // Search Bar
              GestureDetector(
                onTap: () => Get.toNamed('/location_search'),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Where are you going?',
                        style: AppTextStyles.homeSubtitle,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFigmaChip('Home', AppAssets.icHomeChip),
                    _buildFigmaChip('Office', AppAssets.icOfficeChip),
                    _buildFigmaChip('Work', AppAssets.icWorkChip),
                    _buildFigmaChip('Other', AppAssets.icOtherChip),
                  ],
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'Recent Location',
                style: AppTextStyles.homeTitle.copyWith(fontSize: 20.sp),
              ),
              SizedBox(height: 16.h),
              // Recent Locations List
              Obx(
                () => Column(
                  children: controller.recentDestinations
                      .map((loc) => _buildRecentLocationItem(loc))
                      .toList(),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Explore Vehicle',
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              // Vehicle List
              _buildVehicleHorizontalList(),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFigmaChip(String label, String iconPath) {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconPath, width: 20.w, height: 20.w),
          SizedBox(width: 8.w),
          Text(label, style: AppTextStyles.homeChip.copyWith(fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildRecentLocationItem(dynamic loc) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        children: [
          // Distance Badge
          Container(
            width: 52.w,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 20.sp,
                  color: AppColors.shade2,
                ),
                SizedBox(height: 4.h),
                Text(
                  '6 KM',
                  style: AppTextStyles.homeCaption.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.address.split(',').first,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.shade1,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  loc.address,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: AppColors.shade2,
                    fontSize: 13.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.favorite, color: const Color(0xFFE2E8F0), size: 24.sp),
        ],
      ),
    );
  }

  Widget _buildVehicleHorizontalList() {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: controller.vehicleTypes
              .map(
                (vehicle) =>
                    _buildVehicleCard(vehicle.displayName, vehicle.name),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(String label, String vehicleName) {
    String imagePath = 'assets/images/img_cab.png';
    final name = vehicleName.toLowerCase();
    if (name.contains('bike')) {
      imagePath = 'assets/images/img_boda.png';
    } else if (name.contains('auto') || name.contains('wheeler')) {
      imagePath = 'assets/images/img_bajaji.png';
    }

    return Container(
      margin: EdgeInsets.only(right: 16.w),
      child: Column(
        children: [
          Container(
            width: 86.w,
            height: 72.h,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: AppTextStyles.homeCaption.copyWith(
              color: AppColors.shade1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
