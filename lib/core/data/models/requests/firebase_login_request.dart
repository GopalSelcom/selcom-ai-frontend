class FirebaseLoginRequest {
  final String idToken;
  final double? latitude;
  final double? longitude;
  final String? name;

  const FirebaseLoginRequest({
    required this.idToken,
    this.latitude,
    this.longitude,
    this.name,
  });

  Map<String, dynamic> toJson() => {
    'id_token': idToken,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
  };
}
