import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/bottom_inset_helper.dart';
import '../../../../core/widgets/app_adaptive_bottom_safe_scaffold.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../controllers/home_controller.dart';
import '../widgets/recent_location_tile.dart';
import '../widgets/recent_locations_screen_shimmer.dart';

class RecentLocationsScreen extends GetView<HomeController> {
  const RecentLocationsScreen({super.key});

  double _navBottomPadding(BuildContext context) {
    return BottomInsetHelper.instance.resolveBodyOnlyBottomSafeAreaInset(
      context,
      hasFooter: false,
      hasBottomWidget: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveBottomSafeScaffold(
      backgroundColor: AppColors.white,
      liftBodyForKeyboard: false,
      pinnedHeader: AppProfileHeader(title: AppStrings.recentLocation.tr),
      body: RefreshIndicator(
        onRefresh: controller.refreshRecentDestinations,
        child: Obx(() {
          final navBottomPad = _navBottomPadding(context);
          final items = controller.recentDestinationsScreen;
          if (controller.isLoadingRecentLocationsScreen.value &&
              items.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(bottom: navBottomPad),
              child: RecentLocationsScreenShimmer.listContent(),
            );
          }

          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 28.h + navBottomPad),
              children: [
                Text(
                  AppStrings.noRecentLocationsFound.tr,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: AppColors.textBody,
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 20.h + navBottomPad),
            itemCount: items.length,
            separatorBuilder: (context, index) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1.h, color: AppColors.bgSoftCircle),
                SizedBox(height: 20.h),
              ],
            ),
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
        onTap: () =>
            controller.navigateToVehicleSelectionForRecentDestination(loc),
        onFavoriteTap: () => controller.toggleFavoriteForRecent(loc),
      );
    });
  }
}
