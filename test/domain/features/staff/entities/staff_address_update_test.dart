import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/staff_address_update.dart';

void main() {
  group('StaffAddressUpdate.toPayload', () {
    test('produces exactly the Map the edit-profile view used to build', () {
      const request = StaffAddressUpdate(
        addressStreet: '12 Main St',
        addressLine2: 'Apt 4',
        addressCity: 'Nashua',
        addressState: 'NH',
        addressZipCode: '03060',
        addressCountry: 'US',
      );

      expect(request.toPayload(), {
        'addressStreet': '12 Main St',
        'addressLine2': 'Apt 4',
        'addressCity': 'Nashua',
        'addressState': 'NH',
        'addressZipCode': '03060',
        'addressCountry': 'US',
      });
    });

    test('carries already-transformed values verbatim (no coercion added)', () {
      const request = StaffAddressUpdate(
        addressStreet: '  kept  ',
        addressLine2: '',
        addressCity: '',
        addressState: '',
        addressZipCode: '',
        addressCountry: '',
      );

      final payload = request.toPayload();
      expect(payload['addressStreet'], '  kept  ');
      expect(payload['addressLine2'], '');
      expect(payload['addressCountry'], '');
    });

    test('payload has exactly the six expected keys in order', () {
      const request = StaffAddressUpdate(
        addressStreet: 's',
        addressLine2: 'l',
        addressCity: 'c',
        addressState: 'st',
        addressZipCode: 'z',
        addressCountry: 'co',
      );

      expect(request.toPayload().keys.toList(), [
        'addressStreet',
        'addressLine2',
        'addressCity',
        'addressState',
        'addressZipCode',
        'addressCountry',
      ]);
    });
  });

  group('equality', () {
    test('value-equal instances are equal (Equatable props)', () {
      const a = StaffAddressUpdate(
        addressStreet: 's',
        addressLine2: 'l',
        addressCity: 'c',
        addressState: 'st',
        addressZipCode: 'z',
        addressCountry: 'co',
      );
      const b = StaffAddressUpdate(
        addressStreet: 's',
        addressLine2: 'l',
        addressCity: 'c',
        addressState: 'st',
        addressZipCode: 'z',
        addressCountry: 'co',
      );

      expect(a, b);
    });
  });
}
