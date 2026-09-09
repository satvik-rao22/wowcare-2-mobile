/// Formats backend designation enums for UI (e.g. `ASSOCIATE_TEACHER` → Associate Teacher).
String formatDesignationForDisplay(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  final normalized = t.replaceAll('-', '_');
  final parts = normalized.split('_').where((p) => p.trim().isNotEmpty);
  return parts
      .map((p) {
        final lower = p.trim().toLowerCase();
        if (lower.isEmpty) return '';
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .where((p) => p.isNotEmpty)
      .join(' ');
}
