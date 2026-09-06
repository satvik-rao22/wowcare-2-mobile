import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/attendance/models/qr_validation_model.dart';

void main() {
  group('QrValidationRequestModel.toJson', () {
    test('includes qrToken and useCase', () {
      const model = QrValidationRequestModel(
        qrToken: 'TOKEN123',
        useCase: 'SIGN_IN',
      );
      expect(model.toJson(), {'qrToken': 'TOKEN123', 'useCase': 'SIGN_IN'});
    });
  });

  group('QrValidationResponseModel.fromJson', () {
    test('parses a fully-populated envelope', () {
      final model = QrValidationResponseModel.fromJson({
        'data': {
          'valid': true,
          'schoolCode': 'SCH_1',
          'reason': 'ok',
          'validTo': '2026-01-01T00:00:00.000Z',
        },
      });
      expect(model.valid, true);
      expect(model.schoolCode, 'SCH_1');
      expect(model.reason, 'ok');
      expect(model.validTo, DateTime.parse('2026-01-01T00:00:00.000Z'));
    });

    test('defaults valid to false and schoolCode to empty when missing', () {
      final model = QrValidationResponseModel.fromJson({
        'data': <String, dynamic>{},
      });
      expect(model.valid, false);
      expect(model.schoolCode, '');
      expect(model.reason, isNull);
      expect(model.validTo, isNull);
    });

    test('missing data envelope entirely still parses to defaults', () {
      final model = QrValidationResponseModel.fromJson({});
      expect(model.valid, false);
      expect(model.schoolCode, '');
    });

    test('an unparseable validTo string becomes null, not a thrown error', () {
      final model = QrValidationResponseModel.fromJson({
        'data': {'valid': true, 'schoolCode': 'SCH_1', 'validTo': 'not-a-date'},
      });
      expect(model.validTo, isNull);
    });
  });

  group('QrValidationResponseModel.toEntity', () {
    test('maps every field across unchanged', () {
      final model = QrValidationResponseModel.fromJson({
        'data': {
          'valid': true,
          'schoolCode': 'SCH_1',
          'reason': 'ok',
          'validTo': '2026-01-01T00:00:00.000Z',
        },
      });
      final entity = model.toEntity();
      expect(entity.valid, model.valid);
      expect(entity.schoolCode, model.schoolCode);
      expect(entity.reason, model.reason);
      expect(entity.validTo, model.validTo);
    });
  });
}
