import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/staff_schedule_entry.dart';

void main() {
  group('StaffWorkScheduleEntry.toPayload', () {
    test('produces exactly the Map the edit-schedule view used to build', () {
      const entry = StaffWorkScheduleEntry(
        dayOfWeek: 'MONDAY',
        workStartTime: '09:00:00',
        workEndTime: '17:00:00',
      );

      expect(entry.toPayload(), {
        'dayOfWeek': 'MONDAY',
        'workStartTime': '09:00:00',
        'workEndTime': '17:00:00',
      });
      expect(entry.toPayload().keys.toList(), [
        'dayOfWeek',
        'workStartTime',
        'workEndTime',
      ]);
    });
  });

  group('StaffBreakScheduleEntry.toPayload', () {
    test('produces exactly the Map the edit-schedule view used to build', () {
      const entry = StaffBreakScheduleEntry(
        dayOfWeek: 'MONDAY',
        breakType: 'LUNCH',
        breakStartTime: '12:00:00',
        breakEndTime: '13:00:00',
      );

      expect(entry.toPayload(), {
        'dayOfWeek': 'MONDAY',
        'breakType': 'LUNCH',
        'breakStartTime': '12:00:00',
        'breakEndTime': '13:00:00',
      });
      expect(entry.toPayload().keys.toList(), [
        'dayOfWeek',
        'breakType',
        'breakStartTime',
        'breakEndTime',
      ]);
    });
  });

  group('equality', () {
    test('value-equal work entries are equal; differing time unequal', () {
      const a = StaffWorkScheduleEntry(
        dayOfWeek: 'MONDAY',
        workStartTime: '09:00:00',
        workEndTime: '17:00:00',
      );
      const b = StaffWorkScheduleEntry(
        dayOfWeek: 'MONDAY',
        workStartTime: '09:00:00',
        workEndTime: '17:00:00',
      );
      const c = StaffWorkScheduleEntry(
        dayOfWeek: 'MONDAY',
        workStartTime: '08:00:00',
        workEndTime: '17:00:00',
      );

      expect(a, b);
      expect(a == c, isFalse);
    });
  });
}
