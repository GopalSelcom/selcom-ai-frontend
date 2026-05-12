import '../../core/constants/app_assets.dart';

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
}
