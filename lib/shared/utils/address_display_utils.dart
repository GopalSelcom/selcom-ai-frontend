/// Full address for UI display (trimmed only, never truncated in code).
String compactAddressLine(String value) => value.trim();

/// Prepends an optional user note as the first comma-separated address segment.
String prependAddressLine(String baseAddress, String optionalLine) {
  final note = optionalLine.trim();
  final base = baseAddress.trim();
  if (note.isEmpty) return base;
  if (base.isEmpty) return note;
  return '$note, $base';
}
