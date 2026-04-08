import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          // 1. Map Layer
          Positioned.fill(
            child: Obx(() => GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: controller.currentPosition.value,
                    zoom: 15,
                  ),
                  onMapCreated: controller.onMapCreated,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  markers: controller.markers,
                  polylines: controller.polylines,
                  // Apply map styles in controller
                )),
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
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: AppColors.primary, size: 20.sp),
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
                        'Home',
                        style: AppTextStyles.homeSubtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.shade1,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, size: 18.sp, color: AppColors.shade2),
                    ],
                  ),
                  Text(
                    'block number 23_B manik niwas...',
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
  }

  Widget _buildProfileIcon() {
    return Container(
      width: 52.w,
      height: 52.w,
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
        child: Icon(Icons.person_outline, color: AppColors.shade1, size: 24.sp),
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
          'assets/images/ic_gps.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildFigmaDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(37.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
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
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Where to?',
                style: AppTextStyles.homeTitle.copyWith(fontSize: 22.sp),
              ),
              SizedBox(height: 16.h),
              // Search Bar
              GestureDetector(
                onTap: () => Get.toNamed('/location_search'),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 20.sp),
                      SizedBox(width: 12.w),
                      Text(
                        'Where are you going?',
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: AppColors.shade2.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFigmaChip('Home', 'assets/images/ic_home_chip.svg'),
                    _buildFigmaChip('Office', 'assets/images/ic_office_chip.svg'),
                    _buildFigmaChip('Work', 'assets/images/ic_work_chip.svg'),
                    _buildFigmaChip('Other', 'assets/images/ic_other_chip.svg'),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Recent Location',
                style: AppTextStyles.homeTitle.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 16.h),
              // Recent Locations List
              Obx(() => Column(
                children: controller.recentDestinations.map((loc) => _buildRecentLocationItem(loc)).toList(),
              )),
              SizedBox(height: 24.h),
              Text(
                'Explore Vehicle',
                style: AppTextStyles.homeTitle.copyWith(fontSize: 18.sp),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconPath, width: 16.w, height: 16.w),
          SizedBox(width: 8.w),
          Text(label, style: AppTextStyles.homeChip),
        ],
      ),
    );
  }

  Widget _buildRecentLocationItem(dynamic loc) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          // Distance Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_car_outlined, size: 16.sp, color: AppColors.shade2),
                Text('6 KM', style: AppTextStyles.homeCaption.copyWith(fontSize: 10.sp)),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.address.split(',').first, style: AppTextStyles.homeSubtitle.copyWith(fontWeight: FontWeight.bold)),
                Text(loc.address, style: AppTextStyles.homeCaption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.favorite_border, color: AppColors.shade2, size: 24.sp),
        ],
      ),
    );
  }

  Widget _buildVehicleHorizontalList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildVehicleCard('Boda', 'assets/images/img_boda.png'),
          _buildVehicleCard('Bajaji', 'assets/images/img_bajaji.png'),
          _buildVehicleCard('Cab', 'assets/images/img_cab.png'),
          _buildVehicleCard('Cab Premium', 'assets/images/img_cab.png'),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(String label, String imagePath) {
    return Container(
      margin: EdgeInsets.only(right: 16.w),
      child: Column(
        children: [
          Container(
            width: 100.w,
            height: 80.h,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          SizedBox(height: 8.h),
          Text(label, style: AppTextStyles.homeCaption.copyWith(color: AppColors.shade1)),
        ],
      ),
    );
  }
}
