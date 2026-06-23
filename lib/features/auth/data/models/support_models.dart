class SupportReasonModel {
  const SupportReasonModel({required this.value, required this.label});

  final String value;
  final String label;

  factory SupportReasonModel.fromJson(Map<String, dynamic> json) {
    return SupportReasonModel(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class SupportReasonsResponseModel {
  const SupportReasonsResponseModel({required this.reasons});

  final List<SupportReasonModel> reasons;

  factory SupportReasonsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final reasonsJson = data is Map ? data['reasons'] as List? : null;
    final reasons = (reasonsJson ?? [])
        .whereType<Map>()
        .map((e) => SupportReasonModel.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.value.isNotEmpty && r.label.isNotEmpty)
        .toList(growable: false);
    return SupportReasonsResponseModel(reasons: reasons);
  }
}

class CreateSupportTicketRequestModel {
  const CreateSupportTicketRequestModel({
    required this.reason,
    required this.description,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactName,
  });

  final String reason;
  final String description;
  final String contactEmail;
  final String contactPhone;
  final String contactName;

  Map<String, dynamic> toJson() => {
    'reason': reason,
    'description': description,
    'contact_email': contactEmail,
    'contact_phone': contactPhone,
    'contact_name': contactName,
  };
}

class CreateSupportTicketResponseModel {
  const CreateSupportTicketResponseModel({
    required this.statusCode,
    required this.message,
    this.ticketNumber,
  });

  final int statusCode;
  final String message;
  final String? ticketNumber;

  factory CreateSupportTicketResponseModel.fromJson(Map<String, dynamic> json) {
    final ticket = json['data'] is Map ? json['data']['ticket'] : null;
    return CreateSupportTicketResponseModel(
      statusCode: (json['status_code'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      ticketNumber: ticket is Map ? ticket['ticket_number']?.toString() : null,
    );
  }
}
