import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  HomeController get controller => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Layer
          Obx(() => GoogleMap(
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
              )),

          // 2. Top Floating Navigation
          Positioned(
            top: 60.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              children: [
                _buildAddressBox(),
                SizedBox(width: 12.w),
                _buildProfileButton(),
              ],
            ),
          ),

          // 3. Location Re-center Button
          Positioned(
            bottom: 380.h, // Positioned above the bottom sheet
            right: 20.w,
            child: _buildLocationButton(),
          ),

          // 4. Main Bottom UI
          _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildAddressBox() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.dg),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: Colors.green, size: 20.sp),
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
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, size: 20.sp, color: Colors.black54),
                    ],
                  ),
                  Text(
                    'block number 23_B manik niwas...',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
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

  Widget _buildProfileButton() {
    return Container(
      width: 56.dg,
      height: 56.dg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(Icons.person, color: Colors.black, size: 24.sp),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      padding: EdgeInsets.all(12.dg),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(Icons.my_location, color: Colors.black, size: 24.sp),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.42,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            children: [
              SizedBox(height: 12.h),
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Where to?',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              _buildSearchInput(),
              SizedBox(height: 16.h),
              _buildQuickChips(),
              SizedBox(height: 24.h),
              _buildSectionHeader('Recent Location'),
              SizedBox(height: 12.h),
              Obx(() {
                if (controller.isLoadingHomeData.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.recentDestinations.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Text('No recent locations found', style: TextStyle(color: Colors.grey)),
                  );
                }
                return _buildRecentList();
              }),
              SizedBox(height: 24.h),
              _buildSectionHeader('Explore Vehicle'),
              SizedBox(height: 16.h),
              Obx(() {
                if (controller.isLoadingHomeData.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildVehicleList();
              }),
              SizedBox(height: 40.h), // Safe area bottom
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, color: Colors.green, size: 20.sp),
          SizedBox(width: 12.w),
          Text(
            'Where are you going?',
            style: TextStyle(color: Colors.black38, fontSize: 16.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('Home', '🏠'),
          _buildChip('Office', '🏢'),
          _buildChip('Other', '🏦'),
          _buildChip('Work', '👑'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String emoji) {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildRecentList() {
    return Column(
      children: controller.recentDestinations.map((destination) {
        return _buildRecentItem(
          destination.address.split(',').first,
          destination.address,
          'Recently', // We could calculate distance if we had current loc
          false,
        );
      }).toList(),
    );
  }

  Widget _buildRecentItem(String title, String subtitle, String distance, bool isFav) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.dg),
            decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
            child: Icon(Icons.access_time, color: Colors.black45, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                Text(subtitle, style: TextStyle(color: Colors.black38, fontSize: 13.sp), maxLines: 1),
                Text(distance, style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 12.sp)),
              ],
            ),
          ),
          Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.black26),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: controller.vehicleTypes.map((type) {
          return _buildVehicleItem(
            type.label,
            type.imageUrl.startsWith('assets') ? type.imageUrl : 'assets/images/gari.png',
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVehicleItem(String label, String image) {
    return Column(
      children: [
        Container(
          width: 75.w,
          height: 60.h,
          padding: EdgeInsets.all(4.dg),
          child: Image.asset(image, fit: BoxFit.contain),
        ),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
