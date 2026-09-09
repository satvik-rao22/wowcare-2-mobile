import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_health_update_request.dart';

void main() {
  // Note: `StudentHealthUpdateRequest.toPayload` was moved to the data-layer
  // mapper `studentHealthUpdateRequestToPayload` in Step 4; its serialization is
  // covered by
  // test/data/features/student/mappers/student_health_update_request_mapper_test.dart.
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
