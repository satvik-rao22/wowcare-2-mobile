import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile_update.dart';

void main() {
  group('StaffProfileUpdate.toPayload', () {
    test(
      'with jobTag AND birthdate PRESENT reproduces the full Map the view built',
      () {
        const request = StaffProfileUpdate(
          firstName: 'Ada',
          lastName: 'Byron',
          status: 'ACTIVE',
          phoneNumber: '6035551234',
          designation: 'OWNER',
          jobTag: 'FULL_TIME',
          birthdate: '1990-02-03T09:48:39.440Z',
        );

        // Byte-for-byte the old literal:
        //   {
        //     'firstName': ..., 'lastName': ..., 'status': ...,
        //     'phoneNumber': ..., 'designation': ...,
        //     if (jobTagApi != null) 'jobTag': jobTagApi,
        //     if (birthDateApi != null) 'birthdate': birthDateApi,
        //   }
        expect(request.toPayload(), {
          'firstName': 'Ada',
          'lastName': 'Byron',
          'status': 'ACTIVE',
          'phoneNumber': '6035551234',
          'designation': 'OWNER',
          'jobTag': 'FULL_TIME',
          'birthdate': '1990-02-03T09:48:39.440Z',
        });
      },
    );

    test(
      'with jobTag=null AND birthdate=null the keys are ABSENT (conditional omission)',
      () {
        const request = StaffProfileUpdate(
          firstName: 'Ada',
          lastName: 'Byron',
          status: 'ACTIVE',
          phoneNumber: '6035551234',
          designation: 'OWNER',
          jobTag: null,
          birthdate: null,
        );

        final payload = request.toPayload();

        // The five required keys and ONLY those.
        expect(payload, {
          'firstName': 'Ada',
          'lastName': 'Byron',
          'status': 'ACTIVE',
          'phoneNumber': '6035551234',
          'designation': 'OWNER',
        });
        expect(payload.containsKey('jobTag'), isFalse);
        expect(payload.containsKey('birthdate'), isFalse);
      },
    );

    test('jobTag present but birthdate null omits only birthdate', () {
      const request = StaffProfileUpdate(
        firstName: 'A',
        lastName: 'B',
        status: 'ACTIVE',
        phoneNumber: '1',
        designation: 'STAFF',
        jobTag: 'PART_TIME',
      );

      final payload = request.toPayload();
      expect(payload['jobTag'], 'PART_TIME');
      expect(payload.containsKey('birthdate'), isFalse);
      expect(payload.keys.toList(), [
        'firstName',
        'lastName',
        'status',
        'phoneNumber',
        'designation',
        'jobTag',
      ]);
    });

    test('birthdate present but jobTag null omits only jobTag', () {
      const request = StaffProfileUpdate(
        firstName: 'A',
        lastName: 'B',
        status: 'ACTIVE',
        phoneNumber: '1',
        designation: 'STAFF',
        birthdate: '2000-01-01T00:00:00.000Z',
      );

      final payload = request.toPayload();
      expect(payload['birthdate'], '2000-01-01T00:00:00.000Z');
      expect(payload.containsKey('jobTag'), isFalse);
    });
  });

  group('equality', () {
    test('null-optional instances are equal; differing jobTag unequal', () {
      const a = StaffProfileUpdate(
        firstName: 'A',
        lastName: 'B',
        status: 'ACTIVE',
        phoneNumber: '1',
        designation: 'STAFF',
      );
      const b = StaffProfileUpdate(
        firstName: 'A',
        lastName: 'B',
        status: 'ACTIVE',
        phoneNumber: '1',
        designation: 'STAFF',
      );
      const c = StaffProfileUpdate(
        firstName: 'A',
        lastName: 'B',
        status: 'ACTIVE',
        phoneNumber: '1',
        designation: 'STAFF',
        jobTag: 'FULL_TIME',
      );

      expect(a, b);
      expect(a == c, isFalse);
    });
  });
}
