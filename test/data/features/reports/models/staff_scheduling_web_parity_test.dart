import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_scheduling_report_params.dart';

/// The exact body the **web** app sends to
/// `POST /api/v1/staff/staff-shifts/reports/generate`, captured from a request
/// that generated successfully. Mobile was sending everything here except
/// `schoolTimeZone`, and the report failed to generate without it.
///
/// Keep this string verbatim — it is the contract, not a fixture to tidy.
const String _webRequestBody = '''
{"reportType":"STAFF_SCHEDULING","schoolCode":"SCH_3B334F28-7","organizationCode":"ORG_3C6B698F-2","generatedBy":"USR-238e66ae","schoolName":"New horizon","startDate":"2026-09-06","endDate":"2026-09-12","classroomCodes":["CLS_8E01F0CF-4","CLS_B4C22E33-C","CLS_BBD234B0-F","CLS_FB2B93F6-5","CLS_0CB5182A-0","CLS_668E6E7F-D","CLS_CBE1AE6C-0"],"format":"XLSX","schoolTimeZone":"America/New_York"}
''';

void main() {
  final web = jsonDecode(_webRequestBody) as Map<String, dynamic>;

  final params = StaffSchedulingReportParams(
    reportType: ReportType.staffScheduling,
    startDate: DateTime(2026, 9, 6),
    endDate: DateTime(2026, 9, 12),
    format: 'XLSX',
    schoolName: 'New horizon',
    classroomCodes: const [
      'CLS_8E01F0CF-4',
      'CLS_B4C22E33-C',
      'CLS_BBD234B0-F',
      'CLS_FB2B93F6-5',
      'CLS_0CB5182A-0',
      'CLS_668E6E7F-D',
      'CLS_CBE1AE6C-0',
    ],
  );

  const context = ReportRequestContext(
    schoolCode: 'SCH_3B334F28-7',
    organizationCode: 'ORG_3C6B698F-2',
    generatedBy: 'USR-238e66ae',
    schoolName: 'New horizon',
    schoolTimeZone: 'America/New_York',
  );

  test('sends exactly the keys the web app sends — no more, no fewer', () {
    final actual = ReportRequestPayload.fromParams(
      params,
      context: context,
    ).toJson();

    expect(actual.keys.toSet(), web.keys.toSet());
  });

  test('every value matches the web request', () {
    final actual = ReportRequestPayload.fromParams(
      params,
      context: context,
    ).toJson();

    for (final key in web.keys) {
      expect(actual[key], web[key], reason: 'mismatch on "$key"');
    }
  });

  test('schoolTimeZone is carried through from the request context', () {
    // The regression this file exists for: the field did not exist on the
    // body at all, so the key could never appear however the context was set.
    final actual = ReportRequestPayload.fromParams(
      params,
      context: context,
    ).toJson();

    expect(actual['schoolTimeZone'], 'America/New_York');
  });

  test('an unresolved timezone omits the key rather than sending UTC', () {
    // The repository passes null when it cannot resolve the school's zone.
    // Asserting UTC for a school in New York would move shifts across day
    // boundaries, so the key is left out instead.
    final actual = ReportRequestPayload.fromParams(
      params,
      context: const ReportRequestContext(
        schoolCode: 'SCH_3B334F28-7',
        organizationCode: 'ORG_3C6B698F-2',
        generatedBy: 'USR-238e66ae',
        schoolName: 'New horizon',
      ),
    ).toJson();

    expect(actual.containsKey('schoolTimeZone'), isFalse);
  });

  test('a blank timezone is treated as unresolved, not sent as ""', () {
    final actual = ReportRequestPayload.fromParams(
      params,
      context: const ReportRequestContext(
        schoolCode: 'SCH_3B334F28-7',
        schoolName: 'New horizon',
        schoolTimeZone: '   ',
      ),
    ).toJson();

    expect(actual.containsKey('schoolTimeZone'), isFalse);
  });
}
