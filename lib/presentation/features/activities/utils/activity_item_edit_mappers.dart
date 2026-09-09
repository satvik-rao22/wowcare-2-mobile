import 'package:wowcare/domain/features/activity/entities/activity_detail.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart'
    show activityItemFromFeedRow, activityFeedOptionLabelsForType;

/// Rebuilds UI model from `GET /api/v1/activities/code/{code}` for edit prefetch.
ActivityItem activityItemFromActivityDetail(
  ActivityDetail detail, {
  String? viewerDisplayName,
}) {
  return activityItemFromFeedRow(
    ActivityFeedRow.fromActivityDetail(detail),
    viewerDisplayName: viewerDisplayName,
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
