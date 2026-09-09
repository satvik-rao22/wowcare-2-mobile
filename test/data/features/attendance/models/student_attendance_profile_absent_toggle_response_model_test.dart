import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/attendance/models/student_attendance_profile_absent_toggle_response_model.dart';

void main() {
  group(
    'StudentAttendanceProfileAbsentToggleResponseModel.fromJson fidelity',
    () {
      test(
        'parses a full record identically to the old inline screen code',
        () {
          final raw = <String, dynamic>{
            'data': {
              'aggregations': {'absentDays': 4},
              'records': {
                'content': [
                  {
                    'absenceDate': '2026-08-20',
                    'markedAbsentTime': '08:00:00',
                    'markedAbsentByName': 'Alice',
                    'markedAbsentBy': 'ALICE_CODE',
                    'absenceNote': ' sick leave ',
                    'markAbsentMethod': 'APP',
                    'classroomCode': 'CLS_1',
                    'classroomName': 'Sunflower',
                  },
                ],
              },
            },
          };

          final response =
              StudentAttendanceProfileAbsentToggleResponseModel.fromJson(raw);

          // agg['absentDays'] as int? ?? 0
          expect(response.absentDays, 4);

          expect(response.records.length, 1);
          final r = response.records.single;

          expect(r.absenceDate, '2026-08-20');
          // markedAbsentTime is pass-through (raw) for _formatApiTime.
          expect(r.markedAbsentTime, '08:00:00');
          // Both name keys stay raw; the screen coalesces them.
          expect(r.markedAbsentByName, 'Alice');
          expect(r.markedAbsentBy, 'ALICE_CODE');
          // `?? ''` default baked in; the screen consumes as-is (no trim here).
          expect(r.absenceNote, ' sick leave ');
          expect(r.markAbsentMethod, 'APP');
          expect(r.classroomCode, 'CLS_1');
          expect(r.classroomName, 'Sunflower');
        },
      );

      test('preserves object-shaped (Map) markedAbsentTime as a raw value', () {
        final raw = <String, dynamic>{
          'data': {
            'aggregations': {'absentDays': 1},
            'records': {
              'content': [
                {
                  'markedAbsentTime': {'hour': 8, 'minute': 30},
                },
              ],
            },
          },
        };

        final response =
            StudentAttendanceProfileAbsentToggleResponseModel.fromJson(raw);
        final r = response.records.single;
        expect(r.markedAbsentTime, <String, dynamic>{'hour': 8, 'minute': 30});
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

        final response =
            StudentAttendanceProfileAbsentToggleResponseModel.fromJson(raw);

        expect(response.absentDays, 0);

        final r = response.records.single;
        expect(r.absenceDate, '');
        expect(r.markedAbsentTime, isNull);
        expect(r.markedAbsentByName, isNull);
        expect(r.markedAbsentBy, isNull);
        expect(r.absenceNote, '');
        expect(r.markAbsentMethod, isNull);
        expect(r.classroomCode, isNull);
        expect(r.classroomName, isNull);
      });

      test(
        'empty / missing containers yield zero absentDays and no records',
        () {
          final empty =
              StudentAttendanceProfileAbsentToggleResponseModel.fromJson(
                <String, dynamic>{},
              );
          expect(empty.absentDays, 0);
          expect(empty.records, isEmpty);

          final partial =
              StudentAttendanceProfileAbsentToggleResponseModel.fromJson(
                <String, dynamic>{'data': <String, dynamic>{}},
              );
          expect(partial.absentDays, 0);
          expect(partial.records, isEmpty);

          final noContent =
              StudentAttendanceProfileAbsentToggleResponseModel.fromJson(
                <String, dynamic>{
                  'data': {
                    'aggregations': {'absentDays': 3},
                    'records': <String, dynamic>{},
                  },
                },
              );
          expect(noContent.absentDays, 3);
          expect(noContent.records, isEmpty);
        },
      );
    },
  );
}
