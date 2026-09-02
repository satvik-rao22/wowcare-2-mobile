import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';

void main() {
  group('AttendanceProfileQuery.toQueryParameters', () {
    test('student profile (List sort, studentCode + allowedClassroomCodes)', () {
      const query = AttendanceProfileQuery(
        studentCode: 'STU-1',
        fromAttendanceDate: '2026-08-01',
        toAttendanceDate: '2026-08-27',
        page: 0,
        size: 100,
        sort: ['attendanceDate,desc'],
        allowedClassroomCodes: ['CR-1', 'CR-2'],
      );

      expect(query.toQueryParameters(), <String, dynamic>{
        'studentCode': 'STU-1',
        'fromAttendanceDate': '2026-08-01',
        'toAttendanceDate': '2026-08-27',
        'page': 0,
        'size': 100,
        'sort': ['attendanceDate,desc'],
        'allowedClassroomCodes': ['CR-1', 'CR-2'],
      });
    });

    test('cubit profile (String sort, staffCode-only, no classroom scope)', () {
      const query = AttendanceProfileQuery(
        staffCode: 'STF-1',
        fromAttendanceDate: '2026-08-01',
        toAttendanceDate: '2026-08-27',
        page: 2,
        size: 20,
        sort: 'attendanceDate,desc',
      );

      final params = query.toQueryParameters();

      expect(params, <String, dynamic>{
        'staffCode': 'STF-1',
        'fromAttendanceDate': '2026-08-01',
        'toAttendanceDate': '2026-08-27',
        'page': 2,
        'size': 20,
        'sort': 'attendanceDate,desc',
      });
      // sort preserved verbatim as a String (not a List).
      expect(params['sort'], isA<String>());
      // studentCode absent when only staffCode is set.
      expect(params.containsKey('studentCode'), isFalse);
    });

    test('omits studentCode/staffCode when null and allowedClassroomCodes when '
        'null', () {
      const query = AttendanceProfileQuery(
        fromAttendanceDate: '2026-08-01',
        toAttendanceDate: '2026-08-27',
        page: 0,
        size: 10,
        sort: ['attendanceDate,desc'],
      );

      final params = query.toQueryParameters();

      expect(params.containsKey('studentCode'), isFalse);
      expect(params.containsKey('staffCode'), isFalse);
      expect(params.containsKey('allowedClassroomCodes'), isFalse);
      expect(params, <String, dynamic>{
        'fromAttendanceDate': '2026-08-01',
        'toAttendanceDate': '2026-08-27',
        'page': 0,
        'size': 10,
        'sort': ['attendanceDate,desc'],
      });
    });

    test('omits sort when null', () {
      const query = AttendanceProfileQuery(
        studentCode: 'STU-1',
        fromAttendanceDate: '2026-08-01',
        toAttendanceDate: '2026-08-27',
        page: 0,
        size: 10,
      );

      expect(query.toQueryParameters().containsKey('sort'), isFalse);
    });
  });
}
