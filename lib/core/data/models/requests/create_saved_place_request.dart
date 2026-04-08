class CreateSavedPlaceRequest {
  final String label;
  final String name;
  final String placeId;
  final double lat;
  final double lng;

  CreateSavedPlaceRequest({
    required this.label,
    required this.name,
    required this.placeId,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'name': name,
      'place_id': placeId,
      'location': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
    };
  }
}
