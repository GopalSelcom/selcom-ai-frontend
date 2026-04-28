class SaveUserAdditionalDetailsRequest {
  final String name;
  final String emailId;

  const SaveUserAdditionalDetailsRequest({
    required this.name,
    required this.emailId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emailId': emailId,
    };
  }
}
