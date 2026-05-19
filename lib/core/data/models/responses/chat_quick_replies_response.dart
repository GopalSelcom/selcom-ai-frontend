/// Parses `GET …/go/chat/quick-replies` root JSON (`data.quick_replies`).
List<String> parseChatQuickRepliesFromResponse(dynamic root) {
  if (root is! Map<String, dynamic>) return const [];

  final data = root['data'];
  if (data is! Map<String, dynamic>) return const [];

  final raw = data['quick_replies'];
  if (raw is! List) return const [];

  return raw
      .map((e) => e?.toString().trim() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
}
