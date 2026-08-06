import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';

void main() {
  group('StaffDetailsReportParams', () {
    final startDate = DateTime(2026, 6, 1);
    final endDate = DateTime(2026, 6, 30);
    const staffFields = {'Name', 'Email ID', 'Designation'};
    const statusFilter = 'Active Staff';
    const classrooms = ['ROOM1', 'ROOM2'];

    test('creates instance with required fields', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        format: 'PDF',
        schoolName: 'Test School',
      );

      expect(params.reportType, ReportType.staffDetails);
      expect(params.startDate, isNull);
      expect(params.endDate, isNull);
      expect(params.staffFieldsSelected, staffFields);
      expect(params.statusFilter, statusFilter);
    });

    test('creates instance with optional classrooms', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        classroomCodes: classrooms,
        format: 'PDF',
        schoolName: 'Test School',
      );

      expect(params.classroomCodes, classrooms);
    });

    test('toRequestBody excludes startDate and endDate', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        schoolName: 'Test School',
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body.containsKey('startDate'), false);
      expect(body.containsKey('endDate'), false);
    });

    test('toRequestBody includes all field selections as booleans', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        staffFieldsSelected: const {'Name', 'Email ID'},
        statusFilter: statusFilter,
        schoolName: 'Test School',
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['reportType'], 'STAFF_DETAILS');
      expect(body['includeName'], true);
      expect(body['includeEmailId'], true);
      expect(body['includePhoneNumber'], false);
      expect(body['includeDesignation'], false);
    });

    test('toRequestBody maps status correctly', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        staffFieldsSelected: staffFields,
        statusFilter: 'Active Staff',
        format: 'PDF',
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body['status'], 'ACTIVE');
    });

    test('toRequestBody maps inactive status correctly', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        staffFieldsSelected: staffFields,
        statusFilter: 'Inactive Staff',
        format: 'PDF',
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body['status'], 'INACTIVE');
    });

    test('toRequestBody maps all staff status correctly', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        staffFieldsSelected: staffFields,
        schoolName: 'Test School',
        statusFilter: 'All Staff',
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['status'], 'ALL');
    });

    test('toRequestBody excludes empty classrooms', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        format: 'PDF',
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body.containsKey('classroomCodes'), false);
    });

    test('toRequestBody includes non-empty classrooms', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        classroomCodes: classrooms,
        format: 'PDF',
        schoolName: 'Test School',
      );

      final body = params.toRequestBody();

      expect(body['classroomCodes'], classrooms);
    });

    test('toRequestBody includes all 13 staff field flags', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        schoolName: 'Test School',
        endDate: endDate,
        staffFieldsSelected: const {
          'Name',
          'Date Of Birth',
          'Email ID',
          'Phone Number',
          'Address',
          'Primary Classroom',
          'Clock-In-Out Pin',
          'Hire Date',
          'Designation',
          'CDA Expiration Date',
          'CPR Expiration Date',
          'Last Physical Date',
          'Is Active',
        },
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['includeName'], true);
      expect(body['includeDateOfBirth'], true);
      expect(body['includeEmailId'], true);
      expect(body['includePhoneNumber'], true);
      expect(body['includeAddress'], true);
      expect(body['includePrimaryClassroom'], true);
      expect(body['includeClockInOutPin'], true);
      expect(body['includeHireDate'], true);
      expect(body['includeDesignation'], true);
      expect(body['includeCdaExpirationDate'], true);
      expect(body['includeCprExpirationDate'], true);
      expect(body['includeLastPhysicalDate'], true);
      expect(body['includeIsActive'], true);
    });

    test('toCacheIdentifier includes field selections', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        schoolName: 'Test School',
        endDate: endDate,
        staffFieldsSelected: const {'Name', 'Email ID'},
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final identifier = params.toCacheIdentifier();

      expect(identifier.contains('STAFF_DETAILS'), true);
      expect(identifier.contains('2026-06-01'), true);
      expect(identifier.contains('staffFields='), true);
    });

    test('equality works correctly', () {
      final params1 = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        schoolName: 'Test School',
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final params2 = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        schoolName: 'Test School',
        endDate: endDate,
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        format: 'PDF',
      );

      expect(params1, params2);
    });

    test('inequality works correctly for different fields', () {
      final params1 = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        schoolName: 'Test School',
        staffFieldsSelected: const {'Name', 'Email ID'},
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final params2 = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        endDate: endDate,
        staffFieldsSelected: const {'Name'},
        schoolName: 'Test School',
        statusFilter: statusFilter,
        format: 'PDF',
      );

      expect(params1, isNot(params2));
    });

    test('includes format field in payload', () {
      final params = StaffDetailsReportParams(
        reportType: ReportType.staffDetails,
        startDate: startDate,
        schoolName: 'Test School',
        endDate: endDate,
        staffFieldsSelected: staffFields,
        statusFilter: statusFilter,
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['format'], 'PDF');
    });
  });
}
