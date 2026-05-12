import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/app_strings.dart';

/// Ordered presets shared by Home chips row and [AddFavoriteLocationSheet].
enum FavoriteLocationSlotId {
  home,
  office,
  work,
  other,
}

/// Canonical API labels and icons for favorite-location chips (Duka-style presets).
class FavoriteLocationChipCatalog {
  FavoriteLocationChipCatalog._();

  static String canonicalLabel(FavoriteLocationSlotId id) {
    switch (id) {
      case FavoriteLocationSlotId.home:
        return 'Home';
      case FavoriteLocationSlotId.office:
        return 'Office';
      case FavoriteLocationSlotId.work:
        return 'Work';
      case FavoriteLocationSlotId.other:
        return 'Other';
    }
  }

  /// Icon when this slot has a saved address.
  static String categoryIconAsset(FavoriteLocationSlotId id) {
    switch (id) {
      case FavoriteLocationSlotId.home:
        return AppAssets.icHomeChip;
      case FavoriteLocationSlotId.office:
        return AppAssets.icOfficeChip;
      case FavoriteLocationSlotId.work:
        return AppAssets.icWorkChip;
      case FavoriteLocationSlotId.other:
        return AppAssets.icOtherChip;
    }
  }

  /// Icon when no saved address exists for this slot (add flow).
  static String get emptySlotIconAsset => AppAssets.locationIcAdd;

  /// Keys used inside [AddFavoriteLocationSheet] selection state (`home` … `other`).
  static String presetKey(FavoriteLocationSlotId id) => id.name;

  /// Maps a saved-place label (English canonical, preset key, or localized `.tr` string)
  /// to the matching chip SVG.
  static String chipIconAssetForDisplayLabel(String displayLabel) {
    final t = displayLabel.trim();
    if (t.isEmpty) return AppAssets.icOtherChip;

    final lower = t.toLowerCase();
    if (lower == 'home' || lower == FavoriteLocationSlotId.home.name) {
      return AppAssets.icHomeChip;
    }
    if (lower == 'office' || lower == FavoriteLocationSlotId.office.name) {
      return AppAssets.icOfficeChip;
    }
    if (lower == 'work' || lower == FavoriteLocationSlotId.work.name) {
      return AppAssets.icWorkChip;
    }
    if (lower == 'other' || lower == FavoriteLocationSlotId.other.name) {
      return AppAssets.icOtherChip;
    }

    if (t == AppStrings.homeLabel.tr) return AppAssets.icHomeChip;
    if (t == AppStrings.office.tr) return AppAssets.icOfficeChip;
    if (t == AppStrings.work.tr) return AppAssets.icWorkChip;
    if (t == AppStrings.other.tr) return AppAssets.icOtherChip;

    for (final id in FavoriteLocationSlotId.values) {
      if (canonicalLabel(id) == t) {
        return categoryIconAsset(id);
      }
    }

    return AppAssets.icOtherChip;
  }
}
