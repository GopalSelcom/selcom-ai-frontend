import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../home/domain/repositories/home_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_animated_reveal.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/utils/tanzania_phone_validation.dart';
import '../../domain/repositories/ride_repository.dart';

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
  final TextEditingController noteForDriverController =
      TextEditingController();
  late final VoidCallback _pickupNoteListener;
  late LatLng _initialLatLng;
  late String initialAddress;

  /// Drives Obx for pickup note chip (TextEditingController is not reactive).
  final noteChipRevision = 0.obs;
  final isPickupNoteExpanded = false.obs;

  GoogleMapController? mapController;

  LatLng get initialLatLng => _initialLatLng;
  static const double _pickupMoveThreshold = 0.00005;

  bool get hasMovedFromInitial =>
      (selectedLatLng.value.latitude - _initialLatLng.latitude).abs() >
          _pickupMoveThreshold ||
      (selectedLatLng.value.longitude - _initialLatLng.longitude).abs() >
          _pickupMoveThreshold;

  void togglePickupNoteExpanded() {
    isPickupNoteExpanded.value = !isPickupNoteExpanded.value;
    if (!isPickupNoteExpanded.value) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void onClose() {
    noteForDriverController.removeListener(_pickupNoteListener);
    noteForDriverController.dispose();
    super.onClose();
  }

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

    _pickupNoteListener = () {
      if (isClosed) return;
      noteChipRevision.value++;
    };
    noteForDriverController.addListener(_pickupNoteListener);
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
      if (data == null) return;
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
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => Position(
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
            ),
          );

      // Server may use this for analytics / policy; UI always asks locally.
      await rideRepository.checkBookMode(
        riderLat: position.latitude,
        riderLng: position.longitude,
        pickupLat: selectedLatLng.value.latitude,
        pickupLng: selectedLatLng.value.longitude,
      );

      final mode = await _showBookingForSomeoneElseSheet();
      if (mode == null) {
        return;
      }
      bookingMode.value = mode;

      if (mode == BookingMode.other) {
        final details = await _showPassengerDetailsSheet();
        if (details == null) {
          return;
        }
        passengerName.value = details['name']!.trim();
        passengerPhone.value = details['phone']!;
        // Let the passenger bottom-sheet overlay finish disposing before popping
        // the route; otherwise duplicate _OverlayEntryWidgetState keys can occur.
        await SchedulerBinding.instance.endOfFrame;
      } else {
        passengerName.value = '';
        passengerPhone.value = '';
      }

      Get.back(
        result: {
          'pickupLat': selectedLatLng.value.latitude,
          'pickupLng': selectedLatLng.value.longitude,
          'pickupAddress': address.value.trim().isEmpty
              ? 'Selected pickup point'
              : address.value.trim(),
          'note': noteForDriverController.text.trim(),
          'isBookedForOther': bookingMode.value == BookingMode.other,
          'passengerName': bookingMode.value == BookingMode.other
              ? passengerName.value.trim()
              : null,
          'passengerPhone': bookingMode.value == BookingMode.other
              ? passengerPhone.value
              : null,
        },
      );
    } catch (e) {
      Get.back(
        result: {
          'pickupLat': selectedLatLng.value.latitude,
          'pickupLng': selectedLatLng.value.longitude,
          'pickupAddress': address.value.trim().isEmpty
              ? 'Selected pickup point'
              : address.value.trim(),
          'note': noteForDriverController.text.trim(),
          'isBookedForOther': false,
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<BookingMode?> _showBookingForSomeoneElseSheet() async {
    return Get.bottomSheet<BookingMode>(
      SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.bookingForSomeoneElsePrompt.tr,
                textAlign: TextAlign.start,
                style: AppTextStyles.homeTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: AppColors.textHeading,
                  height: 20 / 18,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                AppStrings.bookingForSomeoneElseSubtitle.tr,
                textAlign: TextAlign.start,
                style: AppTextStyles.homeCaption.copyWith(
                  color: AppColors.textBody,
                  fontSize: 12.sp,
                  height: 20 / 12,
                ),
              ),
              SizedBox(height: 20.h),
              _bookingChoiceRow(
                icon: Iconsax.user,
                title: AppStrings.bookingRideOptionForMe.tr,
                onTap: () => Get.back(result: BookingMode.self),
              ),
              SizedBox(height: 12.h),
              _bookingChoiceRow(
                icon: Iconsax.user_add,
                title: AppStrings.bookingRideOptionForSomeoneElse.tr,
                onTap: () => Get.back(result: BookingMode.other),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _bookingChoiceRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textBody,
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showPassengerDetailsSheet() async {
    return Get.bottomSheet<Map<String, String>?>(
      const _PassengerDetailsBottomSheet(),
      isScrollControlled: true,
    );
  }
}

class _PassengerDetailsBottomSheet extends StatefulWidget {
  const _PassengerDetailsBottomSheet();

  @override
  State<_PassengerDetailsBottomSheet> createState() =>
      _PassengerDetailsBottomSheetState();
}

class _PassengerDetailsBottomSheetState extends State<_PassengerDetailsBottomSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onFieldsChanged);
    _phone.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });
  }

  bool get _canConfirm =>
      _name.text.trim().isNotEmpty &&
      TanzaniaPhoneValidation.isCompleteValid(_phone.text);

  @override
  void dispose() {
    _name.removeListener(_onFieldsChanged);
    _phone.removeListener(_onFieldsChanged);
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onConfirmPressed() {
    final trimmedName = _name.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _nameError = AppStrings.nameIsRequired.tr;
      });
      return;
    }

    final e164 = TanzaniaPhoneValidation.e164DigitsOrNull(_phone.text);
    if (e164 == null) {
      setState(() {
        _phoneError = _phone.text.trim().isEmpty
            ? AppStrings.notificationPhoneRequired.tr
            : AppStrings.pleaseEnterAValidPhoneNumber.tr;
      });
      return;
    }

    Get.back(
      result: {'name': trimmedName, 'phone': e164},
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomReserve = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom
        : mq.padding.bottom;
    final maxSheetHeight = (mq.size.height -
            mq.viewPadding.top -
            bottomReserve -
            16)
        .clamp(160.0, mq.size.height);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: mq.size.width,
          maxHeight: maxSheetHeight,
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.passengerDetailsTitle.tr,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.notificationPhoneSubtitle.tr,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: AppColors.textBody,
                    fontSize: 14.sp,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 20.h),
                AppTextField(
                  controller: _name,
                  label: AppStrings.passengerNameLabel.tr,
                  hintText: AppStrings.enterPassengerFullName.tr,
                  keyboardType: TextInputType.name,
                  errorText: _nameError,
                  onChanged: (_) {},
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _phone,
                  label: AppStrings.passengerPhoneLabel.tr,
                  hintText: PhoneNationalRules.hintForIso(
                    TanzaniaPhoneValidation.iso2,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: PhoneNationalRules.inputFormattersForIso(
                    TanzaniaPhoneValidation.iso2,
                  ),
                  prefixIcon: Container(
                    width: 82.w,
                    padding: EdgeInsets.only(left: 14.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                          '+255',
                          style: AppTextStyles.homeSubtitle.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ],
                    ),
                  ),
                  errorText: _phoneError,
                  onChanged: (_) {},
                ),
                AppAnimatedReveal(
                  show: _canConfirm,
                  visibleKey: const ValueKey('passenger_details_confirm_on'),
                  hiddenKey: const ValueKey('passenger_details_confirm_off'),
                  child: Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: AppPrimaryButton(
                      label: AppStrings.confirm.tr,
                      onPressed: _onConfirmPressed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
