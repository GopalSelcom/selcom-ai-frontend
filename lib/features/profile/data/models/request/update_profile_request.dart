import 'dart:io';

import 'package:http/http.dart' as http;

class UserProfileUpdateRequest {
  final String? name;
  final String? emailId;
  final String? dob;
  final String? nidaNumber;
  final String? userId;

  /// Image is not part of JSON; used only when uploading
  final File? image;

  UserProfileUpdateRequest({
    this.name,
    this.emailId,
    this.dob,
    this.nidaNumber,
    this.userId,
    this.image,
  });

  /// Create model from JSON Map
  factory UserProfileUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserProfileUpdateRequest(
      name: json['name'],
      emailId: json['emailId'],
      dob: json['dob'],
      nidaNumber: json['nida_number'],
      userId: json['user_id'],
      image: null, // image can't come from normal JSON
    );
  }

  /// Convert model to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emailId': emailId,
      'dob': dob,
      'nida_number': nidaNumber,
      'user_id': userId,
      // image excluded because MultipartFile is not JSON compatible
    };
  }
}
