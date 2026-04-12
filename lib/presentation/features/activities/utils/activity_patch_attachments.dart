/// Shapes attachment maps for `PATCH /api/v1/activities/{code}`.
List<Map<String, dynamic>> attachmentsForActivityPatchRequest(
  List<Map<String, dynamic>> items,
) {
  final out = <Map<String, dynamic>>[];
  for (final a in items) {
    final ac = (a['assetCode'] ?? '').toString().trim();
    if (ac.isEmpty) continue;
    final student = (a['studentCode'] ?? a['ownerCode'] ?? '').toString();
    out.add({
      'assetCode': ac,
      'studentCode': student,
      'bindingMode': (a['bindingMode'] ?? 'ACTIVITY').toString(),
    });
  }
  return out;
}

/// Normalizes delivery URLs so we can match UI "remaining" URLs to attachment rows.
String normalizeActivityDeliveryUrl(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  try {
    final u = Uri.parse(s);
    return '${u.scheme}://${u.host}${u.path}'.toLowerCase();
  } catch (_) {
    return s.split('?').first.trim().toLowerCase();
  }
}

String _attachmentPrimaryDeliveryUrl(Map<String, dynamic> row) {
  final d = (row['deliveryUrl'] ?? '').toString().trim();
  if (d.isNotEmpty) return d;
  return (row['thumbnailUrl'] ?? '').toString().trim();
}

bool _isVideoAttachmentMap(Map<String, dynamic> row, String? deliveryUrl) {
  final mt = (row['mediaType'] ?? '').toString().toLowerCase();
  if (mt.contains('video')) return true;
  final u = (deliveryUrl ?? '').toLowerCase();
  return u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.webm');
}

/// Image delivery URLs from activity attachment rows (same heuristic as the activity feed).
List<String> imageDeliveryUrlsFromAttachmentRows(
  List<Map<String, dynamic>> rows,
) {
  final urls = <String>[];
  for (final a in rows) {
    final u = _attachmentPrimaryDeliveryUrl(a);
    if (u.isEmpty) continue;
    if (_isVideoAttachmentMap(a, u)) continue;
    urls.add(u);
  }
  return urls;
}

/// Builds the full attachment list for PATCH: keeps rows whose media URL is still shown,
/// replaces [assetCode] only for removed slots using [newUploadRows] in order, appends
/// leftover new uploads as additions, and drops removed slots with no replacement.
List<Map<String, dynamic>> mergeAttachmentRowsForEditPatch({
  required List<Map<String, dynamic>> existingRows,
  required List<Map<String, dynamic>> newUploadRows,
  required Set<String> remainingNormalizedDeliveryUrls,
}) {
  final queue = newUploadRows
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  final result = <Map<String, dynamic>>[];

  for (final row in existingRows) {
    final copy = Map<String, dynamic>.from(row);
    final url = _attachmentPrimaryDeliveryUrl(copy);
    final normalized = normalizeActivityDeliveryUrl(url);

    if (normalized.isEmpty) {
      result.add(copy);
      continue;
    }

    if (remainingNormalizedDeliveryUrls.contains(normalized)) {
      result.add(copy);
      continue;
    }

    if (queue.isEmpty) continue;

    final nu = queue.removeAt(0);
    final newAsset = (nu['assetCode'] ?? '').toString().trim();
    if (newAsset.isEmpty) continue;

    copy['assetCode'] = newAsset;
    final prevStudent =
        (copy['studentCode'] ?? copy['ownerCode'] ?? '').toString().trim();
    final nuStudent = (nu['studentCode'] ?? '').toString().trim();
    if (prevStudent.isEmpty && nuStudent.isNotEmpty) {
      copy['studentCode'] = nuStudent;
    }
    final bm = (copy['bindingMode'] ?? nu['bindingMode'] ?? 'PER_STUDENT')
        .toString();
    copy['bindingMode'] = bm.isNotEmpty ? bm : 'PER_STUDENT';
    result.add(copy);
  }

  for (final nu in queue) {
    result.add(Map<String, dynamic>.from(nu));
  }

  return result;
}
