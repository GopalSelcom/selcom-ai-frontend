import 'dart:io';

/// Payload for `edit_profile` — JSON body sends [name] only; [image] is multipart.
class UserProfileUpdateRequest {
  final String name;

  /// Optional profile photo; not included in [toJson].
  final File? image;

  UserProfileUpdateRequest({required String name, this.image})
    : name = name.trim() {
    // Controller validates before save; guard direct construction too.
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be null or empty');
    }
  }

  factory UserProfileUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserProfileUpdateRequest(name: json['name']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'name': name};
}
