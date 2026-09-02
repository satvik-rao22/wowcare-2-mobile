import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';

void main() {
  group('AttendanceProfileAbsentToggleQuery.toQueryParameters', () {
    test('student toggle (List sort, studentCode, with pageable aliases)', () {
      const query = AttendanceProfileAbsentToggleQuery(
        studentCode: 'STU-1',
        fromAbsenceDate: '2026-08-01',
        toAbsenceDate: '2026-08-27',
        page: 0,
        size: 100,
        sort: ['absenceDate,desc'],
        allowedClassroomCodes: ['CR-1', 'CR-2'],
        includePageableAliasParams: true,
      );

      expect(query.toQueryParameters(), <String, dynamic>{
        'studentCode': 'STU-1',
        'fromAbsenceDate': '2026-08-01',
        'toAbsenceDate': '2026-08-27',
        'page': 0,
        'size': 100,
        'sort': ['absenceDate,desc'],
        'allowedClassroomCodes': ['CR-1', 'CR-2'],
        'pageable.page': 0,
        'pageable.size': 100,
        'pageable.sort': ['absenceDate,desc'],
      });
    });

    test('cubit toggle (String sort, staffCode-only, no aliases, no scope)', () {
      const query = AttendanceProfileAbsentToggleQuery(
        staffCode: 'STF-1',
        fromAbsenceDate: '2026-08-01',
        toAbsenceDate: '2026-08-27',
        page: 2,
        size: 20,
        sort: 'absenceDate,desc',
      );

      final params = query.toQueryParameters();

      expect(params, <String, dynamic>{
        'staffCode': 'STF-1',
        'fromAbsenceDate': '2026-08-01',
        'toAbsenceDate': '2026-08-27',
        'page': 2,
        'size': 20,
        'sort': 'absenceDate,desc',
      });
      // sort preserved verbatim as a String (not a List).
      expect(params['sort'], isA<String>());
      // No pageable alias keys when includePageableAliasParams is false.
      expect(params.containsKey('pageable.page'), isFalse);
      expect(params.containsKey('pageable.size'), isFalse);
      expect(params.containsKey('pageable.sort'), isFalse);
      // studentCode absent when only staffCode is set.
      expect(params.containsKey('studentCode'), isFalse);
      // allowedClassroomCodes omitted when null.
      expect(params.containsKey('allowedClassroomCodes'), isFalse);
    });

    test('omits pageable.sort when aliases requested but sort is null', () {
      const query = AttendanceProfileAbsentToggleQuery(
        studentCode: 'STU-1',
        fromAbsenceDate: '2026-08-01',
        toAbsenceDate: '2026-08-27',
        page: 0,
        size: 100,
        includePageableAliasParams: true,
      );

      final params = query.toQueryParameters();

      expect(params.containsKey('sort'), isFalse);
      expect(params.containsKey('pageable.sort'), isFalse);
      expect(params['pageable.page'], 0);
      expect(params['pageable.size'], 100);
    });
  });
}
