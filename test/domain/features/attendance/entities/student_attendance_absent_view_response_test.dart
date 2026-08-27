import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_view_response.dart';

void main() {
  group('StudentAttendanceAbsentViewResponse.fromJson fidelity', () {
    test('exposes the raw nested `data` page map verbatim', () {
      final raw = <String, dynamic>{
        'data': {
          'content': [
            {
              'studentCode': 'STU_1',
              'studentName': 'Alice',
              'classroomCode': 'CLS_1',
              'classroomName': 'Sunflower',
              'absenceDate': '2026-08-20',
              'absentDays': 3,
              'markedAbsentTime': '08:00:00',
              'markedAbsentByName': 'Ms. Bee',
              'absenceNote': 'sick leave',
            },
          ],
          'last': false,
          'number': 0,
        },
      };

      final response = StudentAttendanceAbsentViewResponse.fromJson(raw);

      // The screen does `data['data'] as Map<String, dynamic>? ?? {}` then
      // hands that page map to `_applyPagePayload` / `saveCache` unchanged.
      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data!['last'], false);
      expect(response.data!['number'], 0);
      final content = response.data!['content'] as List<dynamic>;
      expect(content.length, 1);
      final first = content.single as Map<String, dynamic>;
      expect(first['studentCode'], 'STU_1');
      expect(first['studentName'], 'Alice');
      expect(first['absentDays'], 3);
      // Object-shaped time survives untouched for the screen's `parseTime`.
    });

    test('preserves an object-shaped markedAbsentTime inside the page map', () {
      final raw = <String, dynamic>{
        'data': {
          'content': [
            {
              'markedAbsentTime': {'hour': 8, 'minute': 30, 'second': 15},
            },
          ],
          'last': true,
          'number': 2,
        },
      };

      final response = StudentAttendanceAbsentViewResponse.fromJson(raw);
      final content = response.data!['content'] as List<dynamic>;
      final first = content.single as Map<String, dynamic>;
      expect(
        first['markedAbsentTime'],
        <String, dynamic>{'hour': 8, 'minute': 30, 'second': 15},
      );
    });

    test('missing `data` key yields a null composed field (screen `?? {}`)', () {
      final response = StudentAttendanceAbsentViewResponse.fromJson(
        <String, dynamic>{},
      );
      // The screen supplies its own `?? {}` default at the consume site, so
      // the model itself leaves this null (byte-faithful to the raw cast).
      expect(response.data, isNull);
    });

    test('an empty `data` object is exposed as an empty map, not null', () {
      final response = StudentAttendanceAbsentViewResponse.fromJson(
        <String, dynamic>{'data': <String, dynamic>{}},
      );
      expect(response.data, isNotNull);
      expect(response.data, isEmpty);
      // `content` absent -> screen's `root['content'] as List? ?? const []`.
      expect(response.data!['content'], isNull);
    });

    test('props reflect the composed page map for value equality', () {
      final a = StudentAttendanceAbsentViewResponse.fromJson(
        <String, dynamic>{
          'data': {
            'content': const <dynamic>[],
            'last': true,
            'number': 0,
          },
        },
      );
      final b = StudentAttendanceAbsentViewResponse.fromJson(
        <String, dynamic>{
          'data': {
            'content': const <dynamic>[],
            'last': true,
            'number': 0,
          },
        },
      );
      expect(a, equals(b));
      expect(a.props, [a.data]);
    });
  });
}
