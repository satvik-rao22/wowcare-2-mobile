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
  });
}
