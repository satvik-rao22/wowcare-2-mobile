/// Shapes attachment maps for `PATCH /api/v1/activities/{code}`.
List<Map<String, dynamic>> attachmentsForActivityPatchRequest(
  List<Map<String, dynamic>> items,
) {
  final out = <Map<String, dynamic>>[];
  for (final a in items) {
    final ac = (a['assetCode'] ?? '').toString().trim();
    if (ac.isEmpty) continue;
    final owner = (a['studentCode'] ?? a['ownerCode'] ?? '').toString().trim();
    final bindingRaw = (a['bindingMode'] ?? '').toString().trim();
    final bindingMode = bindingRaw.isNotEmpty
        ? bindingRaw
        : (owner.isNotEmpty ? 'PER_STUDENT' : 'ACTIVITY');
    final ownerTypeRaw = (a['ownerType'] ?? '').toString().trim();
    final ownerType = ownerTypeRaw.isNotEmpty
        ? ownerTypeRaw
        : (owner.isNotEmpty ? 'STUDENT' : '');

    final entry = <String, dynamic>{
      'assetCode': ac,
      'bindingMode': bindingMode,
    };
    if (owner.isNotEmpty) {
      entry['studentCode'] = owner;
      entry['ownerCode'] = owner;
    }
    if (ownerType.isNotEmpty) {
      entry['ownerType'] = ownerType;
    }
    out.add(entry);
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

const List<String> _attachmentUrlKeys = [
  'deliveryUrl',
  'thumbnailUrl',
  'artifactUrl',
  'originalDownloadUrl',
];

/// First non-empty URL on the row (same preference order as the activity feed card).
String _attachmentPrimaryDeliveryUrl(Map<String, dynamic> row) {
  for (final key in _attachmentUrlKeys) {
    final d = (row[key] ?? '').toString().trim();
    if (d.isNotEmpty) return d;
  }
  return '';
}

bool _attachmentRowUrlsIntersectRemaining(
  Map<String, dynamic> row,
  Set<String> remainingNorm,
) {
  for (final key in _attachmentUrlKeys) {
    final u = (row[key] ?? '').toString().trim();
    if (u.isEmpty) continue;
    final n = normalizeActivityDeliveryUrl(u);
    if (n.isNotEmpty && remainingNorm.contains(n)) return true;
  }
  return false;
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

/// Video URLs from attachment rows (for edit UI + PATCH merge).
List<String> videoDeliveryUrlsFromAttachmentRows(
  List<Map<String, dynamic>> rows,
) {
  final urls = <String>[];
  for (final a in rows) {
    for (final key in _attachmentUrlKeys) {
      final u = (a[key] ?? '').toString().trim();
      if (u.isEmpty) continue;
      if (_isVideoAttachmentMap(a, u)) {
        urls.add(u);
        break;
      }
    }
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
  final queue = newUploadRows.map((e) => Map<String, dynamic>.from(e)).toList();
  final result = <Map<String, dynamic>>[];

  for (final row in existingRows) {
    final copy = Map<String, dynamic>.from(row);
    final url = _attachmentPrimaryDeliveryUrl(copy);
    final normalized = normalizeActivityDeliveryUrl(url);

    if (normalized.isEmpty) {
      result.add(copy);
      continue;
    }

    if (_attachmentRowUrlsIntersectRemaining(
      copy,
      remainingNormalizedDeliveryUrls,
    )) {
      result.add(copy);
      continue;
    }

    if (queue.isEmpty) continue;

    final nu = queue.removeAt(0);
    final newAsset = (nu['assetCode'] ?? '').toString().trim();
    if (newAsset.isEmpty) continue;

    copy['assetCode'] = newAsset;
    final nuStudent = (nu['studentCode'] ?? '').toString().trim();
    final nuOwnerCode = (nu['ownerCode'] ?? '').toString().trim();
    final nuBinding = (nu['bindingMode'] ?? '').toString().trim();

    // When a removed slot is replaced by a newly uploaded asset, use the
    // new asset ownership/binding metadata and do not carry stale values from
    // the previous row (e.g. SHARED classroom rows replaced with PER_STUDENT).
    if (nuStudent.isNotEmpty) {
      copy['studentCode'] = nuStudent;
    } else {
      copy.remove('studentCode');
    }
    if (nuOwnerCode.isNotEmpty) {
      copy['ownerCode'] = nuOwnerCode;
    } else if (nuStudent.isNotEmpty) {
      copy['ownerCode'] = nuStudent;
    } else {
      copy.remove('ownerCode');
    }
    copy['bindingMode'] = nuBinding.isNotEmpty ? nuBinding : 'PER_STUDENT';
    result.add(copy);
  }

  for (final nu in queue) {
    result.add(Map<String, dynamic>.from(nu));
  }

  return result;
}
