import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart';

ActivityItem _item({String? activityCode, String? studentCode, String name = 'Activity'}) {
  return ActivityItem(
    time: '10:00',
    date: '2026-08-27',
    name: name,
    studentList: const <String>[],
    createdBy: 'staff',
    activityCode: activityCode,
    studentCode: studentCode,
  );
}

void main() {
  group('dedupeActivitiesByStableId', () {
    test('collapses two rows with the same (activityCode, studentCode)', () {
      final out = dedupeActivitiesByStableId([
        _item(activityCode: 'ACT-1', studentCode: 'STU-1'),
        _item(activityCode: 'ACT-1', studentCode: 'STU-1'),
      ]);
      expect(out.length, 1);
      expect(out.first.activityCode, 'ACT-1');
      expect(out.first.studentCode, 'STU-1');
    });

    test('keeps rows with same activityCode but different studentCode', () {
      final out = dedupeActivitiesByStableId([
        _item(activityCode: 'ACT-1', studentCode: 'STU-1'),
        _item(activityCode: 'ACT-1', studentCode: 'STU-2'),
      ]);
      expect(out.length, 2);
      expect(out.map((e) => e.studentCode), ['STU-1', 'STU-2']);
    });

    test('never dedupes rows with empty or null activityCode', () {
      final out = dedupeActivitiesByStableId([
        _item(activityCode: null, studentCode: 'STU-1'),
        _item(activityCode: null, studentCode: 'STU-1'),
        _item(activityCode: '', studentCode: 'STU-2'),
        _item(activityCode: '   ', studentCode: 'STU-2'),
      ]);
      expect(out.length, 4);
    });

    test('preserves order and keeps the first occurrence of a duplicate', () {
      final a = _item(activityCode: 'ACT-1', studentCode: 'STU-1', name: 'First');
      final b = _item(activityCode: 'ACT-2', studentCode: 'STU-1', name: 'Second');
      final aDup = _item(activityCode: 'ACT-1', studentCode: 'STU-1', name: 'FirstDuplicate');
      final out = dedupeActivitiesByStableId([a, b, aDup]);
      expect(out.length, 2);
      expect(out[0].name, 'First');
      expect(out[1].name, 'Second');
    });
  });
}
