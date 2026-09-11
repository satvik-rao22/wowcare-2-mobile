import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';

void main() {
  group('ActivityParameterValue.toPayload', () {
    test('value entry keeps parameterCode + value, omits selectedOptionCode',
        () {
      const p = ActivityParameterValue(
        parameterCode: 'PARAM_DATE',
        value: '2026-08-27',
      );
      expect(p.toPayload(), <String, dynamic>{
        'parameterCode': 'PARAM_DATE',
        'value': '2026-08-27',
      });
    });

    test('selectedOptionCode entry omits value key', () {
      const p = ActivityParameterValue(
        parameterCode: 'PARAM_MEAL',
        selectedOptionCode: 'OPT_LUNCH',
      );
      expect(p.toPayload(), <String, dynamic>{
        'parameterCode': 'PARAM_MEAL',
        'selectedOptionCode': 'OPT_LUNCH',
      });
    });

    test('empty-string value stays present (key not dropped)', () {
      const p = ActivityParameterValue(
        parameterCode: 'PARAM_SIGN',
        value: '',
      );
      final payload = p.toPayload();
      expect(payload.containsKey('value'), isTrue);
      expect(payload, <String, dynamic>{
        'parameterCode': 'PARAM_SIGN',
        'value': '',
      });
    });

    test('parameterCode-only entry omits value (value == null)', () {
      const p = ActivityParameterValue(parameterCode: 'PARAM_ONLY');
      final payload = p.toPayload();
      expect(payload.containsKey('value'), isFalse);
      expect(payload.containsKey('selectedOptionCode'), isFalse);
      expect(payload, <String, dynamic>{'parameterCode': 'PARAM_ONLY'});
    });

    test('empty selectedOptionCode is omitted', () {
      const p = ActivityParameterValue(
        parameterCode: 'PARAM_X',
        selectedOptionCode: '',
      );
      final payload = p.toPayload();
      expect(payload.containsKey('selectedOptionCode'), isFalse);
      expect(payload, <String, dynamic>{'parameterCode': 'PARAM_X'});
    });

    test('non-string value types are preserved verbatim', () {
      const boolEntry = ActivityParameterValue(
        parameterCode: 'PARAM_NAP',
        value: true,
      );
      expect(boolEntry.toPayload()['value'], isTrue);
    });

    test('extra keys (e.g. mediaType) are carried through verbatim', () {
      const p = ActivityParameterValue(
        parameterCode: 'PARAM_MEDIA',
        value: 'asset1,asset2',
        extra: {'mediaType': 'VIDEO'},
      );
      expect(p.toPayload(), <String, dynamic>{
        'parameterCode': 'PARAM_MEDIA',
        'value': 'asset1,asset2',
        'mediaType': 'VIDEO',
      });
    });

    test('Equatable value equality holds', () {
      const a = ActivityParameterValue(parameterCode: 'C', value: 1);
      const b = ActivityParameterValue(parameterCode: 'C', value: 1);
      expect(a, equals(b));
    });
  });
}
