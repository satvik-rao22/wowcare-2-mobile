import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_health_update_request.dart';

void main() {
  group('StudentHealthUpdateRequest.toPayload', () {
    test('produces exactly the Map the views used to build', () {
      const request = StudentHealthUpdateRequest(
        allergy: 'peanuts',
        medications: 'none',
        dietRestrictions: 'vegetarian',
        photoPermission: true,
      );

      expect(request.toPayload(), {
        'allergy': 'peanuts',
        'medications': 'none',
        'dietRestrictions': 'vegetarian',
        'photoPermission': true,
      });
    });

    test('reproduces field values verbatim (no trimming/coercion added)', () {
      const request = StudentHealthUpdateRequest(
        allergy: '  spaces kept  ',
        medications: '',
        dietRestrictions: '',
        photoPermission: false,
      );

      final payload = request.toPayload();
      expect(payload['allergy'], '  spaces kept  ');
      expect(payload['medications'], '');
      expect(payload['dietRestrictions'], '');
      expect(payload['photoPermission'], false);
    });

    test('payload has exactly the four expected keys in order', () {
      const request = StudentHealthUpdateRequest(
        allergy: 'a',
        medications: 'm',
        dietRestrictions: 'd',
        photoPermission: true,
      );

      expect(request.toPayload().keys.toList(), [
        'allergy',
        'medications',
        'dietRestrictions',
        'photoPermission',
      ]);
    });
  });

  group('equality', () {
    test('value-equal instances are equal (Equatable props)', () {
      const a = StudentHealthUpdateRequest(
        allergy: 'a',
        medications: 'm',
        dietRestrictions: 'd',
        photoPermission: true,
      );
      const b = StudentHealthUpdateRequest(
        allergy: 'a',
        medications: 'm',
        dietRestrictions: 'd',
        photoPermission: true,
      );

      expect(a, b);
    });

    test('differing photoPermission makes instances unequal', () {
      const a = StudentHealthUpdateRequest(
        allergy: 'a',
        medications: 'm',
        dietRestrictions: 'd',
        photoPermission: true,
      );
      const b = StudentHealthUpdateRequest(
        allergy: 'a',
        medications: 'm',
        dietRestrictions: 'd',
        photoPermission: false,
      );

      expect(a == b, isFalse);
    });
  });
}
