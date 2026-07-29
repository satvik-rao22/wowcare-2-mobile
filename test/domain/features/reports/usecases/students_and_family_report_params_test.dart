import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/students_and_family_report_params.dart';

void main() {
  group('StudentsAndFamilyReportParams', () {
    final startDate = DateTime(2026, 6, 1);
    final endDate = DateTime(2026, 6, 30);
    const studentFields = {'Full Name', 'DOB', 'Classroom'};
    const parentFields = {'First name', 'Last name', 'Email'};
    const statusFilter = 'Active';
    const classrooms = ['ROOM1', 'ROOM2'];
    const tags = ['TAG1', 'TAG2'];

    test('creates instance with required fields', () {
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

      expect(params.reportType, ReportType.studentsAndFamily);
      expect(params.startDate, startDate);
      expect(params.endDate, endDate);
      expect(params.studentFieldsSelected, studentFields);
      expect(params.parentFieldsSelected, parentFields);
      expect(params.statusFilter, statusFilter);
    });

    test('creates instance with optional classrooms and tags', () {
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

      expect(params.classroomCodes, classrooms);
      expect(params.tagCodes, tags);
    });

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

      final body = params.toRequestBody();

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

      final body = params.toRequestBody();

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

      final body = params.toRequestBody();

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

      final body = params.toRequestBody();

      // Backend expects an array even for the single-select UI value
      // (confirmed against the web client's verified payload).
      expect(body['statusFilter'], ['Inactive']);
    });

    test('toCacheIdentifier includes field selections', () {
      final params = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        studentFieldsSelected: const {'Full Name', 'DOB'},
        parentFieldsSelected: const {'First name'},
        statusFilter: statusFilter,
        schoolName: 'Test School',
        format: 'PDF',
      );

      final identifier = params.toCacheIdentifier();

      expect(identifier.contains('STUDENTS_AND_FAMILY'), true);
      expect(identifier.contains('2026-06-01'), true);
      expect(identifier.contains('studentFields='), true);
      expect(identifier.contains('parentFields='), true);
    });

    test('equality works correctly', () {
      final params1 = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        studentFieldsSelected: studentFields,
        parentFieldsSelected: parentFields,
        statusFilter: statusFilter,
        schoolName: 'Test School',
        format: 'PDF',
      );

      final params2 = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        studentFieldsSelected: studentFields,
        parentFieldsSelected: parentFields,
        statusFilter: statusFilter,
        schoolName: 'Test School',
        format: 'PDF',
      );

      expect(params1, params2);
    });

    test('inequality works correctly for different fields', () {
      final params1 = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        schoolName: 'Test School',
        studentFieldsSelected: const {'Full Name', 'DOB'},
        parentFieldsSelected: parentFields,
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final params2 = StudentsAndFamilyReportParams(
        reportType: ReportType.studentsAndFamily,
        startDate: startDate,
        endDate: endDate,
        studentFieldsSelected: const {'Full Name'},
        parentFieldsSelected: parentFields,
        statusFilter: statusFilter,
        schoolName: 'Test School',
        format: 'PDF',
      );

      expect(params1, isNot(params2));
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

      final body = params.toRequestBody();

      expect(body['format'], 'PDF');
    });
  });
}
