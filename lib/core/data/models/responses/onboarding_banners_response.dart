/// One onboarding slide from `GET …/go/banner` (`data.banner` or `data.banners`).
class OnboardingBannerItem {
  final String screen;
  final String title;
  final String subtitle;
  final String? backgroundImageUrl;
  final String? updatedAt;

  const OnboardingBannerItem({
    this.screen = '',
    required this.title,
    required this.subtitle,
    this.backgroundImageUrl,
    this.updatedAt,
  });

  factory OnboardingBannerItem.fromJson(Map<String, dynamic> json) {
    return OnboardingBannerItem(
      screen: (json['screen'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString().trim(),
      subtitle: (json['subtitle'] ?? '').toString().trim(),
      backgroundImageUrl: json['background_image_url']?.toString().trim(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

/// Parses `data.banner` (object or list) or `data.banners` (list) from API root JSON.
List<OnboardingBannerItem> parseOnboardingBannersFromResponse(dynamic raw) {
  if (raw is! Map<String, dynamic>) return const [];

  final data = raw['data'];
  if (data is! Map<String, dynamic>) return const [];

  final fromList =
      _itemsFromDynamicList(data['banners']) ??
      _itemsFromDynamicList(data['banner']);
  if (fromList != null && fromList.isNotEmpty) return fromList;

  final single = data['banner'];
  if (single is Map<String, dynamic>) {
    final item = OnboardingBannerItem.fromJson(single);
    if (item.title.isNotEmpty ||
        item.subtitle.isNotEmpty ||
        (item.backgroundImageUrl ?? '').isNotEmpty) {
      return [item];
    }
  }

  return const [];
}

List<OnboardingBannerItem>? _itemsFromDynamicList(dynamic value) {
  if (value is! List || value.isEmpty) return null;
  final out = <OnboardingBannerItem>[];
  for (final e in value) {
    if (e is Map<String, dynamic>) {
      out.add(OnboardingBannerItem.fromJson(e));
    } else if (e is Map) {
      out.add(OnboardingBannerItem.fromJson(Map<String, dynamic>.from(e)));
    }
  }
  return out.isEmpty ? null : out;
}
