import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/data/models/responses/get_saved_places_response.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../utils/favorite_location_chip_catalog.dart';
import 'app_saved_place_chip.dart';

/// Horizontal row of four presets (Home, Office, Work, Other): category icon when
/// saved, add icon when empty. Behavior is delegated via callbacks (Home vs Location Selection).
///
/// Optional [extraSavedPlaces] appends one chip per non-preset saved address (Home screen only).
///
/// Place outside horizontal [Padding] on the parent. Pass [contentHorizontalPadding]
/// so the first chip lines up with padded siblings while the list scrolls to screen edges.
class FavoriteLocationChipsRow extends StatelessWidget {
  const FavoriteLocationChipsRow({
    super.key,
    required this.resolvePlace,
    required this.onChipTap,
    this.onSavedChipLongPress,
    this.extraSavedPlaces,
    this.onExtraChipTap,
    this.onExtraChipLongPress,
    this.chipBackgroundColor,
    this.chipBorderColor,
    this.contentHorizontalPadding,
  });

  final SavedPlace? Function(String canonicalLabel) resolvePlace;

  /// Called with stored label (e.g. `"Home"`) and matching place if any.
  final void Function(String canonicalLabel, SavedPlace? place) onChipTap;

  final void Function(String canonicalLabel)? onSavedChipLongPress;

  /// Non-preset favourites (e.g. custom labels from API). Omit everywhere except Home.
  final List<SavedPlace>? extraSavedPlaces;

  final void Function(SavedPlace place)? onExtraChipTap;

  final void Function(SavedPlace place)? onExtraChipLongPress;

  final Color? chipBackgroundColor;
  final Color? chipBorderColor;

  /// Inset for the first/last chip inside the horizontal scroll (matches sheet padding).
  final double? contentHorizontalPadding;

  String _displayTitle(FavoriteLocationSlotId id) {
    switch (id) {
      case FavoriteLocationSlotId.home:
        return AppStrings.home.tr;
      case FavoriteLocationSlotId.office:
        return AppStrings.office.tr;
      case FavoriteLocationSlotId.work:
        return AppStrings.work.tr;
      case FavoriteLocationSlotId.other:
        return AppStrings.other.tr;
    }
  }

  String _extraChipTitle(SavedPlace place) {
    final raw = (place.label ?? place.name ?? '').trim();
    if (raw.isEmpty) return AppStrings.saved.tr;
    return raw.capitalizeFirst ?? raw;
  }

  @override
  Widget build(BuildContext context) {
    final extras = extraSavedPlaces ?? const <SavedPlace>[];
    final inset = contentHorizontalPadding ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: inset > 0
          ? EdgeInsets.symmetric(horizontal: inset)
          : EdgeInsets.zero,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          ...FavoriteLocationSlotId.values.map((id) {
            final canonical = FavoriteLocationChipCatalog.canonicalLabel(id);
            final place = resolvePlace(canonical);
            final hasSaved = place != null;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: AppSavedPlaceChip(
                label: _displayTitle(id),
                iconAsset: hasSaved
                    ? FavoriteLocationChipCatalog.categoryIconAsset(id)
                    : FavoriteLocationChipCatalog.emptySlotIconAsset,
                iconColor: hasSaved ? null : AppColors.primary,
                backgroundColor: chipBackgroundColor,
                borderColor: chipBorderColor,
                onTap: () => onChipTap(canonical, place),
                onLongPress: hasSaved && onSavedChipLongPress != null
                    ? () => onSavedChipLongPress!(canonical)
                    : null,
              ),
            );
          }),
          ...extras.map((place) {
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: AppSavedPlaceChip(
                label: _extraChipTitle(place),
                iconAsset: AppAssets.icOtherChip,
                backgroundColor: chipBackgroundColor,
                borderColor: chipBorderColor,
                onTap: () => onExtraChipTap?.call(place),
                onLongPress: onExtraChipLongPress != null
                    ? () => onExtraChipLongPress!(place)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
