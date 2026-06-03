import '../../core/data/models/responses/get_saved_places_response.dart';
import 'favorite_location_chip_catalog.dart';

/// Sorts saved places for chips and lists: Home → Office → Work → Other, then custom labels.
class SavedPlacesOrdering {
  SavedPlacesOrdering._();

  static String effectiveLabel(SavedPlace place) {
    final labelTrim = (place.label ?? '').trim();
    if (labelTrim.isNotEmpty) return labelTrim;
    return (place.name ?? '').trim();
  }

  /// Preset slots in catalog order, then non-preset labels alphabetically.
  static List<SavedPlace> sortForDisplay(Iterable<SavedPlace> places) {
    final input = places.toList();
    if (input.isEmpty) return const [];

    final bySlot = <FavoriteLocationSlotId, SavedPlace>{};
    final extras = <SavedPlace>[];

    for (final place in input) {
      final slot = FavoriteLocationChipCatalog.slotForSavedPlaceLabel(
        effectiveLabel(place),
      );
      if (slot != null) {
        bySlot.putIfAbsent(slot, () => place);
      } else {
        extras.add(place);
      }
    }

    final ordered = <SavedPlace>[];
    for (final id in FavoriteLocationSlotId.values) {
      final place = bySlot[id];
      if (place != null) ordered.add(place);
    }

    extras.sort(
      (a, b) => effectiveLabel(a).toLowerCase().compareTo(
        effectiveLabel(b).toLowerCase(),
      ),
    );
    ordered.addAll(extras);
    return ordered;
  }

  static SavedPlace? placeForCanonicalLabel(
    Iterable<SavedPlace> places,
    String canonicalLabel,
  ) {
    final slot = FavoriteLocationChipCatalog.slotForSavedPlaceLabel(
      canonicalLabel,
    );
    if (slot == null) return null;

    for (final place in places) {
      if (FavoriteLocationChipCatalog.slotForSavedPlaceLabel(
            effectiveLabel(place),
          ) ==
          slot) {
        return place;
      }
    }
    return null;
  }

  /// Non-preset saved places, including duplicate preset labels (e.g. second "other").
  static List<SavedPlace> beyondPresetSlots(Iterable<SavedPlace> places) {
    final assignedIds = <String>{};
    for (final id in FavoriteLocationSlotId.values) {
      final place = placeForCanonicalLabel(
        places,
        FavoriteLocationChipCatalog.canonicalLabel(id),
      );
      final placeId = place?.id;
      if (placeId != null && placeId.isNotEmpty) {
        assignedIds.add(placeId);
      }
    }

    return places
        .where((p) {
          final id = p.id;
          return id == null || id.isEmpty || !assignedIds.contains(id);
        })
        .toList();
  }
}
