import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/mappers/report_entity_mapper.dart';
import 'package:wowcare/data/features/reports/models/report_response_model.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';

/// Characterisation tests for [ReportResponseModel] (§8).
///
/// This parser does three things a plain field-mapper does not, and all three
/// are pinned here so the `@JsonSerializable` migration cannot quietly drop
/// one:
///   1. unwraps the `{success, message, data: {...}}` envelope, falling back
///      to the top-level object when there is no `data`;
///   2. throws on `success: false` rather than returning a half-built model;
///   3. rejects missing/empty `reportId`, `reportType` and `generatedAt`
///      instead of defaulting them to `''` (a report with no id can never be
///      downloaded).
void main() {
  group('ReportResponseModel.fromJson — envelope', () {
    test('reads the fields out of a `data` envelope', () {
      final model = ReportResponseModel.fromJson(const {
        'success': true,
        'message': 'Report generated',
        'data': {
          'reportId': 'rpt-1',
          'reportType': 'STUDENT_DAILY_ATTENDANCE',
          'generatedAt': '2026-01-02T03:04:05Z',
          'assetCode': 'asset-1',
          'fileName': 'daily.xlsx',
        },
      });

      expect(model.reportId, 'rpt-1');
      expect(model.reportType, 'STUDENT_DAILY_ATTENDANCE');
      expect(model.generatedAt, '2026-01-02T03:04:05Z');
      expect(model.assetCode, 'asset-1');
      expect(model.fileName, 'daily.xlsx');
      expect(model.message, 'Report generated');
    });

    test('falls back to the top-level object when `data` is absent', () {
      final model = ReportResponseModel.fromJson(const {
        'reportId': 'rpt-2',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
        'assetCode': 'asset-2',
      });

      expect(model.reportId, 'rpt-2');
      expect(model.assetCode, 'asset-2');
      expect(model.message, isNull);
    });

    test('`message` always comes from the envelope, never from `data`', () {
      final model = ReportResponseModel.fromJson(const {
        'message': 'outer',
        'data': {
          'reportId': 'rpt-3',
          'reportType': 'STUDENT_ABSENT',
          'generatedAt': '2026-01-02T00:00:00Z',
          'message': 'inner',
        },
      });

      expect(model.message, 'outer');
    });

    test('an explicit null `data` falls back to the top level', () {
      final model = ReportResponseModel.fromJson(const {
        'data': null,
        'reportId': 'rpt-4',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
      });

      expect(model.reportId, 'rpt-4');
    });
  });

  group('ReportResponseModel.fromJson — failure envelope', () {
    test('throws when success is false, quoting `message`', () {
      expect(
        () => ReportResponseModel.fromJson(const {
          'success': false,
          'message': 'Quota exceeded',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Quota exceeded'),
          ),
        ),
      );
    });

    test('falls back to `error` when there is no `message`', () {
      expect(
        () => ReportResponseModel.fromJson(const {
          'success': false,
          'error': 'E_BACKEND',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('E_BACKEND'),
          ),
        ),
      );
    });

    test('says "unknown error" when neither is present', () {
      expect(
        () => ReportResponseModel.fromJson(const {'success': false}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('unknown error'),
          ),
        ),
      );
    });

    test(
      'a non-String `message` on the failure path is interpolated, not cast',
      () {
        // The failure branch reads `json['message']` untyped, so a malformed
        // message still produces a FormatException rather than a TypeError.
        expect(
          () => ReportResponseModel.fromJson(const {
            'success': false,
            'message': 42,
          }),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('42'),
            ),
          ),
        );
      },
    );

    test('a non-String `message` on the success path throws TypeError', () {
      expect(
        () => ReportResponseModel.fromJson(const {
          'message': 42,
          'reportId': 'rpt-6',
          'reportType': 'STUDENT_ABSENT',
          'generatedAt': '2026-01-02T00:00:00Z',
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('a non-bool `success` is not treated as failure', () {
      // Only `success is bool && !success` short-circuits; a string "false"
      // falls through to normal parsing.
      final model = ReportResponseModel.fromJson(const {
        'success': 'false',
        'reportId': 'rpt-5',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
      });

      expect(model.reportId, 'rpt-5');
    });
  });

  group('ReportResponseModel.fromJson — required-field validation', () {
    Map<String, dynamic> valid() => <String, dynamic>{
      'reportId': 'rpt-1',
      'reportType': 'STUDENT_ABSENT',
      'generatedAt': '2026-01-02T00:00:00Z',
    };

    for (final field in ['reportId', 'reportType', 'generatedAt']) {
      test('throws when $field is missing', () {
        expect(
          () => ReportResponseModel.fromJson(valid()..remove(field)),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('missing required field "$field"'),
            ),
          ),
        );
      });

      test('throws when $field is null', () {
        expect(
          () => ReportResponseModel.fromJson(valid()..[field] = null),
          throwsFormatException,
        );
      });

      test('throws when $field is the empty string', () {
        expect(
          () => ReportResponseModel.fromJson(valid()..[field] = ''),
          throwsFormatException,
        );
      });
    }

    test('all three required fields are cast before any is validated', () {
      // Order matters on malformed input: `reportType` is cast to String
      // before the null `reportId` is checked, so the TypeError wins over
      // the FormatException. Pinned so the generated parser cannot reorder it.
      expect(
        () => ReportResponseModel.fromJson(
          valid()
            ..['reportId'] = null
            ..['reportType'] = 42,
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test(
      'a non-String required field throws TypeError, not FormatException',
      () {
        expect(
          () => ReportResponseModel.fromJson(valid()..['reportId'] = 42),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('optional fields stay null when absent', () {
      final model = ReportResponseModel.fromJson(valid());
      expect(model.assetCode, isNull);
      expect(model.fileName, isNull);
      expect(model.message, isNull);
    });

    test('unknown keys are ignored', () {
      final model = ReportResponseModel.fromJson(
        valid()..['somethingTheBackendAddedLater'] = 'ignored',
      );
      expect(model.reportId, 'rpt-1');
    });
  });

  group('ReportResponseModel.toJson', () {
    test('emits every key when nothing is null', () {
      const model = ReportResponseModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_ABSENT',
        generatedAt: '2026-01-02T00:00:00Z',
        assetCode: 'asset-1',
        fileName: 'absent.xlsx',
        message: 'ok',
      );

      expect(model.toJson(), {
        'reportId': 'rpt-1',
        'reportType': 'STUDENT_ABSENT',
        'generatedAt': '2026-01-02T00:00:00Z',
        'assetCode': 'asset-1',
        'fileName': 'absent.xlsx',
        'message': 'ok',
      });
    });

    test('omits null optional keys entirely', () {
      const model = ReportResponseModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_ABSENT',
        generatedAt: '2026-01-02T00:00:00Z',
      );

      final json = model.toJson();
      expect(json.containsKey('assetCode'), isFalse);
      expect(json.containsKey('fileName'), isFalse);
      expect(json.containsKey('message'), isFalse);
      expect(json.length, 3);
    });

    test('round-trips through fromJson unchanged', () {
      const original = ReportResponseModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_ABSENT',
        generatedAt: '2026-01-02T00:00:00Z',
        assetCode: 'asset-1',
        fileName: 'absent.xlsx',
        message: 'ok',
      );

      expect(ReportResponseModel.fromJson(original.toJson()), original);
    });
  });

  group('ReportResponseModel.toEntity', () {
    test('maps the backend value onto the ReportType enum', () {
      const model = ReportResponseModel(
        reportId: 'rpt-1',
        reportType: 'STUDENT_DAILY_ATTENDANCE',
        generatedAt: '2026-01-02T03:04:05Z',
        assetCode: 'asset-1',
        fileName: 'daily.xlsx',
        message: 'ignored by the entity',
      );

      final entity = model.toEntity();
      expect(entity.reportId, 'rpt-1');
      expect(entity.reportType, ReportType.studentDailyAttendance);
      expect(entity.generatedAt, DateTime.parse('2026-01-02T03:04:05Z'));
      expect(entity.assetCode, 'asset-1');
      expect(entity.fileName, 'daily.xlsx');
    });

    test('throws FormatException on an unknown reportType', () {
      const model = ReportResponseModel(
        reportId: 'rpt-1',
        reportType: 'NOT_A_REPORT',
        generatedAt: '2026-01-02T00:00:00Z',
      );

      expect(model.toEntity, throwsFormatException);
    });
  });
}
