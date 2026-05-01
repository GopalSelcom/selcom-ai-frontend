import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../controllers/favorite_locations_controller.dart';

class FavoriteLocationsScreen extends GetView<FavoriteLocationsController> {
  const FavoriteLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.favouriteLocations.tr),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPictureAsset(
                        AppAssets.locationIcHeartOutline,
                        width: 64.w,
                        height: 64.h,
                        color: AppColors.iconHeartOutline,
                        placeholderBuilder: (_) => Icon(
                          Icons.favorite_border,
                          size: 64.sp,
                          color: AppColors.iconHeartOutline,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.noFavoriteLocationsYet.tr,
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchFavorites,
                child: ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: controller.favorites.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final place = controller.favorites[index];
                    return _locationTile(place);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _locationTile(SavedPlace place) {
    return InkWell(
      onTap: () => controller.onLocationSelected(place),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.w,
              backgroundColor: AppColors.bgSuccessBanner,
              child: SvgPictureAsset(
                AppAssets.locationIcPickupPin,
                width: 20.w,
                height: 20.h,
                color: AppColors.mapDropMarkerGreen,
                placeholderBuilder: (_) => Icon(
                  Icons.location_on,
                  color: AppColors.mapDropMarkerGreen,
                  size: 22.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (place.label ?? 'Location').capitalizeFirst ?? 'Location',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    place.address ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textBody,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => controller.toggleFavorite(place),
              icon: SvgPictureAsset(
                AppAssets.locationIcHeartFilled,
                width: 24.w,
                height: 24.h,
                color: AppColors.iconHeartFilled,
                placeholderBuilder: (_) => Icon(
                  Icons.favorite,
                  color: AppColors.iconHeartFilled,
                  size: 24.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
