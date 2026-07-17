import '../user_model.dart';

/// Response envelope for `POST /go/auth/set_name`.
///
/// Example:
/// ```json
/// {
///   "status_code": 200,
///   "message": "Profile updated successfully",
///   "data": {
///     "user": { "_id": "6a4b5f7084fd290007222211", "name": "Priyansh" }
///   }
/// }
/// ```
///
/// Note: [user] is a partial profile — only `_id` and `name` are guaranteed.
/// Merge into the locally stored user instead of replacing the full record.
class SetNameResponseModel {
  int? statusCode;
  String? message;
  UserModel? user;

  SetNameResponseModel({this.statusCode, this.message, this.user});

  SetNameResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['status_code'];
    message = json['message'];
    final payload = json['data'];
    if (payload is Map<String, dynamic>) {
      final userJson = payload['user'];
      if (userJson is Map<String, dynamic>) {
        user = UserModel.fromJson(userJson);
      }
    }
  }

  bool get isSuccess => statusCode == 200;
}
