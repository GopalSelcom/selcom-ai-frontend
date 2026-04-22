import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../controllers/favorite_locations_controller.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';

class FavoriteLocationsScreen extends GetView<FavoriteLocationsController> {
  const FavoriteLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const AppProfileHeader(title: 'Favourite Locations'),
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
                      Icon(
                        Icons.favorite_border,
                        size: 64.sp,
                        color: AppColors.shade2.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No favorite locations yet',
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: AppColors.shade2,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
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
                children: [
                  Text(
                    (place.label ?? 'Location').capitalizeFirst ?? 'Location',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.shade1,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    place.address ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.shade2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => controller.toggleFavorite(place),
              icon: const Icon(Icons.favorite, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
