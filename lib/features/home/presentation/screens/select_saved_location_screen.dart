import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../controllers/home_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/utils/app_dialogs.dart';
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
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
    final args = Get.arguments;
    if (args is Map) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(args);
      label = data['label'] ?? AppStrings.searchLocation.tr;
    } else {
      label = args as String? ?? 'Home';
    }
    searchController = TextEditingController();

    // Clear previous suggestions and search query
    // Wrapped in addPostFrameCallback to avoid "setState() called during build" exception
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.searchQuery.value = '';
      controller.suggestions.clear();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canGoBack
            ? const AppBackButton(
                color: AppColors.textHeading,
                alignment: Alignment.center,
              )
            : null,
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
              child: Stack(
                children: [
                  Obx(() {
                    if (controller.isSearching.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.searchQuery.value.trim().isNotEmpty) {
                      return _buildSuggestionsList();
                    }

                    return _buildRecentList();
                  }),
                  if (_isGeocoding)
                    Container(
                      color: AppColors.white.withOpacity(0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.skeletonBase, width: 0.8),
      ),
      child: Center(
        child: TextField(
          controller: searchController,
          autofocus: true,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) => controller.searchQuery.value = value,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: AppColors.textHeading,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIconConstraints: BoxConstraints(minWidth: 32.w, minHeight: 0),
            prefixIcon: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Obx(
                () => controller.searchQuery.value.isEmpty
                    ? Icon(Icons.search, color: AppColors.textHint, size: 22.sp)
                    : SvgPicture.asset(
                        AppAssets.locationIcPickupPin,
                        width: 14.w,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
            hintText: AppStrings.searchLocation.tr,
            hintStyle: AppTextStyles.hint,
            border: InputBorder.none,
            suffixIconConstraints: BoxConstraints(minWidth: 40.w, minHeight: 0),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.cancel,
                        color: AppColors.textHint,
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
          AppStrings.noLocationsFound.tr,
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.textBody),
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
          AppStrings.noRecentLocations.tr,
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.textBody),
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
          onFavorite: () => controller.toggleFavoriteForRecent(loc),
        );
      },
    );
  }

  Widget _locationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onFavorite,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          // Subtle border/shadow as per image
          border: Border.all(color: AppColors.bgSoftCircle, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.01),
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
                color: AppColors.bgSoftCircle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time_outlined,
                color: AppColors.textHint,
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
                      color: AppColors.textHeading,
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.textBody,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onFavorite != null)
              IconButton(
                icon: Icon(
                  Icons.favorite_border,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
                onPressed: onFavorite,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLocationSelection(Prediction item) async {
    final title = item.description?.split(',').first ?? label;
    final subtitle = item.description ?? '';

    final args = Get.arguments;
    if (args is Map && args['isSelectingStop'] == true) {
      if (_isGeocoding) return;
      setState(() => _isGeocoding = true);
      try {
        final latLng = await controller.getLatLngFromAddress(subtitle);
        setState(() => _isGeocoding = false);

        if (latLng != null) {
          final result = await Get.toNamed(
            AppRoutes.confirmStop,
            arguments: {
              'address': subtitle,
              'lat': latLng.latitude,
              'lng': latLng.longitude,
            },
          );
          if (result != null) {
            Get.back(result: result);
          }
        } else {
          AppDialogs.showErrorDialog(
            message: 'Unable to get location coordinates',
          );
        }
      } catch (e) {
        setState(() => _isGeocoding = false);
        AppDialogs.showErrorDialog(message: 'Something went wrong: $e');
      }
      return;
    }

    // Show loading? Maybe, but geocoding is usually fast.
    final latLng = await controller.getLatLngFromAddress(subtitle);

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
  }

  Future<void> _handleRecentSelection(RecentDestinationModel loc) async {
    final title = loc.address.split(',').first;
    final subtitle = loc.address;

    final args = Get.arguments;
    if (args is Map && args['isSelectingStop'] == true) {
      final result = await Get.toNamed(
        AppRoutes.confirmStop,
        arguments: {'address': subtitle, 'lat': loc.lat, 'lng': loc.lng},
      );
      if (result != null) {
        Get.back(result: result);
      }
      return;
    }

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
  }
}
