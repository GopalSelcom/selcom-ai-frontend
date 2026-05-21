/// Short label for map route headers (first segment before comma).
String compactAddressLine(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  final first = trimmed.split(',').first.trim();
  return first.isEmpty ? trimmed : first;
}
