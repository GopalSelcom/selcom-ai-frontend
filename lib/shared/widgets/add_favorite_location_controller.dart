import 'package:get/get.dart';

import '../../core/data/models/responses/get_saved_places_response.dart';
import '../../core/localization/app_strings.dart';
import '../utils/address_display_utils.dart';
import '../utils/favorite_location_chip_catalog.dart';
import '../utils/saved_places_ordering.dart';

/// One chip in the add-favourite picker (same order as [FavoriteLocationChipsRow]).
sealed class AddFavoriteChipEntry {
  const AddFavoriteChipEntry();

  String get selectionKey;
}

final class AddFavoritePresetChip extends AddFavoriteChipEntry {
  AddFavoritePresetChip(this.slotId);

  final FavoriteLocationSlotId slotId;

  @override
  String get selectionKey => FavoriteLocationChipCatalog.presetKey(slotId);
}

final class AddFavoriteExtraChip extends AddFavoriteChipEntry {
  AddFavoriteExtraChip(this.place);

  final SavedPlace place;

  @override
  String get selectionKey =>
      'extra:${place.id ?? SavedPlacesOrdering.effectiveLabel(place)}';
}

final class AddFavoriteAddNewChip extends AddFavoriteChipEntry {
  const AddFavoriteAddNewChip();

  @override
  String get selectionKey => 'add_new';
}

class AddFavoriteLocationController extends GetxController {
  AddFavoriteLocationController({
    required this.address,
    required this.onSave,
    required this.resolveSavedPlace,
    required this.isSaving,
    required this.savedPlaces,
  });

  final String address;
  final Future<void> Function(String label, String address) onSave;
  final SavedPlace? Function(String canonicalLabel) resolveSavedPlace;
  final RxBool isSaving;
  final RxList<SavedPlace> savedPlaces;

  final selectedLabel = ''.obs;
  final hasUserSelectedLabel = false.obs;
  final customLabelText = ''.obs;
  final addressNoteText = ''.obs;

  String get effectiveAddress =>
      prependAddressLine(address, addressNoteText.value);

  bool get canSave {
    if (!hasUserSelectedLabel.value) return false;
    if (selectedLabel.value.isEmpty) return false;
    if (selectedLabel.value == 'add_new') {
      return customLabelText.value.trim().length >= 3;
    }
    return true;
  }

  void selectChip(AddFavoriteChipEntry entry) {
    hasUserSelectedLabel.value = true;
    selectedLabel.value = entry.selectionKey;
    if (entry is! AddFavoriteAddNewChip) {
      customLabelText.value = '';
    }
  }

  void onCustomLabelChanged(String value) {
    hasUserSelectedLabel.value = true;
    customLabelText.value = value;
  }

  void onAddressNoteChanged(String value) {
    addressNoteText.value = value;
  }

  /// Filled presets → custom saved labels → empty presets → Add New (matches Home).
  List<AddFavoriteChipEntry> chipsForDisplay() {
    final extras = SavedPlacesOrdering.beyondPresetSlots(savedPlaces);
    final groups = FavoriteLocationChipCatalog.slotDisplayGroups(
      resolvePlace: resolveSavedPlace,
    );

    return [
      ...groups.filled.map(AddFavoritePresetChip.new),
      ...extras.map(AddFavoriteExtraChip.new),
      ...groups.empty.map(AddFavoritePresetChip.new),
      const AddFavoriteAddNewChip(),
    ];
  }

  String labelForSave(AddFavoriteChipEntry? entry) {
    if (entry == null) return '';
    return switch (entry) {
      AddFavoriteAddNewChip() => customLabelText.value.trim(),
      AddFavoriteExtraChip(place: final place) =>
        SavedPlacesOrdering.effectiveLabel(place),
      AddFavoritePresetChip(slotId: final slotId) =>
        FavoriteLocationChipCatalog.canonicalLabel(slotId),
    };
  }

  AddFavoriteChipEntry? entryForSelectionKey(String key) {
    for (final entry in chipsForDisplay()) {
      if (entry.selectionKey == key) return entry;
    }
    return null;
  }

  Future<void> saveSelected() async {
    final entry = entryForSelectionKey(selectedLabel.value);
    await onSave(labelForSave(entry), effectiveAddress);
  }

  String presetDisplayTitle(FavoriteLocationSlotId id) {
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
}
