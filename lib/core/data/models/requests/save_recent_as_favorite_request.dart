class SaveRecentAsFavoriteRequest {
  final String label;
  final String name;
  final String address;
  final double lat;
  final double lng;

  SaveRecentAsFavoriteRequest({
    required this.label,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}
