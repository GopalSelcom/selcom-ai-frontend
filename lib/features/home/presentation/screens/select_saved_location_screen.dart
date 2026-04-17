import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/home_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/places_models.dart';
import '../../../ride/data/models/ride_management_models.dart';

class SelectSavedLocationScreen extends StatefulWidget {
  const SelectSavedLocationScreen({super.key});

  @override
  State<SelectSavedLocationScreen> createState() =>
      _SelectSavedLocationScreenState();
}

class _SelectSavedLocationScreenState extends State<SelectSavedLocationScreen> {
  late final HomeController controller;
  late final TextEditingController searchController;
  late final String label;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
    label = Get.arguments as String? ?? 'Home';
    searchController = TextEditingController();

    // Clear previous suggestions and search query
    controller.searchQuery.value = '';
    controller.suggestions.clear();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.shade1),
          onPressed: () => Get.back(),
        ),
        title: Text(
          label,
          style: AppTextStyles.homeTitle.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            _buildSearchBar(),
            SizedBox(height: 16.h),
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.searchQuery.value.trim().isNotEmpty) {
                  return _buildSuggestionsList();
                }

                return _buildRecentList();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      height: 54.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Center(
        child: TextField(
          controller: searchController,
          autofocus: true,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) => controller.searchQuery.value = value,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: AppColors.shade1,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIconConstraints: BoxConstraints(minWidth: 32.w, minHeight: 0),
            prefixIcon: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Obx(
                () => controller.searchQuery.value.isEmpty
                    ? Icon(
                        Icons.search,
                        color: const Color(0xFF94A3B8),
                        size: 22.sp,
                      )
                    : SvgPicture.asset(
                        AppAssets.locationIcPin,
                        width: 14.w,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
            hintText: 'Search location...',
            hintStyle: AppTextStyles.homeSubtitle.copyWith(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            suffixIconConstraints: BoxConstraints(minWidth: 40.w, minHeight: 0),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.cancel,
                        color: const Color(0xFF94A3B8),
                        size: 20.sp,
                      ),
                      onPressed: () {
                        searchController.clear();
                        controller.searchQuery.value = '';
                        controller.suggestions.clear();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (controller.suggestions.isEmpty) {
      return Center(
        child: Text(
          'No locations found',
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.shade2),
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.suggestions.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = controller.suggestions[index];
        final description = item.description ?? '';
        final title = description.split(',').first;

        return _locationTile(
          title: title,
          subtitle: description,
          onTap: () => _handleLocationSelection(item),
        );
      },
    );
  }

  Widget _buildRecentList() {
    if (controller.recentDestinations.isEmpty &&
        controller.savedPlaces.isEmpty) {
      return Center(
        child: Text(
          'No recent locations',
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.shade2),
        ),
      );
    }

    final recentItems = controller.recentDestinations;

    return ListView.separated(
      itemCount: recentItems.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final loc = recentItems[index];
        return _locationTile(
          title: loc.address.split(',').first,
          subtitle: loc.address,
          onTap: () => _handleRecentSelection(loc),
        );
      },
    );
  }

  Widget _locationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          // Subtle border/shadow as per image
          border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                Icons.access_time_outlined,
                color: const Color(0xFF94A3B8),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.shade1,
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.shade2,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
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
    );
  }

  Future<void> _handleLocationSelection(Prediction item) async {
    final title = item.description?.split(',').first ?? label;
    final subtitle = item.description ?? '';

    // Show loading? Maybe, but geocoding is usually fast.
    final latLng = await controller.getLatLngFromAddress(subtitle);

    _showConfirmationDialog(
      title: title,
      subtitle: subtitle,
      onConfirm: () {
        Get.back(); // Close dialog
        Get.toNamed(
          AppRoutes.checkPickupPoint,
          arguments: {
            'label': label,
            'title': title,
            'subtitle': subtitle,
            'placeId': item.placeId ?? '',
            if (latLng != null) 'lat': latLng.latitude,
            if (latLng != null) 'lng': latLng.longitude,
          },
        );
      },
    );
  }

  Future<void> _handleRecentSelection(RecentDestinationModel loc) async {
    final title = loc.address.split(',').first;
    final subtitle = loc.address;

    _showConfirmationDialog(
      title: title,
      subtitle: subtitle,
      onConfirm: () {
        Get.back(); // Close dialog
        Get.toNamed(
          AppRoutes.checkPickupPoint,
          arguments: {
            'label': label,
            'title': title,
            'subtitle': subtitle,
            'placeId': '',
            'lat': loc.lat,
            'lng': loc.lng,
          },
        );
      },
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
            color: Colors.white,
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
                      color: const Color(0xFFECFDF5),
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
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                color: AppColors.shade1,
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
                      'Are you sure you want to add this address as a $label?',
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.locationIcPin,
                            width: 16.w,
                            colorFilter: const ColorFilter.mode(
                              AppColors.primary,
                              BlendMode.srcIn,
                            ),
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
                                    color: AppColors.shade1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.homeCaption.copyWith(
                                    color: AppColors.shade2,
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          elevation: 0,
                        ),
                        onPressed: onConfirm,
                        child: Text(
                          'Yes',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        onPressed: () => Get.back(),
                        child: Text(
                          'Change Location',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.shade2,
                            fontWeight: FontWeight.w500,
                          ),
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

    return SvgPicture.asset(
      asset,
      width: 16.w,
      colorFilter: const ColorFilter.mode(
        Color(0xFFB45309), // Amber-ish color for icons in the image
        BlendMode.srcIn,
      ),
    );
  }
}
