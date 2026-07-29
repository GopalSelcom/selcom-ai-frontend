/// Backend-owned cancel confirmation copy (`cancel_info` on status / active rides).
///
/// Title, subtitle, and fee are pre-rendered by the server — render as-is.
class RideCancelInfoModel {
  final bool canCancel;
  final int fee;
  final String title;
  final String subtitle;

  const RideCancelInfoModel({
    required this.canCancel,
    required this.fee,
    required this.title,
    required this.subtitle,
  });

  factory RideCancelInfoModel.fromJson(Map<String, dynamic> json) {
    return RideCancelInfoModel(
      canCancel: json['can_cancel'] == true,
      fee: (json['fee'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString().trim() ?? '',
      subtitle: json['subtitle']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'can_cancel': canCancel,
    'fee': fee,
    'title': title,
    'subtitle': subtitle,
  };

  bool get hasFee => fee > 0;
}

/// Parses `cancel_info` from a status or active-ride envelope map.
RideCancelInfoModel? rideCancelInfoFromJson(dynamic raw) {
  if (raw is! Map) return null;
  return RideCancelInfoModel.fromJson(Map<String, dynamic>.from(raw));
}
