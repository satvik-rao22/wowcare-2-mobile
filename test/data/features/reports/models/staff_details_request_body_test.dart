import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';

void main() {
  /// Payload assertions for StaffDetailsRequestBody, moved here with the wire-building logic
  /// when the domain params classes lost `toRequestBody()` (§8).
  group('StaffDetailsRequestBody', () {
    final startDate = DateTime(2026, 6, 1);
    final endDate = DateTime(2026, 6, 30);
    const staffFields = {'Name', 'Email ID', 'Designation'};
    const statusFilter = 'Active Staff';
    const classrooms = ['ROOM1', 'ROOM2'];

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

      expect(body['format'], 'PDF');
    });
  });
}
