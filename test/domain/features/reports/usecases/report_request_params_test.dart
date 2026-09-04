import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';

void main() {
  group('ReportRequestParams', () {
    final startDate = DateTime(2026, 1, 1);
    final endDate = DateTime(2026, 1, 31);
    const classroomCodes = ['CLS_1', 'CLS_2'];
    const studentCodes = ['STD_1'];

    test('uses roomCodes for STUDENT_ATTENDANCE_PER_STUDENT', () {
      final params = ReportRequestParams(
        reportType: ReportType.studentAttendancePerStudent,
        startDate: startDate,
        endDate: endDate,
        format: 'PDF',
        roomCodes: classroomCodes,
        studentCodes: studentCodes,
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body['reportType'], 'STUDENT_ATTENDANCE_PER_STUDENT');
      expect(body['roomCodes'], classroomCodes);
      expect(body.containsKey('classroomCodes'), false);
      expect(body['studentCodes'], studentCodes);
      expect(body['schoolName'], 'Test School');
    });

    test('uses roomCodes for SCHOOL_INCIDENT', () {
      final params = ReportRequestParams(
        reportType: ReportType.studentIncident,
        startDate: startDate,
        endDate: endDate,
        format: 'PDF',
        roomCodes: classroomCodes,
        studentCodes: studentCodes,
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body['reportType'], 'SCHOOL_INCIDENT');
      expect(body['roomCodes'], classroomCodes);
      expect(body.containsKey('classroomCodes'), false);
    });

    test('uses roomCodes for STAFF_ABSENT', () {
      final params = ReportRequestParams(
        reportType: ReportType.staffAbsent,
        startDate: startDate,
        endDate: endDate,
        format: 'PDF',
        roomCodes: classroomCodes,
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body['reportType'], 'STAFF_ABSENT');
      expect(body['startDate'], '2026-01-01');
      expect(body['endDate'], '2026-01-31');
      expect(body['roomCodes'], classroomCodes);
      expect(body.containsKey('classroomCodes'), false);
      expect(body['schoolName'], 'Test School');
      expect(body['format'], 'PDF');
    });

    test('omits schoolName when null', () {
      final params = ReportRequestParams(
        reportType: ReportType.studentAttendancePerStudent,
        startDate: startDate,
        endDate: endDate,
        format: 'PDF',
        roomCodes: classroomCodes,
        schoolName: null,
      );

      final body = params.toRequestBody();

      expect(body.containsKey('schoolName'), false);
    });

    test('uses dateFrom and dateTo in ISO-8601 for BILLING_TRANSACTION', () {
      final utcStart = DateTime.utc(2026, 1, 1);
      final utcEnd = DateTime.utc(2026, 1, 31);

      final params = ReportRequestParams(
        reportType: ReportType.billingTransaction,
        startDate: utcStart,
        endDate: utcEnd,
        format: 'PDF',
        schoolName: 'School name ',
      );

      final body = params.toRequestBody();

      expect(body['reportType'], 'BILLING_TRANSACTION');
      expect(body['dateFrom'], '2026-01-01T00:00:00.000Z');
      expect(body['dateTo'], '2026-01-31T00:00:00.000Z');
      expect(body.containsKey('startDate'), false);
      expect(body.containsKey('endDate'), false);
    });
  });
}
