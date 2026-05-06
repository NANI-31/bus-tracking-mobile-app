bool parseBool(dynamic value, [bool defaultValue = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return defaultValue;
}

DateTime parseDateTime(dynamic value, [DateTime? defaultValue]) {
  if (value == null) return defaultValue ?? DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? defaultValue ?? DateTime.now();
  }
  return defaultValue ?? DateTime.now();
}
