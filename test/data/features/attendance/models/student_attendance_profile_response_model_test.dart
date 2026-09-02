import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/attendance/models/student_attendance_profile_response_model.dart';

void main() {
  group('StudentAttendanceProfileResponseModel.fromJson fidelity', () {
    test('parses a full record identically to the old inline screen code', () {
      // A representative raw backend response: data.aggregations + one full
      // record under data.records.content.
      final raw = <String, dynamic>{
        'data': {
          'aggregations': {'attendedDays': 5, 'totalAttendedTime': '12h 30m'},
          'records': {
            'content': [
              {
                'attendanceDate': '2026-08-20',
                'sequenceNumber': 2,
                'totalSequenceCount': 3,
                'signedInTime': '08:00:00',
                'signedOutTime': '17:00:00',
                'transferTime': '12:00:00',
                'nextActionTime': '13:00:00',
                'classroomName': 'Sunflower',
                'classroomCode': 'CLS_1',
                'signedOutMethod': 'SYSTEM',
                'transferredBy': ' Alice ',
                'signedInBy': ' Bob ',
                'signedOutBy': ' Carol ',
                'attendedTime': '9h 0m',
                'attendedHours': 9,
                'attendedMinutes': 0,
                'signedInMethod': 'APP',
                'notExpectedComment': ' late arrival ',
              },
            ],
          },
        },
      };

      final response = StudentAttendanceProfileResponseModel.fromJson(raw);

      // --- Aggregations (agg['attendedDays'] as int? ?? 0 / totalAttendedTime) ---
      expect(response.attendedDays, 5);
      expect(response.totalAttendedTime, '12h 30m');

      expect(response.records.length, 1);
      final r = response.records.single;

      // Each field must equal what `m['key'] as T? ?? default` produced.
      expect(r.attendanceDate, '2026-08-20');
      expect(r.sequenceNumber, 2);
      expect(r.totalSequenceCount, 3);
      // Time fields are pass-through (raw) for _formatApiTime.
      expect(r.signedInTime, '08:00:00');
      expect(r.signedOutTime, '17:00:00');
      expect(r.transferTime, '12:00:00');
      expect(r.nextActionTime, '13:00:00');
      expect(r.classroomName, 'Sunflower');
      expect(r.classroomCode, 'CLS_1');
      expect(r.signedOutMethod, 'SYSTEM');
      // The `?? ''` default is baked in; the screen keeps the .trim().
      expect(r.transferredBy, ' Alice ');
      expect(r.signedInBy, ' Bob ');
      expect(r.signedOutBy, ' Carol ');
      expect(r.attendedTime, '9h 0m');
      expect(r.attendedHours, 9);
      expect(r.attendedMinutes, 0);
      expect(r.signedInMethod, 'APP');
      expect(r.notExpectedComment, ' late arrival ');
    });

    test('preserves object-shaped (Map) time payloads as raw values', () {
      // _formatApiTime accepts {hour, minute, ...} maps, so the raw value must
      // survive untouched rather than being coerced/dropped.
      final raw = <String, dynamic>{
        'data': {
          'aggregations': {'attendedDays': 1, 'totalAttendedTime': '1h'},
          'records': {
            'content': [
              {
                'signedInTime': {'hour': 8, 'minute': 30},
              },
            ],
          },
        },
      };

      final response = StudentAttendanceProfileResponseModel.fromJson(raw);
      final r = response.records.single;
      expect(r.signedInTime, <String, dynamic>{'hour': 8, 'minute': 30});
    });

    test('missing per-record keys fall back to the screen defaults', () {
      final raw = <String, dynamic>{
        'data': {
          'aggregations': <String, dynamic>{},
          'records': {
            'content': [<String, dynamic>{}],
          },
        },
      };

      final response = StudentAttendanceProfileResponseModel.fromJson(raw);

      // Missing aggregation keys.
      expect(response.attendedDays, 0);
      expect(response.totalAttendedTime, '');

      final r = response.records.single;
      expect(r.attendanceDate, '');
      expect(r.sequenceNumber, 1);
      expect(r.totalSequenceCount, 1);
      expect(r.signedInTime, isNull);
      expect(r.signedOutTime, isNull);
      expect(r.transferTime, isNull);
      expect(r.nextActionTime, isNull);
      expect(r.classroomName, isNull);
      expect(r.classroomCode, isNull);
      expect(r.signedOutMethod, isNull);
      expect(r.transferredBy, '');
      expect(r.signedInBy, '');
      expect(r.signedOutBy, '');
      expect(r.attendedTime, '');
      expect(r.attendedHours, 0);
      expect(r.attendedMinutes, 0);
      expect(r.signedInMethod, isNull);
      expect(r.notExpectedComment, '');
    });

    test(
      'empty / missing containers yield zero aggregations and no records',
      () {
        // Completely empty top-level map.
        final empty = StudentAttendanceProfileResponseModel.fromJson(
          <String, dynamic>{},
        );
        expect(empty.attendedDays, 0);
        expect(empty.totalAttendedTime, '');
        expect(empty.records, isEmpty);

        // data present but without aggregations / records.
        final partial = StudentAttendanceProfileResponseModel.fromJson(
          <String, dynamic>{'data': <String, dynamic>{}},
        );
        expect(partial.attendedDays, 0);
        expect(partial.totalAttendedTime, '');
        expect(partial.records, isEmpty);

        // records present but no content list.
        final noContent = StudentAttendanceProfileResponseModel.fromJson(
          <String, dynamic>{
            'data': {
              'aggregations': {'attendedDays': 3, 'totalAttendedTime': '3h'},
              'records': <String, dynamic>{},
            },
          },
        );
        expect(noContent.attendedDays, 3);
        expect(noContent.totalAttendedTime, '3h');
        expect(noContent.records, isEmpty);
      },
    );
  });
}
