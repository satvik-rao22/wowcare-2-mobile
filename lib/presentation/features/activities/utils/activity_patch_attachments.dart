/// Shapes attachment maps for `PATCH /api/v1/activities/{code}`.
List<Map<String, dynamic>> attachmentsForActivityPatchRequest(
  List<Map<String, dynamic>> items,
) {
  final out = <Map<String, dynamic>>[];
  for (final a in items) {
    final ac = (a['assetCode'] ?? '').toString().trim();
    if (ac.isEmpty) continue;
    out.add({
      'assetCode': ac,
      'studentCode': (a['studentCode'] ?? '').toString(),
      'bindingMode': (a['bindingMode'] ?? 'ACTIVITY').toString(),
    });
  }
  return out;
}
