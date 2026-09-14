import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';

void main() {
  group('SchoolImmunizationReportParams', () {
    final startDate = DateTime(2026, 6, 1);
    final endDate = DateTime(2026, 6, 30);
    const vaccineCodes = ['DTaP', 'Polio', 'MMR'];
    const statusFilters = ['ACTIVE'];
    const classrooms = ['ROOM1', 'ROOM2'];
    const tags = ['TAG1', 'TAG2'];

    test('creates instance with required fields', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        includeParentName: true,
        includeParentEmail: true,

        format: 'PDF',
        schoolName: 'Dummy School',
      );

      expect(params.reportType, ReportType.immunization);
      expect(params.startDate, startDate);
      expect(params.endDate, endDate);
      expect(params.vaccineCodes, vaccineCodes);
      expect(params.statusFilters, statusFilters);
      expect(params.includeParentName, true);
      expect(params.includeParentEmail, true);
    });
    test('creates instance with optional classrooms and tags', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        includeParentName: false,
        includeParentEmail: false,
        classroomCodes: classrooms,
        tagCodes: tags,
        format: 'PDF',
        schoolName: 'Dummy School',
      );

      expect(params.classroomCodes, classrooms);
      expect(params.tagCodes, tags);
    });
    test('toCacheIdentifier includes vaccine and status filters', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: const ['DTaP', 'Polio'],
        statusFilters: const ['ACTIVE'],
        includeParentName: true,
        includeParentEmail: true,
        format: 'PDF',
        schoolName: 'Dummy School',
      );

      final identifier = params.toCacheIdentifier();

      expect(identifier.contains('IMMUNIZATION'), true);
      expect(identifier.contains('vaccines=DTaP,Polio'), true);
      expect(identifier.contains('statuses=ACTIVE'), true);
    });
    test('equality works correctly', () {
      final params1 = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        includeParentName: true,
        includeParentEmail: true,
        format: 'PDF',
        schoolName: 'Dummy School',
      );

      final params2 = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        schoolName: 'Dummy School',
        includeParentName: true,
        includeParentEmail: true,
        format: 'PDF',
      );

      expect(params1, params2);
    });
    test('inequality works correctly for different parent flags', () {
      final params1 = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        includeParentName: true,
        schoolName: 'Dummy School',
        includeParentEmail: true,
        format: 'PDF',
      );

      final params2 = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        includeParentName: false,
        schoolName: 'Dummy School',
        includeParentEmail: true,
        format: 'PDF',
      );

      expect(params1, isNot(params2));
    });
  });
}
