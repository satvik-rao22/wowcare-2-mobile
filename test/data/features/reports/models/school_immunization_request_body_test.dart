import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';

void main() {
  /// Payload assertions for SchoolImmunizationRequestBody, moved here with the wire-building logic
  /// when the domain params classes lost `toRequestBody()` (§8).
  group('SchoolImmunizationRequestBody', () {
    final startDate = DateTime(2026, 6, 1);
    final endDate = DateTime(2026, 6, 30);
    const vaccineCodes = ['DTaP', 'Polio', 'MMR'];
    const statusFilters = ['ACTIVE'];
    const classrooms = ['ROOM1', 'ROOM2'];
    const tags = ['TAG1', 'TAG2'];

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

      expect(body['roomCodes'], classrooms);
      expect(body['tagCodes'], tags);
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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

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

      final body = ReportRequestPayload.fromParams(params).toJson();

      expect(body['statusFilter'], ['INACTIVE']);
    });
  });
}
