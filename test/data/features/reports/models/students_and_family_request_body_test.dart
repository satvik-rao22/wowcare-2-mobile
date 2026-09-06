import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/students_and_family_report_params.dart';

void main() {
  /// Payload assertions for StudentsAndFamilyRequestBody, moved here with the wire-building logic
  /// when the domain params classes lost `toRequestBody()` (§8).
  group('StudentsAndFamilyRequestBody', () {
    final startDate = DateTime(2026, 6, 1);
    final endDate = DateTime(2026, 6, 30);
    const studentFields = {'Full Name', 'DOB', 'Classroom'};
    const parentFields = {'First name', 'Last name', 'Email'};
    const statusFilter = 'Active';
    const classrooms = ['ROOM1', 'ROOM2'];
    const tags = ['TAG1', 'TAG2'];

    test('toRequestBody includes all field selections as booleans', () {
      final params = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        studentFieldsSelected: const {'Full Name', 'DOB'},
        parentFieldsSelected: const {'First name'},
        statusFilter: statusFilter,
        format: 'PDF',
        schoolName: 'Test School',
      );

      final body = ReportRequestPayload.fromParams(params).toJson();

      expect(body['reportType'], 'STUDENTS_AND_FAMILY');
      expect(body['fullName'], true);
      expect(body['dob'], true);
      expect(body['classroom'], false);
      expect(body['guardianFirstName'], true);
      expect(body['guardianLastName'], false);
    });
    test('toRequestBody excludes empty arrays', () {
      final params = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        studentFieldsSelected: studentFields,
        parentFieldsSelected: parentFields,
        schoolName: 'Test School',
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final body = ReportRequestPayload.fromParams(params).toJson();

      expect(body.containsKey('roomCodes'), false);
      expect(body.containsKey('tagCodes'), false);
    });
    test('toRequestBody includes non-empty arrays', () {
      final params = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        studentFieldsSelected: studentFields,
        parentFieldsSelected: parentFields,
        statusFilter: statusFilter,
        classroomCodes: classrooms,
        tagCodes: tags,
        schoolName: 'Test School',
        format: 'PDF',
      );

      final body = ReportRequestPayload.fromParams(params).toJson();

      expect(body['roomCodes'], classrooms);
      expect(body['tagCodes'], tags);
    });
    test('toRequestBody includes status filter as a single-element array', () {
      final params = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        schoolName: 'Test School',
        endDate: endDate,
        studentFieldsSelected: studentFields,
        parentFieldsSelected: parentFields,
        statusFilter: 'Inactive',
        format: 'PDF',
      );

      final body = ReportRequestPayload.fromParams(params).toJson();

      // Backend expects an array even for the single-select UI value
      // (confirmed against the web client's verified payload), and the value
      // is upper-cased like every other backend enum in these payloads —
      // added deliberately in aeacb38c.
      expect(body['statusFilter'], ['INACTIVE']);
    });
    test('includes format field in payload', () {
      final params = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        schoolName: 'Test School',
        endDate: endDate,
        studentFieldsSelected: studentFields,
        parentFieldsSelected: parentFields,
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final body = ReportRequestPayload.fromParams(params).toJson();

      expect(body['format'], 'PDF');
    });
  });
}
