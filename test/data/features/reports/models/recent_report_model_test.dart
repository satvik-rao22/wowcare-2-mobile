import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/mappers/report_entity_mapper.dart';
import 'package:wowcare/data/features/reports/models/recent_report_model.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';

/// Characterisation tests for [RecentReportModel] (§8).
///
/// These pin the *exact* behaviour of the hand-written parser — including
/// nulls, missing keys and wrong types — so the move to `@JsonSerializable`
/// can be proven byte-for-byte equivalent rather than merely "looks right".
///
/// Every expectation here was written against the hand-written parser and
/// must keep passing unchanged after generation.
void main() {
  group('RecentReportModel.fromJson', () {
    test('reads every field from a complete payload', () {
      final model = RecentReportModel.fromJson(const {
        'reportId': 'rpt-1',
        'reportType': 'STUDENT_DAILY_ATTENDANCE',
        'generatedAt': '2026-01-02T03:04:05Z',
        'assetCode': 'asset-1',
        'fileName': 'daily.xlsx',
      });

      expect(model.reportId, 'rpt-1');
      expect(model.reportType, 'STUDENT_DAILY_ATTENDANCE');
      expect(model.generatedAt, '2026-01-02T03:04:05Z');
      expect(model.assetCode, 'asset-1');
      expect(model.fileName, 'daily.xlsx');
    });

    test('missing required keys default to the empty string, never null', () {
      final model = RecentReportModel.fromJson(const <String, dynamic>{});

      expect(model.reportId, '');
      expect(model.reportType, '');
      expect(model.generatedAt, '');
      expect(model.assetCode, isNull);
      expect(model.fileName, isNull);
    });

    test(
      'explicit nulls on required keys also default to the empty string',
      () {
        final model = RecentReportModel.fromJson(const {
          'reportId': null,
          'reportType': null,
          'generatedAt': null,
          'assetCode': null,
          'fileName': null,
        });

        expect(model.reportId, '');
        expect(model.reportType, '');
        expect(model.generatedAt, '');
        expect(model.assetCode, isNull);
        expect(model.fileName, isNull);
      },
    );

    test('optional keys stay null when absent', () {
      final model = RecentReportModel.fromJson(const {
        'reportId': 'rpt-2',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
      });

      expect(model.assetCode, isNull);
      expect(model.fileName, isNull);
    });

    test('a non-String value on a required key throws TypeError', () {
      // `as String?` on an int is a cast failure, not a silent default.
      expect(
        () => RecentReportModel.fromJson(const {'reportId': 42}),
        throwsA(isA<TypeError>()),
      );
    });

    test('a non-String value on an optional key throws TypeError', () {
      expect(
        () => RecentReportModel.fromJson(const {
          'reportId': 'rpt-3',
          'reportType': 'STUDENT_ABSENT',
          'generatedAt': '2026-01-02T00:00:00Z',
          'assetCode': 7,
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('unknown keys are ignored', () {
      final model = RecentReportModel.fromJson(const {
        'reportId': 'rpt-4',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
        'somethingTheBackendAddedLater': 'ignored',
      });

      expect(model.reportId, 'rpt-4');
    });
  });

  group('RecentReportModel.toJson', () {
    test('emits all six keys when nothing is null', () {
      const model = RecentReportModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_ABSENT',
        generatedAt: '2026-01-02T00:00:00Z',
        assetCode: 'asset-1',
        fileName: 'absent.xlsx',
      );

      expect(model.toJson(), {
        'reportId': 'rpt-1',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
        'assetCode': 'asset-1',
        'fileName': 'absent.xlsx',
      });
    });

    test('omits null optional keys entirely — it does not emit null', () {
      const model = RecentReportModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_ABSENT',
        generatedAt: '2026-01-02T00:00:00Z',
      );

      final json = model.toJson();
      expect(json.containsKey('assetCode'), isFalse);
      expect(json.containsKey('fileName'), isFalse);
      expect(json, {
        'reportId': 'rpt-1',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
      });
    });

    test('round-trips through fromJson unchanged', () {
      const original = RecentReportModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_ABSENT',
        generatedAt: '2026-01-02T00:00:00Z',
        assetCode: 'asset-1',
        fileName: 'absent.xlsx',
      );

      expect(RecentReportModel.fromJson(original.toJson()), original);
    });
  });

  group('RecentReportModel.toEntity', () {
    test('maps the backend value onto the ReportType enum', () {
      const model = RecentReportModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_DAILY_ATTENDANCE',
        generatedAt: '2026-01-02T03:04:05Z',
        assetCode: 'asset-1',
        fileName: 'daily.xlsx',
      );

      final entity = model.toEntity();
      expect(entity.reportId, 'rpt-1');
      expect(entity.reportType, ReportType.studentDailyAttendance);
      expect(entity.generatedAt, DateTime.parse('2026-01-02T03:04:05Z'));
      expect(entity.assetCode, 'asset-1');
      expect(entity.fileName, 'daily.xlsx');
    });

    test('throws FormatException on an unknown reportType', () {
      const model = RecentReportModel(
        reportId: 'rpt-1',
        reportType: 'NOT_A_REPORT',
        generatedAt: '2026-01-02T00:00:00Z',
      );

      expect(model.toEntity, throwsFormatException);
    });

    test(
      'an unparseable generatedAt falls back to now rather than throwing',
      () {
        const model = RecentReportModel(
          reportId: 'rpt-1',
          reportType: 'STUDENT_ABSENT',
          generatedAt: 'not-a-date',
        );

        final before = DateTime.now().toUtc();
        final entity = model.toEntity();
        final after = DateTime.now().toUtc();

        expect(
          entity.generatedAt.isBefore(
            before.subtract(const Duration(seconds: 1)),
          ),
          isFalse,
        );
        expect(
          entity.generatedAt.isAfter(after.add(const Duration(seconds: 1))),
          isFalse,
        );
      },
    );
  });
}
