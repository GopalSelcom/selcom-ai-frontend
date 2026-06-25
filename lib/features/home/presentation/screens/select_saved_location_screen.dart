import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../controllers/home_controller.dart';
import '../controllers/select_saved_location_controller.dart';
import '../widgets/favorite_icon_button.dart';
import '../widgets/select_saved_location_screen_shimmer.dart';

class SelectSavedLocationScreen extends GetView<SelectSavedLocationController> {
  const SelectSavedLocationScreen({super.key});

  HomeController get homeController => controller.homeController;

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.translucent,
      child: AppScaffold(
        backgroundColor: AppColors.cardBackground,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: canGoBack
              ? const AppBackButton(
                  color: AppColors.textHeading,
                  alignment: Alignment.center,
                )
              : null,
          title: Text(controller.label),
        ),
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
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
                        final query = homeController.searchQuery.value.trim();

                        if (query.isNotEmpty) {
                          if (homeController.isSearching.value) {
                            return SelectSavedLocationScreenShimmer
                                .suggestionsList();
                          }
                          return _buildSuggestionsList();
                        }

                        if (homeController.isLoadingHomeData.value &&
                            homeController.recentDestinations.isEmpty) {
                          return SelectSavedLocationScreenShimmer.recentList();
                        }

                        return _buildRecentList();
                      }),
                      Obx(
                        () => controller.isGeocoding.value
                            ? Container(
                                color: AppColors.white.withValues(alpha: 0.5),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      height: 54.h,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
      ),
      child: Center(
        child: TextField(
          controller: controller.searchController,
          autofocus: true,
          textAlignVertical: TextAlignVertical.center,
          onChanged: controller.onSearchChanged,
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
                () => homeController.searchQuery.value.isEmpty
                    ? Icon(Icons.search, color: AppColors.textHint, size: 22.sp)
                    : SvgPictureAsset(
                        AppAssets.locationIcPickupPin,
                        width: 14.w,
                        color: AppColors.primary,
                      ),
              ),
            ),
            hintText: AppStrings.searchLocation.tr,
            hintStyle: AppTextStyles.hint,
            border: InputBorder.none,
            suffixIconConstraints: BoxConstraints(minWidth: 40.w, minHeight: 0),
            suffixIcon: Obx(
              () => homeController.searchQuery.value.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.cancel,
                        color: AppColors.textHint,
                        size: 20.sp,
                      ),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (homeController.suggestions.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noLocationsFound.tr,
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.textBody),
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: homeController.suggestions.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = homeController.suggestions[index];
        final description = item.description ?? '';
        final title = description.split(',').first;

        return _locationTile(
          title: title,
          subtitle: description,
          onTap: () => controller.handleLocationSelection(item),
        );
      },
    );
  }

  Widget _buildRecentList() {
    if (homeController.recentDestinations.isEmpty &&
        homeController.savedPlaces.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noRecentLocations.tr,
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.textBody),
        ),
      );
    }

    final recentItems = homeController.recentDestinations;

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: recentItems.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final loc = recentItems[index];
        return Obx(() {
          final savedPlace = homeController.getSavedPlaceFor(loc.address, null);
          final isFavorite = savedPlace?.isFavourite ?? false;
          return _locationTile(
            title: loc.address.split(',').first,
            subtitle: loc.address,
            onTap: () => controller.handleRecentSelection(loc),
            onFavorite: () => homeController.toggleFavoriteForRecent(loc),
            isFavorite: isFavorite,
          );
        });
      },
    );
  }

  Widget _locationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onFavorite,
    bool isFavorite = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderWalletCard, width: 0.5),
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
              child: SvgPictureAsset(
                AppAssets.locationIcTime,
                width: 20.w,
                height: 20.h,
                color: AppColors.textHint,
                placeholderBuilder: (_) => Icon(
                  Icons.access_time_outlined,
                  color: AppColors.textHint,
                  size: 20.sp,
                ),
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
              FavoriteIconButton(isFavorite: isFavorite, onPressed: onFavorite),
          ],
        ),
      ),
    );
  }
}
