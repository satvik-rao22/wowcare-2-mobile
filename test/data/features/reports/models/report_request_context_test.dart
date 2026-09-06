import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_scheduling_report_params.dart';

/// The school/user identity used to be written onto the payload map inside
/// `ReportsRepositoryImpl.generateReport` after `toRequestBody()` had run.
/// It is now a typed input to the payload, so these tests pin the three
/// behaviours that mutation had.
void main() {
  final start = DateTime.utc(2026, 1, 2);
  final end = DateTime.utc(2026, 2, 3);

  ReportRequestParams generic({String? schoolName}) => ReportRequestParams(
    reportType: ReportType.studentAbsent,
    startDate: start,
    endDate: end,
    schoolName: schoolName,
  );

  group('school context is stamped onto the payload', () {
    test('schoolCode, organizationCode and generatedBy are emitted', () {
      final json = ReportRequestPayload.fromParams(
        generic(schoolName: 'Sunny School'),
        context: const ReportRequestContext(
          schoolCode: 'SCH_1',
          organizationCode: 'ORG_1',
          generatedBy: 'USR_1',
        ),
      ).toJson();

      expect(json['schoolCode'], 'SCH_1');
      expect(json['organizationCode'], 'ORG_1');
      expect(json['generatedBy'], 'USR_1');
    });

    test('empty identity values are still sent, as they always were', () {
      // Storage misses resolved to '' before, and the repository wrote those
      // empty strings onto the body rather than omitting the keys.
      final json = ReportRequestPayload.fromParams(
        generic(schoolName: 'Sunny School'),
        context: const ReportRequestContext(
          schoolCode: '',
          organizationCode: '',
          generatedBy: '',
        ),
      ).toJson();

      expect(json['schoolCode'], '');
      expect(json['organizationCode'], '');
      expect(json['generatedBy'], '');
    });

    test('no context means no identity keys at all', () {
      final json = ReportRequestPayload.fromParams(
        generic(schoolName: 'Sunny School'),
      ).toJson();

      expect(json.containsKey('schoolCode'), isFalse);
      expect(json.containsKey('organizationCode'), isFalse);
      expect(json.containsKey('generatedBy'), isFalse);
    });
  });

  group('resolved school name', () {
    test('overrides the name the form supplied', () {
      final json = ReportRequestPayload.fromParams(
        generic(schoolName: 'From Form'),
        context: const ReportRequestContext(schoolName: 'Resolved Name'),
      ).toJson();

      expect(json['schoolName'], 'Resolved Name');
    });

    test('fills in when the form had none', () {
      final json = ReportRequestPayload.fromParams(
        generic(),
        context: const ReportRequestContext(schoolName: 'Resolved Name'),
      ).toJson();

      expect(json['schoolName'], 'Resolved Name');
    });

    test('an empty resolved name leaves the form value alone', () {
      final json = ReportRequestPayload.fromParams(
        generic(schoolName: 'From Form'),
        context: const ReportRequestContext(schoolName: ''),
      ).toJson();

      expect(json['schoolName'], 'From Form');
    });

    test('a null resolved name leaves the form value alone', () {
      final json = ReportRequestPayload.fromParams(
        generic(schoolName: 'From Form'),
        context: const ReportRequestContext.none(),
      ).toJson();

      expect(json['schoolName'], 'From Form');
    });

    test('a blank form name with no resolved name omits the key', () {
      final json = ReportRequestPayload.fromParams(
        generic(schoolName: '   '),
        context: const ReportRequestContext.none(),
      ).toJson();

      expect(json.containsKey('schoolName'), isFalse);
    });

    test('the override applies to the other payload shapes too', () {
      final json = ReportRequestPayload.fromParams(
        StaffSchedulingReportParams(
          reportType: ReportType.staffScheduling,
          startDate: start,
          endDate: end,
          format: 'PDF',
          schoolName: 'From Form',
        ),
        context: const ReportRequestContext(
          schoolCode: 'SCH_1',
          schoolName: 'Resolved Name',
        ),
      ).toJson();

      expect(json['schoolName'], 'Resolved Name');
      expect(json['schoolCode'], 'SCH_1');
    });
  });

  test('an unsupported params type is rejected loudly', () {
    expect(
      () => ReportRequestPayload.fromParams(_UnknownParams()),
      throwsArgumentError,
    );
  });
}

/// A params class with no payload of its own — the case the dispatch's
/// fallback arm exists to catch if someone adds a report and forgets the
/// request model.
class _UnknownParams extends ReportParams {
  @override
  ReportType get reportType => ReportType.studentAbsent;

  @override
  DateTime? get startDate => DateTime.utc(2026);

  @override
  String get format => 'PDF';

  @override
  String toCacheIdentifier() => 'unknown';

  @override
  List<Object?> get props => const [];
}
