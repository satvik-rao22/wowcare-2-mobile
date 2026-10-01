import 'package:wowcare/domain/features/activity/entities/activity_detail.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/presentation/features/activities/model/activity_item.dart';
import 'package:wowcare/presentation/features/activities/model/activity_item_from_feed_row.dart';

/// Rebuilds UI model from `GET /api/v1/activities/code/{code}` for edit prefetch.
///
/// [schoolIana] MUST be passed (e.g. `await editor.resolveSchoolTimezone()`)
/// — omitting it makes [activityItemFromFeedRow] fall back to
/// `DateTime.toLocal()` (the DEVICE's timezone), showing the wrong Date/Time
/// on this screen whenever the device isn't in the school's own zone.
ActivityItem activityItemFromActivityDetail(
  ActivityDetail detail, {
  String? viewerDisplayName,
  String? schoolIana,
}) {
  return activityItemFromFeedRow(
    ActivityFeedRow.fromActivityDetail(detail),
    viewerDisplayName: viewerDisplayName,
    schoolIana: schoolIana,
    activityTypeOptionCodeToLabel: activityFeedOptionLabelsForType(
      detail.activityTypeCode,
    ),
  );
}

/// Maps [ActivityItem] to student maps used by create/edit activity screens.
List<Map<String, dynamic>> studentDataMapsForActivityEdit(
  ActivityItem activity,
) {
  final room = activity.classroomCode?.trim();
  final refs = activity.studentActivityRefs;
  if (refs != null && refs.isNotEmpty) {
    return refs
        .map(
          (r) => <String, dynamic>{
            'name': (r['name'] ?? '').trim().isEmpty
                ? 'Student'
                : (r['name'] ?? '').trim(),
            if ((r['studentCode'] ?? '').trim().isNotEmpty)
              'studentCode': r['studentCode']!.trim(),
            if (room != null && room.isNotEmpty) 'classroomCode': room,
            if ((r['activityCode'] ?? '').trim().isNotEmpty)
              'activityCode': r['activityCode']!.trim(),
          },
        )
        .toList();
  }
  final code = activity.studentCode?.trim();
  final maps = <Map<String, dynamic>>[];
  for (final name in activity.studentList) {
    maps.add({
      'name': name,
      if (code != null && code.isNotEmpty) 'studentCode': code,
      if (room != null && room.isNotEmpty) 'classroomCode': room,
      if ((activity.activityCode ?? '').trim().isNotEmpty)
        'activityCode': activity.activityCode!.trim(),
    });
  }
  if (maps.isEmpty && activity.studentList.isEmpty) {
    maps.add({'name': 'Student'});
  }
  return maps;
}
