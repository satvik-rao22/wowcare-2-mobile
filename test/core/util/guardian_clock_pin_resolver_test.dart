import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/guardian_clock_pin_resolver.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';

StudentGuardian _guardian({
  String guardianCode = '',
  String userCode = '',
  String? clockPin,
  bool primaryContact = false,
}) {
  return StudentGuardian(
    guardianCode: guardianCode,
    userCode: userCode,
    firstName: 'G',
    lastName: guardianCode,
    mobile: '',
    email: '',
    relationToStudent: 'PARENT',
    primaryContact: primaryContact,
    legalCustody: false,
    clockPin: clockPin,
  );
}

void main() {
  group('selectGuardianClockPin', () {
    test('prefers the row belonging to the logged-in user over the primary', () {
      final pin = selectGuardianClockPin(
        guardians: [
          _guardian(guardianCode: 'G1', userCode: 'U1', clockPin: '1111',
              primaryContact: true),
          _guardian(guardianCode: 'G2', userCode: 'U2', clockPin: '2222'),
        ],
        loggedInUserCode: 'U2',
        loggedInGuardianCode: '',
      );

      expect(pin, '2222');
    });

    test('matches on guardianCode when the userCode is not known', () {
      final pin = selectGuardianClockPin(
        guardians: [
          _guardian(guardianCode: 'G1', userCode: 'U1', clockPin: '1111'),
          _guardian(guardianCode: 'G2', userCode: 'U2', clockPin: '2222'),
        ],
        loggedInUserCode: '',
        loggedInGuardianCode: 'G2',
      );

      expect(pin, '2222');
    });

    test('falls back to the primary contact when the user has no row', () {
      final pin = selectGuardianClockPin(
        guardians: [
          _guardian(guardianCode: 'G1', userCode: 'U1', clockPin: '1111'),
          _guardian(guardianCode: 'G2', userCode: 'U2', clockPin: '2222',
              primaryContact: true),
        ],
        loggedInUserCode: 'U9',
        loggedInGuardianCode: '',
      );

      expect(pin, '2222');
    });

    test('falls back to the first guardian that has a PIN', () {
      final pin = selectGuardianClockPin(
        guardians: [
          _guardian(guardianCode: 'G1', userCode: 'U1'),
          _guardian(guardianCode: 'G2', userCode: 'U2', clockPin: '2222'),
        ],
        loggedInUserCode: '',
        loggedInGuardianCode: '',
      );

      expect(pin, '2222');
    });

    test('a PIN-less row for the logged-in user does not shadow a real PIN', () {
      final pin = selectGuardianClockPin(
        guardians: [
          _guardian(guardianCode: 'G1', userCode: 'U1', clockPin: '   '),
          _guardian(guardianCode: 'G2', userCode: 'U2', clockPin: '2222',
              primaryContact: true),
        ],
        loggedInUserCode: 'U1',
        loggedInGuardianCode: '',
      );

      expect(pin, '2222');
    });

    test('returns empty when no guardian carries a PIN', () {
      final pin = selectGuardianClockPin(
        guardians: [_guardian(guardianCode: 'G1', userCode: 'U1')],
        loggedInUserCode: 'U1',
        loggedInGuardianCode: '',
      );

      expect(pin, '');
    });

    test('returns empty for a student with no guardians at all', () {
      expect(
        selectGuardianClockPin(
          guardians: const [],
          loggedInUserCode: 'U1',
          loggedInGuardianCode: 'G1',
        ),
        '',
      );
    });
  });
}
