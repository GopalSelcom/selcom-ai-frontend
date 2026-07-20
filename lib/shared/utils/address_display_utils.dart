/// Short label for map route headers (first segment before comma).
String compactAddressLine(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  final first = trimmed.split(',').first.trim();
  return first.isEmpty ? trimmed : first;
}

/// Prepends an optional user note as the first comma-separated address segment.
String prependAddressLine(String baseAddress, String optionalLine) {
  final note = optionalLine.trim();
  final base = baseAddress.trim();
  if (note.isEmpty) return base;
  if (base.isEmpty) return note;
  return '$note, $base';
}
