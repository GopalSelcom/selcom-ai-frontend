import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../controllers/home_controller.dart';
import '../widgets/recent_location_tile.dart';

class RecentLocationsScreen extends GetView<HomeController> {
  const RecentLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textHeading,
        title: Text(
          AppStrings.recentLocation.tr,
          style: AppTextStyles.homeSubtitle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshRecentDestinations,
        child: Obx(() {
          final items = controller.recentDestinations;
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
              children: [
                Text(
                  'No recent locations found',
                  style: AppTextStyles.homeCaption.copyWith(
                    color: AppColors.textBody,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildRecentLocationItem(items[index]),
          );
        }),
      ),
    );
  }

  Widget _buildRecentLocationItem(RecentDestinationModel loc) {
    return Obx(() {
      final distance = controller.calculateDistanceKm(loc.lat, loc.lng);
      final savedPlace = controller.getSavedPlaceFor(loc.address, null);
      final isFavorite = savedPlace?.isFavourite ?? false;
      return RecentLocationTile(
        title: controller.recentDestinationTitleLine(loc),
        address: loc.address,
        distance: distance,
        isFavorite: isFavorite,
        onTap: () => controller.navigateToVehicleSelectionForRecentDestination(loc),
        onFavoriteTap: () => controller.toggleFavoriteForRecent(loc),
      );
    });
  }
}
