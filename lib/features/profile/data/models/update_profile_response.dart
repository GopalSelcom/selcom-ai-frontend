import '../../../../core/data/models/user_model.dart';
import 'profile_response_model.dart';

/// Envelope for `edit_profile` — same `data` shape as [UserProfileResponseModel].
class UserProfileUpdateResponse {
  final int? statusCode;
  final String? message;
  final UserProfileDataModel? data;

  const UserProfileUpdateResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory UserProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return UserProfileUpdateResponse(
      statusCode: (json['status_code'] as num?)?.toInt(),
      message: json['message']?.toString(),
      data: rawData is Map<String, dynamic>
          ? UserProfileDataModel.fromJson(rawData)
          : rawData is Map
          ? UserProfileDataModel.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  /// Maps update payload to [UserModel], keeping session user id when API omits `_id`.
  UserModel? toUserModel({String? preserveUserId}) =>
      data?.toUserModel(preserveUserId: preserveUserId);
}
