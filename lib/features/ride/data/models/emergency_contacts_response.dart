/// Response for `GET .../go/emergency-contacts`.
class EmergencyContactsResponse {
  EmergencyContactsResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final int statusCode;
  final String message;
  final EmergencyContactsData data;

  factory EmergencyContactsResponse.fromJson(Map<String, dynamic> json) {
    return EmergencyContactsResponse(
      statusCode: (json['status_code'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?) ?? '',
      data: EmergencyContactsData.fromJson(
        Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
    'data': data.toJson(),
  };
}

class EmergencyContactsData {
  EmergencyContactsData({required this.contacts});

  final List<EmergencyContactModel> contacts;

  factory EmergencyContactsData.fromJson(Map<String, dynamic> json) {
    final raw = json['contacts'];
    if (raw is! List) {
      return EmergencyContactsData(contacts: []);
    }
    return EmergencyContactsData(
      contacts: raw
          .map((e) {
            if (e is Map<String, dynamic>) {
              return EmergencyContactModel.fromJson(e);
            }
            return EmergencyContactModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            );
          })
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'contacts': contacts.map((e) => e.toJson()).toList(),
  };
}

class EmergencyContactModel {
  EmergencyContactModel({
    required this.id,
    required this.label,
    required this.phone,
    this.secondaryPhone,
    this.email,
  });

  final String id;
  final String label;
  final String phone;
  final String? secondaryPhone;
  final String? email;

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      secondaryPhone: json['secondary_phone']?.toString(),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'phone': phone,
    'secondary_phone': secondaryPhone,
    'email': email,
  };
}
