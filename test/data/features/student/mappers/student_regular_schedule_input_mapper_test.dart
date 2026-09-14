import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_regular_schedule_input_mapper.dart';
import 'package:wowcare/domain/features/student/entities/student_regular_schedule_input.dart';

void main() {
  test('maps a schedule entry to the exact PATCH body', () {
    const entry = StudentRegularScheduleInput(
      dayOfWeek: 'MONDAY',
      startTime: '08:00:00',
      halfDay: '12:00:00',
      endTime: '16:00:00',
    );

    expect(studentRegularScheduleInputToPayload(entry), <String, dynamic>{
      'dayOfWeek': 'MONDAY',
      'startTime': '08:00:00',
      'halfDay': '12:00:00',
      'endTime': '16:00:00',
    });
  });
}
