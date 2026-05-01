import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/utils/phone_formatter.dart';

enum BookingMode { self, other }

class ConfirmPickupController extends GetxController {
  ConfirmPickupController({
    required this.homeRepository,
    required this.rideRepository,
  });

  final HomeRepository homeRepository;
  final RideRepository rideRepository;
  final selectedLatLng = const LatLng(-6.7924, 39.2083).obs;
  final address = ''.obs;
  final isResolvingAddress = false.obs;
  final isSubmitting = false.obs;

  final bookingMode = BookingMode.self.obs;
  final passengerName = ''.obs;
  final passengerPhone = ''.obs;
  final passengerNameError = RxnString();
  final passengerPhoneError = RxnString();
  late LatLng _initialLatLng;
  late String initialAddress;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  GoogleMapController? mapController;
  LatLng get initialLatLng => _initialLatLng;

  bool get hasMovedFromInitial =>
      (selectedLatLng.value.latitude - _initialLatLng.latitude).abs() >
          0.000001 ||
      (selectedLatLng.value.longitude - _initialLatLng.longitude).abs() >
          0.000001;

  @override
  void onInit() {
    super.onInit();
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final lat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
    final lng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
    selectedLatLng.value = LatLng(lat, lng);
    _initialLatLng = LatLng(lat, lng);
    initialAddress =
        (args['pickupAddress'] as String?)?.trim() ?? 'Selected pickup point';
    address.value = initialAddress;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    await controller.animateCamera(
      CameraUpdate.newLatLng(selectedLatLng.value),
    );
  }

  void onCameraMove(CameraPosition position) {
    selectedLatLng.value = position.target;
  }

  Future<void> onCameraIdle() async {
    // Keep the initially selected pickup address on first paint.
    if (!hasMovedFromInitial) return;

    final lat = selectedLatLng.value.latitude;
    final lng = selectedLatLng.value.longitude;
    isResolvingAddress.value = true;
    final result = await homeRepository.reverseGeocode(lat: lat, lng: lng);
    isResolvingAddress.value = false;

    result.fold((_) {}, (data) {
      final results = data.data?.results;
      final nextAddress = (results != null && results.isNotEmpty)
          ? results.first.formattedAddress
          : null;
      if (nextAddress != null && nextAddress.trim().isNotEmpty) {
        address.value = nextAddress.trim();
      }
    });
  }

  Future<void> confirmPickup() async {
    isSubmitting.value = true;

    try {
      // ── Book for Other Person Check ──
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 5), onTimeout: () => Position(
        latitude: selectedLatLng.value.latitude,
        longitude: selectedLatLng.value.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ));

      final checkResult = await rideRepository.checkBookMode(
        riderLat: position.latitude,
        riderLng: position.longitude,
        pickupLat: selectedLatLng.value.latitude,
        pickupLng: selectedLatLng.value.longitude,
      );

      bool cancelled = false;
      await checkResult.fold(
        (f) => null, // Ignore failure, proceed as self
        (res) async {
          if (res.showBookForOtherOption) {
            final mode = await _showBookingModeBottomSheet();
            if (mode == null) {
              cancelled = true;
              return;
            }
            bookingMode.value = mode;

            if (mode == BookingMode.other) {
              final details = await _showPassengerDetailsSheet();
              if (details == null) {
                cancelled = true;
                return;
              }
              passengerName.value = details['name'] ?? '';
              passengerPhone.value = _stripLeadingZero(details['phone'] ?? '');
            }
          }
        },
      );

      if (cancelled) {
        isSubmitting.value = false;
        return;
      }

      Get.back(
        result: {
          'pickupLat': selectedLatLng.value.latitude,
          'pickupLng': selectedLatLng.value.longitude,
          'pickupAddress': address.value.trim().isEmpty
              ? 'Selected pickup point'
              : address.value.trim(),
          'isBookedForOther': bookingMode.value == BookingMode.other,
          'passengerName': bookingMode.value == BookingMode.other ? passengerName.value : null,
          'passengerPhone': bookingMode.value == BookingMode.other ? passengerPhone.value : null,
        },
      );
    } catch (e) {
      // Fallback to self
      Get.back(
        result: {
          'pickupLat': selectedLatLng.value.latitude,
          'pickupLng': selectedLatLng.value.longitude,
          'pickupAddress': address.value.trim().isEmpty
              ? 'Selected pickup point'
              : address.value.trim(),
          'isBookedForOther': false,
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  String _stripLeadingZero(String phone) {
    final trimmed = phone.trim();
    return trimmed.startsWith('0') ? trimmed.substring(1) : trimmed;
  }

  Future<BookingMode?> _showBookingModeBottomSheet() async {
    return await Get.bottomSheet<BookingMode>(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Who is this ride for?",
              style: TextStyle(
                fontFamily: AppTextStyles.metropolisFont,
                fontWeight: FontWeight.w700,
                fontSize: 20.sp,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 30.h),
            _buildModeOption(
              icon: Iconsax.user,
              title: "Book for Myself",
              onTap: () => Get.back(result: BookingMode.self),
            ),
            SizedBox(height: 16.h),
            _buildModeOption(
              icon: Iconsax.user_add,
              title: "Book for Someone Else",
              onTap: () => Get.back(result: BookingMode.other),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorderDefault),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24.w),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTextStyles.metropolisFont,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: AppColors.textBody, size: 16.w),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showPassengerDetailsSheet() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await Get.bottomSheet<Map<String, String>>(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 30.h,
              bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 30.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Passenger Details",
                  style: TextStyle(
                    fontFamily: AppTextStyles.metropolisFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 24.h),
                Obx(() => AppTextField(
                      controller: nameController,
                      label: "Passenger Name",
                      hintText: "Enter full name",
                      errorText: passengerNameError.value,
                      onChanged: (_) => passengerNameError.value = null,
                    )),
                SizedBox(height: 16.h),
                Obx(() => AppTextField(
                      controller: phoneController,
                      label: "Passenger Phone",
                      hintText: "712 345 678",
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TanzaniaPhoneFormatter(),
                      ],
                      prefixIcon: Container(
                        width: 82.w,
                        padding: EdgeInsets.only(left: 14.w),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3.r),
                              child: SvgPictureAsset(
                                AppAssets.icTanzaniaFlag,
                                height: 14.h,
                                width: 22.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "+255",
                              style: TextStyle(
                                fontFamily: AppTextStyles.metropolisFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                      ),
                      errorText: passengerPhoneError.value,
                      onChanged: (_) => passengerPhoneError.value = null,
                    )),
                SizedBox(height: 30.h),
                AppPrimaryButton(
                  label: "Confirm",
                  onPressed: () {
                    final name = nameController.text.trim();
                    final rawPhone = phoneController.text.replaceAll(' ', '');

                    bool valid = true;
                    if (name.isEmpty) {
                      passengerNameError.value = "Name is required";
                      valid = false;
                    }
                    if (rawPhone.isEmpty) {
                      passengerPhoneError.value = "Phone is required";
                      valid = false;
                    } else {
                      final stripped = _stripLeadingZero(rawPhone);
                      if (stripped.length < 9 || stripped.length > 10) {
                        passengerPhoneError.value =
                            "Enter a valid Tanzanian phone number";
                        valid = false;
                      }
                    }

                    if (valid) {
                      Get.back(result: {
                        'name': name,
                        'phone': '255${_stripLeadingZero(rawPhone)}',
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
