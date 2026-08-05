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
        classroomCodes: classroomCodes,
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
        classroomCodes: classroomCodes,
        studentCodes: studentCodes,
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body['reportType'], 'SCHOOL_INCIDENT');
      expect(body['roomCodes'], classroomCodes);
      expect(body.containsKey('classroomCodes'), false);
    });

    test('omits schoolName when null', () {
      final params = ReportRequestParams(
        reportType: ReportType.studentAttendancePerStudent,
        startDate: startDate,
        endDate: endDate,
        format: 'PDF',
        classroomCodes: classroomCodes,
        schoolName: null,
      );

      final body = params.toRequestBody();

      expect(body.containsKey('schoolName'), false);
    });
  });
}
