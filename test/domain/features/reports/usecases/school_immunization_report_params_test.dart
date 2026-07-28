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

    test('toRequestBody includes vaccine codes and statuses as arrays', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: const ['DTaP', 'Polio'],
        statusFilters: const ['ACTIVE', 'UPCOMING'],
        includeParentName: true,
        schoolName: 'Dummy School',
        includeParentEmail: false,
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['reportType'], 'IMMUNIZATION');
      expect(body['vaccineCodes'], const ['DTaP', 'Polio']);
      expect(body['statusFilter'], const ['ACTIVE', 'UPCOMING']);
    });

    test('toRequestBody includes parent info flags', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        includeParentName: true,
        schoolName: 'Dummy School',
        includeParentEmail: false,
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['includeParentName'], true);
      expect(body['includeParentEmail'], false);
    });

    test('toRequestBody excludes empty arrays', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        includeParentName: true,
        includeParentEmail: true,
        schoolName: 'Dummy School',
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body.containsKey('roomCodes'), false);
      expect(body.containsKey('tagCodes'), false);
    });

    test('toRequestBody includes non-empty arrays', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: statusFilters,
        schoolName: 'Dummy School',
        includeParentName: true,
        includeParentEmail: true,
        classroomCodes: classrooms,
        tagCodes: tags,
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['roomCodes'], classrooms);
      expect(body['tagCodes'], tags);
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

    test('includes format field in payload', () {
      final params = SchoolImmunizationReportParams(
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

      final body = params.toRequestBody();

      expect(body['format'], 'PDF');
    });

    test('handles multiple status filters', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        schoolName: 'Dummy School',
        vaccineCodes: vaccineCodes,
        statusFilters: const ['ACTIVE', 'UPCOMING', 'INACTIVE'],
        includeParentName: true,
        includeParentEmail: true,
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['statusFilter'].length, 3);
      expect(body['statusFilter'], contains('INACTIVE'));
    });

    test('correctly handles ACTIVE status filter', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: const ['ACTIVE'],
        includeParentName: true,
        includeParentEmail: true,
        schoolName: 'Dummy School',
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['statusFilter'], ['ACTIVE']);
    });

    test('correctly handles UPCOMING status filter', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: const ['UPCOMING'],
        includeParentName: true,
        schoolName: 'Dummy School',
        includeParentEmail: true,
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['statusFilter'], ['UPCOMING']);
    });

    test('correctly handles INACTIVE status filter', () {
      final params = SchoolImmunizationReportParams(
        reportType: ReportType.immunization,
        startDate: startDate,
        endDate: endDate,
        vaccineCodes: vaccineCodes,
        statusFilters: const ['INACTIVE'],
        includeParentName: true,
        includeParentEmail: true,
        schoolName: 'Dummy School',
        format: 'PDF',
      );

      final body = params.toRequestBody();

      expect(body['statusFilter'], ['INACTIVE']);
    });
  });
}
