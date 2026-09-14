import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';

/// Fidelity test: [ActivityAttachment.toPayload] must reproduce the exact Map
/// shapes the photo/incident Views used to build by hand, byte-for-byte, so the
/// outbound CREATE / SHARED-create JSON on the wire stays identical.
void main() {
  group('ActivityAttachment.toPayload', () {
    test('SHARED shape: only assetCode key present', () {
      const attachment = ActivityAttachment(assetCode: 'ASSET-1');

      final payload = attachment.toPayload();

      expect(payload, {'assetCode': 'ASSET-1'});
      expect(payload.containsKey('studentCode'), isFalse);
      expect(payload.containsKey('bindingMode'), isFalse);
      expect(payload.keys.toList(), ['assetCode']);
    });

    test('PER_STUDENT shape: all three keys present', () {
      const attachment = ActivityAttachment(
        assetCode: 'ASSET-2',
        studentCode: 'STU-9',
        bindingMode: 'PER_STUDENT',
      );

      final payload = attachment.toPayload();

      expect(payload, {
        'assetCode': 'ASSET-2',
        'studentCode': 'STU-9',
        'bindingMode': 'PER_STUDENT',
      });
      expect(payload.keys.toList(), ['assetCode', 'studentCode', 'bindingMode']);
    });

    test('empty studentCode/bindingMode are omitted (collapse to SHARED shape)',
        () {
      const attachment = ActivityAttachment(
        assetCode: 'ASSET-3',
        studentCode: '',
        bindingMode: '',
      );

      final payload = attachment.toPayload();

      expect(payload, {'assetCode': 'ASSET-3'});
      expect(payload.containsKey('studentCode'), isFalse);
      expect(payload.containsKey('bindingMode'), isFalse);
    });

    test('null studentCode/bindingMode are omitted', () {
      const attachment = ActivityAttachment(assetCode: 'ASSET-4');

      final payload = attachment.toPayload();

      expect(payload, {'assetCode': 'ASSET-4'});
    });

    test('value equality via Equatable props', () {
      const a = ActivityAttachment(
        assetCode: 'X',
        studentCode: 'S',
        bindingMode: 'PER_STUDENT',
      );
      const b = ActivityAttachment(
        assetCode: 'X',
        studentCode: 'S',
        bindingMode: 'PER_STUDENT',
      );
      const c = ActivityAttachment(assetCode: 'X');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
