class ShareLinkEntity {
  final String shareUrl;
  final String shareToken;
  final DateTime expiresAt;

  const ShareLinkEntity({
    required this.shareUrl,
    required this.shareToken,
    required this.expiresAt,
  });
}
