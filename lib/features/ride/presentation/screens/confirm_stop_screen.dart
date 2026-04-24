import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/map_widgets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../home/presentation/controllers/home_controller.dart';

class ConfirmStopScreen extends StatefulWidget {
  const ConfirmStopScreen({super.key});

  @override
  State<ConfirmStopScreen> createState() => _ConfirmStopScreenState();
}

class _ConfirmStopScreenState extends State<ConfirmStopScreen> {
  late final HomeController controller;
  late final String address;
  late final double lat;
  late final double lng;

  final RxString _resolvedAddress = ''.obs;
  final RxDouble _currentLat = 0.0.obs;
  final RxDouble _currentLng = 0.0.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
    final args = Get.arguments;
    final Map<String, dynamic> data = args is Map
        ? Map<String, dynamic>.from(args)
        : {};
    address = data['address']?.toString() ?? '';
    lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    lng = (data['lng'] as num?)?.toDouble() ?? 0.0;

    _resolvedAddress.value = address;
    _currentLat.value = lat;
    _currentLng.value = lng;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AppGoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLat.value, _currentLng.value),
                zoom: 16,
              ),
              onMapCreated: (mapController) {
                // Not using home controller's map logic to avoid side effects
              },
              onCameraMove: (position) {
                _currentLat.value = position.target.latitude;
                _currentLng.value = position.target.longitude;
              },
              onCameraIdle: () async {
                // Resolve address at pin
                final result = await controller.homeRepository.reverseGeocode(
                  lat: _currentLat.value,
                  lng: _currentLng.value,
                );
                result.fold((_) => null, (data) {
                  final formatted =
                      data.data?.results?.firstOrNull?.formattedAddress ?? "";
                  if (formatted.isNotEmpty) {
                    _resolvedAddress.value = formatted;
                  }
                });
              },
              padding: EdgeInsets.only(bottom: 250.h),
              markers: const {},
            ),
          ),

          // Pin Overlay
          Positioned.fill(
            bottom: 250.h,
            child: IgnorePointer(
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // The line and bubble positioned relative to the dot
                    Positioned(
                      bottom: 6.w, // Half of dot size to start from dot center
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Text(
                              AppStrings.stopLocation.tr,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            width: 2.w,
                            height: 20.h,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 6.w), // Match dot radius
                        ],
                      ),
                    ),
                    // The Dot (placed exactly at center)
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 16.w,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.shade1),
                onPressed: () => Get.back(),
              ),
            ),
          ),

          // Bottom Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, color: AppColors.primary, size: 24.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Obx(
                          () => Text(
                            _resolvedAddress.value,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(
                          result: {
                            'address': _resolvedAddress.value,
                            'lat': _currentLat.value,
                            'lng': _currentLng.value,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'Confirm Stop',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
