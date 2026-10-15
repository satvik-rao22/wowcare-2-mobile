import 'package:wowcare/domain/features/activity/services/activity_staff_display.dart';
import 'package:wowcare/presentation/features/activities/model/activity_item.dart';

/// Pure grouping/dedupe rules for the activity feed.
///
/// Extracted from `view/activity_daily_tab.dart` so `activity_feed_cubit` no
/// longer imports a widget file to reach them (a view-model depending on a
/// view). Nothing here touches Flutter — the one function in this region that
/// does, `activityApprovalStatusBadgeColor`, deliberately stayed behind.

/// Activity types where the API may return one feed row per student; adjacent
/// rows that match the same logged event are merged for display.
const Set<String> _mergeableMultiStudentActivityNames = {
  'Meal',
  'Bottle',
  'Notes',
  'Observation',
  'Nap Start',
  'Nap End',
  'Nap',
  'Bathroom',
  'Learning',
  'Outdoor',
  'Medication',
  'Photo',
  'Video',
};

const Set<String> _attendanceMergeableActivityNames = {
  'Sign-in',
  'Sign-out',
  'Transfer',
  'Marked Absent',
};

bool activityItemsMergeableForFeedDisplay(ActivityItem a, ActivityItem b) {
  if (_attendanceMergeableActivityNames.contains(a.name)) {
    if (a.name != b.name) return false;
    if (a.time != b.time) return false;
    if (a.date != b.date) return false;
    if ((a.classroomCode ?? '') != (b.classroomCode ?? '')) return false;
    if ((a.description ?? '') != (b.description ?? '')) return false;
    final scA = a.studentCode?.trim() ?? '';
    final scB = b.studentCode?.trim() ?? '';
    if (scA.isNotEmpty && scA == scB) return false;
    return true;
  }

  if (!_mergeableMultiStudentActivityNames.contains(a.name)) return false;
  if (a.name != b.name) return false;
  if ((a.activityTypeCode ?? '') != (b.activityTypeCode ?? '')) return false;
  if ((a.classroomCode ?? '') != (b.classroomCode ?? '')) return false;
  if ((a.activityDateIso ?? '') != (b.activityDateIso ?? '')) return false;
  if ((a.description ?? '') != (b.description ?? '')) return false;
  if (a.name == 'Photo' || a.name == 'Video') {
    final aMedia = (a.photoUrl ?? a.videoUrl ?? '').trim();
    final bMedia = (b.photoUrl ?? b.videoUrl ?? '').trim();
    if (aMedia.isEmpty || aMedia != bMedia) return false;
  }
  final scA = a.studentCode?.trim() ?? '';
  final scB = b.studentCode?.trim() ?? '';
  if (scA.isNotEmpty && scA == scB) return false;
  if (a.name == 'Meal') {
    if (a.mealType != b.mealType) return false;
    if (a.mealQuantity != b.mealQuantity) return false;
  }
  if (a.name == 'Bottle') {
    if (a.amountConsumed != b.amountConsumed) return false;
    if (a.bottleConsumptionStatus != b.bottleConsumptionStatus) return false;
  }
  if (a.name == 'Bathroom') {
    if ((a.bathroomType ?? '') != (b.bathroomType ?? '')) return false;
    if ((a.bathroomSubType ?? '') != (b.bathroomSubType ?? '')) return false;
    if ((a.bathroomDiaperSize ?? '') != (b.bathroomDiaperSize ?? '')) {
      return false;
    }
  }
  return true;
}

List<Map<String, String>>? _mergedStudentActivityRefsForFeed(
  ActivityItem a,
  ActivityItem b,
) {
  final out = <Map<String, String>>[];
  void add(ActivityItem x) {
    final r = x.studentActivityRefs;
    if (r != null && r.isNotEmpty) {
      for (final m in r) {
        out.add(Map<String, String>.from(m));
      }
    } else {
      for (final name in x.studentList) {
        final nm = name.trim();
        if (nm.isEmpty) continue;
        out.add({
          'name': nm,
          'studentCode': x.studentCode?.trim() ?? '',
          'activityCode': x.activityCode?.trim() ?? '',
        });
      }
    }
  }

  add(a);
  add(b);
  final seen = <String>{};
  final unique = <Map<String, String>>[];
  for (final m in out) {
    final ac = (m['activityCode'] ?? '').trim();
    if (ac.isNotEmpty) {
      if (seen.contains(ac)) continue;
      seen.add(ac);
      unique.add(m);
      continue;
    }
    final sc = (m['studentCode'] ?? '').trim();
    final nm = (m['name'] ?? '').trim();
    final key = '$sc|$nm';
    if (seen.contains(key)) continue;
    seen.add(key);
    unique.add(m);
  }
  return unique.isEmpty ? null : unique;
}

ActivityItem mergeTwoActivityItemsForFeed(ActivityItem a, ActivityItem b) {
  final names = <String>[];
  void addUnique(Iterable<String> list) {
    for (final n in list) {
      final t = n.trim();
      if (t.isEmpty) continue;
      if (!names.contains(t)) names.add(t);
    }
  }

  addUnique(a.studentList);
  addUnique(b.studentList);
  if (names.isEmpty) names.add('Student');

  final mergedRefs = _mergedStudentActivityRefsForFeed(a, b);

  return ActivityItem(
    time: a.time,
    date: a.date,
    name: a.name,
    description: a.description,
    photoUrl: a.photoUrl ?? b.photoUrl,
    videoUrl: a.videoUrl ?? b.videoUrl,
    studentList: names,
    createdBy: preferActivityAuthorLabel(a.createdBy, b.createdBy),
    activityType: a.activityType,
    categoryType: a.categoryType,
    mealType: a.mealType,
    mealQuantity: a.mealQuantity,
    amountConsumed: a.amountConsumed,
    bottleConsumptionStatus: a.bottleConsumptionStatus,
    napStartTime: a.napStartTime,
    remainderOn: a.remainderOn,
    napEndTime: a.napEndTime,
    whatHappened: a.whatHappened,
    firstAidAdministered: a.firstAidAdministered,
    staffPresent: preferActivityAuthorLabel(
      a.staffPresent ?? '',
      b.staffPresent ?? '',
    ),
    staffPresentCode: (a.staffPresentCode ?? '').trim().isNotEmpty
        ? a.staffPresentCode!.trim()
        : ((b.staffPresentCode ?? '').trim().isNotEmpty
              ? b.staffPresentCode!.trim()
              : null),
    additionalNotes: a.additionalNotes,
    bathroomType: a.bathroomType,
    bathroomSubType: a.bathroomSubType,
    bathroomDiaperSize: a.bathroomDiaperSize ?? b.bathroomDiaperSize,
    activityTypeCode: a.activityTypeCode,
    activityCode: a.activityCode,
    studentCode: a.studentCode,
    classroomCode: a.classroomCode,
    activityDateIso: a.activityDateIso,
    snapshotAttachments: a.snapshotAttachments ?? b.snapshotAttachments,
    studentActivityRefs: mergedRefs,
    approvalStatus: a.approvalStatus ?? b.approvalStatus,
  );
}

List<ActivityItem> mergeAdjacentMultiStudentFeedItems(
  List<ActivityItem> items,
) {
  if (items.length < 2) return items;
  final out = <ActivityItem>[items.first];
  for (var i = 1; i < items.length; i++) {
    final prev = out.last;
    final cur = items[i];
    if (activityItemsMergeableForFeedDisplay(prev, cur)) {
      out[out.length - 1] = mergeTwoActivityItemsForFeed(prev, cur);
    } else {
      out.add(cur);
    }
  }
  return out;
}

String? _feedGroupKeyForItem(
  ActivityItem x, {
  required bool attendanceRequireDateAndTimeMatch,
}) {
  final name = x.name;
  if (_attendanceMergeableActivityNames.contains(name)) {
    final time = x.time.trim();
    if (time.isEmpty) return null;
    final date = x.date.trim();
    final cc = (x.classroomCode ?? '').trim();
    final desc = (x.description ?? '').trim();
    final dtPart = attendanceRequireDateAndTimeMatch
        ? '|$date|$time'
        : '|$time';
    return 'ATT|$name$dtPart|$cc|$desc';
  }

  if (!_mergeableMultiStudentActivityNames.contains(name)) return null;

  final typeCode = (x.activityTypeCode ?? '').trim();
  final cc = (x.classroomCode ?? '').trim();
  final iso = (x.activityDateIso ?? '').trim();
  final desc = (x.description ?? '').trim();
  final media = (x.photoUrl ?? x.videoUrl ?? '').trim();
  final mealType = (x.mealType ?? '').trim();
  final mealQty = (x.mealQuantity ?? '').trim();
  final bottleAmt = (x.amountConsumed ?? '').trim();
  final bottleStatus = (x.bottleConsumptionStatus ?? '').trim();
  final bathType = (x.bathroomType ?? '').trim();
  final bathSub = (x.bathroomSubType ?? '').trim();
  final bathSize = (x.bathroomDiaperSize ?? '').trim();

  return [
    'ACT',
    name,
    typeCode,
    cc,
    iso,
    desc,
    media,
    mealType,
    mealQty,
    bottleAmt,
    bottleStatus,
    bathType,
    bathSub,
    bathSize,
  ].join('|');
}

List<ActivityItem> groupMultiStudentFeedItems(
  List<ActivityItem> items, {
  required bool attendanceRequireDateAndTimeMatch,
}) {
  if (items.length < 2) return items;

  final out = <ActivityItem>[];
  final indexByKey = <String, int>{};

  for (final item in items) {
    final key = _feedGroupKeyForItem(
      item,
      attendanceRequireDateAndTimeMatch: attendanceRequireDateAndTimeMatch,
    );
    if (key == null) {
      out.add(item);
      continue;
    }
    final existingIndex = indexByKey[key];
    if (existingIndex == null) {
      indexByKey[key] = out.length;
      out.add(item);
      continue;
    }
    out[existingIndex] = mergeTwoActivityItemsForFeed(out[existingIndex], item);
  }

  return out;
}

/// Removes duplicate feed rows that overlapping backend pages can produce.
/// Keyed by (activityCode, studentCode) so a genuine multi-student activity
/// whose per-student rows share an activityCode is NOT collapsed. Rows without
/// a stable activityCode (e.g. attendance/absent-derived rows, which are merged
/// separately by their own group key) are never deduped by code. Order-preserving.
List<ActivityItem> dedupeActivitiesByStableId(List<ActivityItem> items) {
  final seen = <String>{};
  final out = <ActivityItem>[];
  for (final it in items) {
    final code = (it.activityCode ?? '').trim();
    if (code.isEmpty) {
      out.add(it);
      continue;
    }
    if (seen.add('$code|${(it.studentCode ?? '').trim()}')) out.add(it);
  }
  return out;
}

List<String?> feedStudentCodesForNames(ActivityItem activity) {
  final refs = activity.studentActivityRefs;
  final byName = <String, String>{};
  if (refs != null) {
    for (final r in refs) {
      final n = (r['name'] ?? '').trim();
      final c = (r['studentCode'] ?? '').trim();
      if (n.isNotEmpty && c.isNotEmpty) byName[n] = c;
    }
  }
  final fallback = (activity.studentCode ?? '').trim();
  final single = activity.studentList.length == 1;
  return activity.studentList.map<String?>((name) {
    final c = byName[name.trim()];
    if (c != null && c.isNotEmpty) return c;
    if (single && fallback.isNotEmpty) return fallback;
    return null;
  }).toList();
}

/// Option code → label for activity type definitions (`GET …/activity-types/{code}`).
