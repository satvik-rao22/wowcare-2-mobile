import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_absent_toggle_response.dart';

void main() {
  group('StaffAttendanceProfileAbsentToggleResponse.fromJson fidelity', () {
    test('parses a full record identically to the old inline screen code', () {
      final raw = <String, dynamic>{
        'data': {
          'aggregations': {'absentDays': 6},
          'records': {
            'content': [
              {
                'absenceDate': '2026-08-21',
                'markedAbsentTime': '09:15:00',
                'markedAbsentByName': 'Manager',
                'markedAbsentBy': 'MGR_CODE',
                'absenceNote': ' on leave ',
                'markAbsentMethod': 'APP',
                'classroomName': 'Rose',
                'classroomCode': 'CLS_2',
              },
            ],
          },
        },
      };

      final response = StaffAttendanceProfileAbsentToggleResponse.fromJson(raw);

      // agg['absentDays'] as int? ?? 0
      expect(response.absentDays, 6);

      expect(response.records.length, 1);
      final r = response.records.single;

      expect(r.absenceDate, '2026-08-21');
      // markedAbsentTime is pass-through (raw) for _formatApiTime.
      expect(r.markedAbsentTime, '09:15:00');
      // Both name keys stay raw; the screen coalesces them.
      expect(r.markedAbsentByName, 'Manager');
      expect(r.markedAbsentBy, 'MGR_CODE');
      expect(r.absenceNote, ' on leave ');
      expect(r.markAbsentMethod, 'APP');
      expect(r.classroomName, 'Rose');
      expect(r.classroomCode, 'CLS_2');
    });

    test('preserves object-shaped (Map) markedAbsentTime as a raw value', () {
      final raw = <String, dynamic>{
        'data': {
          'aggregations': {'absentDays': 1},
          'records': {
            'content': [
              {
                'markedAbsentTime': {'hour': 9, 'minute': 15},
              },
            ],
          },
        },
      };

      final response = StaffAttendanceProfileAbsentToggleResponse.fromJson(raw);
      final r = response.records.single;
      expect(r.markedAbsentTime, <String, dynamic>{'hour': 9, 'minute': 15});
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

      final response = StaffAttendanceProfileAbsentToggleResponse.fromJson(raw);

      expect(response.absentDays, 0);

      final r = response.records.single;
      expect(r.absenceDate, '');
      expect(r.markedAbsentTime, isNull);
      expect(r.markedAbsentByName, isNull);
      expect(r.markedAbsentBy, isNull);
      expect(r.absenceNote, '');
      expect(r.markAbsentMethod, isNull);
      expect(r.classroomName, isNull);
      expect(r.classroomCode, isNull);
    });

    test('empty / missing containers yield zero absentDays and no records', () {
      final empty = StaffAttendanceProfileAbsentToggleResponse.fromJson(
        <String, dynamic>{},
      );
      expect(empty.absentDays, 0);
      expect(empty.records, isEmpty);

      final partial = StaffAttendanceProfileAbsentToggleResponse.fromJson(
        <String, dynamic>{'data': <String, dynamic>{}},
      );
      expect(partial.absentDays, 0);
      expect(partial.records, isEmpty);
    });

    test(
      'exposes the pageable absentPage shape the dashboard cubit consumes',
      () {
        // The cubit parses the SAME payload the pageable way, reading
        // `data.content` + `data.number/size/totalPages/totalElements` +
        // `data.aggregations.absentDays`.
        final raw = <String, dynamic>{
          'data': {
            'aggregations': {'absentDays': 6},
            // Pageable path (StaffAttendanceAbsentPageModel.fromJson).
            'content': [
              {
                'staffCode': 'STF_1',
                'staffName': 'Manager',
                'absenceDate': '2026-08-21',
              },
              {'staffCode': 'STF_2'},
            ],
            'number': 0,
            'size': 10,
            'totalPages': 2,
            'totalElements': 12,
          },
        };

        final response =
            StaffAttendanceProfileAbsentToggleResponse.fromJson(raw);

        final page = response.absentPage;
        expect(page.items.length, 2);
        expect(page.items.first.staffCode, 'STF_1');
        expect(page.page, 0);
        expect(page.size, 10);
        expect(page.totalPages, 2);
        expect(page.totalElements, 12);
        // pageNumber + 1 < totalPages -> 0 + 1 < 2 -> true.
        expect(page.hasMore, isTrue);
        expect(page.absentDays, 6);
      },
    );
  });
}
