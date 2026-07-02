/// Builds classroom labels for newsletter list cards, hiding codes the user cannot access.
String buildNewsletterClassroomLabel({
  required List<String> classroomCodes,
  required Map<String, String> nameByCode,
  bool restrictToKnownClassrooms = false,
}) {
  if (classroomCodes.isEmpty) {
    return restrictToKnownClassrooms ? '' : 'All Classrooms';
  }

  final Set<String> knownCodes = nameByCode.keys
      .map((String c) => c.trim())
      .where((String c) => c.isNotEmpty)
      .toSet();

  final List<String> labels = <String>[];
  for (final String raw in classroomCodes) {
    final String code = raw.trim();
    if (code.isEmpty) continue;
    if (restrictToKnownClassrooms && !knownCodes.contains(code)) continue;

    final String? name = nameByCode[code]?.trim();
    if (restrictToKnownClassrooms) {
      if (name != null && name.isNotEmpty) labels.add(name);
    } else {
      labels.add(name != null && name.isNotEmpty ? name : code);
    }
  }

  if (labels.isEmpty) return '';
  return labels.toSet().join(', ');
}
