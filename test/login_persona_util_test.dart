import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/util/login_persona_util.dart';

void main() {
  group('shouldSkipStaffCodeResolutionForContext', () {
    test('returns true for KIOSK role to prevent staff lookup', () {
      final rolesJson = jsonEncode([
        {
          'role': 'KIOSK',
          'organizationCode': 'ORG_001',
          'schoolCode': 'SCH_123',
        }
      ]);

      final result = shouldSkipStaffCodeResolutionForContext(
        rolesJson: rolesJson,
        organizationCode: 'ORG_001',
        schoolCode: 'SCH_123',
      );

      expect(result, isTrue, reason: 'KIOSK users should skip staff code resolution');
    });

    test('returns true for GUARDIAN role to prevent staff lookup', () {
      final rolesJson = jsonEncode([
        {
          'role': 'GUARDIAN',
          'organizationCode': 'ORG_001',
          'schoolCode': 'SCH_123',
        }
      ]);

      final result = shouldSkipStaffCodeResolutionForContext(
        rolesJson: rolesJson,
        organizationCode: 'ORG_001',
        schoolCode: 'SCH_123',
      );

      expect(result, isTrue, reason: 'GUARDIAN users should skip staff code resolution');
    });

    test('returns false for STAFF role to enable staff lookup', () {
      final rolesJson = jsonEncode([
        {
          'role': 'STAFF',
          'organizationCode': 'ORG_001',
          'schoolCode': 'SCH_123',
        }
      ]);

      final result = shouldSkipStaffCodeResolutionForContext(
        rolesJson: rolesJson,
        organizationCode: 'ORG_001',
        schoolCode: 'SCH_123',
      );

      expect(result, isFalse, reason: 'STAFF users should perform staff code resolution');
    });

    test('returns true for mixed KIOSK and STAFF roles', () {
      final rolesJson = jsonEncode([
        {
          'role': 'KIOSK',
          'organizationCode': 'ORG_001',
          'schoolCode': 'SCH_123',
        },
        {
          'role': 'STAFF',
          'organizationCode': 'ORG_002',
          'schoolCode': 'SCH_456',
        }
      ]);

      // When checking KIOSK context, should skip
      final resultKiosk = shouldSkipStaffCodeResolutionForContext(
        rolesJson: rolesJson,
        organizationCode: 'ORG_001',
        schoolCode: 'SCH_123',
      );
      expect(resultKiosk, isTrue, reason: 'KIOSK context should skip staff lookup');

      // When checking STAFF context, should not skip
      final resultStaff = shouldSkipStaffCodeResolutionForContext(
        rolesJson: rolesJson,
        organizationCode: 'ORG_002',
        schoolCode: 'SCH_456',
      );
      expect(resultStaff, isFalse, reason: 'STAFF context should perform staff lookup');
    });

    test('returns false for empty roles', () {
      final result = shouldSkipStaffCodeResolutionForContext(
        rolesJson: '[]',
        organizationCode: 'ORG_001',
        schoolCode: 'SCH_123',
      );

      expect(result, isFalse, reason: 'Empty roles should not skip');
    });
  });

  group('roleStringIsKioskPersona', () {
    test('returns true for KIOSK role', () {
      expect(roleStringIsKioskPersona('KIOSK'), isTrue);
      expect(roleStringIsKioskPersona('kiosk'), isTrue);
      expect(roleStringIsKioskPersona('Kiosk'), isTrue);
    });

    test('returns false for non-KIOSK roles', () {
      expect(roleStringIsKioskPersona('STAFF'), isFalse);
      expect(roleStringIsKioskPersona('GUARDIAN'), isFalse);
      expect(roleStringIsKioskPersona('TEACHER'), isFalse);
      expect(roleStringIsKioskPersona('STAFF_KIOSK'), isFalse);
    });
  });

  group('loginResponseIsKioskUser', () {
    test('returns true for KIOSK role in response', () {
      final result = loginResponseIsKioskUser([
        {
          'role': 'KIOSK',
          'organizationCode': 'ORG_001',
          'schoolCode': 'SCH_123',
        }
      ]);

      expect(result, isTrue);
    });

    test('returns false for non-KIOSK roles', () {
      final result = loginResponseIsKioskUser([
        {
          'role': 'GUARDIAN',
          'organizationCode': 'ORG_001',
          'schoolCode': 'SCH_123',
        }
      ]);

      expect(result, isFalse);
    });

    test('returns true when KIOSK is among multiple roles', () {
      final result = loginResponseIsKioskUser([
        {
          'role': 'GUARDIAN',
          'organizationCode': 'ORG_001',
          'schoolCode': 'SCH_123',
        },
        {
          'role': 'KIOSK',
          'organizationCode': 'ORG_002',
          'schoolCode': 'SCH_456',
        }
      ]);

      expect(result, isTrue);
    });
  });
}
