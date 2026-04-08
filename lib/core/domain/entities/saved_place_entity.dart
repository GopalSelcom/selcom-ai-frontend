enum SavedPlaceLabel { home, office, work, other }

class SavedPlaceEntity {
  final String id;
  final String userId;
  final SavedPlaceLabel label;
  final String? name;
  final String address;
  final double lat;
  final double lng;
  final bool isActive;

  const SavedPlaceEntity({
    required this.id,
    required this.userId,
    required this.label,
    this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isActive,
  });
}
