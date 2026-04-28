import '../../domain/entities/share_link_entity.dart';

class ShareLinkModel extends ShareLinkEntity {
  const ShareLinkModel({
    required super.shareUrl,
    required super.shareToken,
    required super.expiresAt,
  });

  factory ShareLinkModel.fromJson(Map<String, dynamic> json) {
    return ShareLinkModel(
      shareUrl: (json['share_url'] ?? '').toString(),
      shareToken: (json['share_token'] ?? '').toString(),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()) ??
          DateTime.now().add(const Duration(hours: 24)),
    );
  }
}
