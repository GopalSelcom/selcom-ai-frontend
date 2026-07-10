class SetNameRequest {
  /// Body for `POST /go/auth/set_name` when [VerifyOtpData.needsName] is true
  /// after SSO (Google / Apple / Facebook) did not yield a display name.
  final String name;

  const SetNameRequest({required this.name});

  Map<String, dynamic> toJson() => {'name': name.trim()};
}
