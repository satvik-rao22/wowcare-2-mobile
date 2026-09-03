import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';

void main() {
  group('StudentGuardianModel.fromJson fullName fallback', () {
    test('uses top-level firstName/lastName when present', () {
      final model = StudentGuardianModel.fromJson({
        'guardianCode': 'G1',
        'firstName': 'Jane',
        'lastName': 'Doe',
        'fullName': 'Should Not Be Used',
      });
      expect(model.fullName, 'Jane Doe');
    });

    test(
      'falls back to top-level fullName when firstName/lastName are both empty',
      () {
        final model = StudentGuardianModel.fromJson({
          'guardianCode': 'G1',
          'fullName': 'Jane Doe',
        });
        expect(model.fullName, 'Jane Doe');
      },
    );

    test('falls back to top-level name when fullName is absent too', () {
      final model = StudentGuardianModel.fromJson({
        'guardianCode': 'G1',
        'name': 'Jane Doe',
      });
      expect(model.fullName, 'Jane Doe');
    });

    test('falls back to nested user.firstName/user.lastName when the guardian '
        'record itself has no name fields at all - this is the exact shape '
        'that silently dropped a real guardian from the Child Custody '
        'dropdown after the profile-edit MVVM migration', () {
      final model = StudentGuardianModel.fromJson({
        'guardianCode': 'G1',
        'user': {'firstName': 'Jane', 'lastName': 'Doe'},
      });
      expect(model.fullName, 'Jane Doe');
    });

    test('falls back to nested user.fullName as the last resort', () {
      final model = StudentGuardianModel.fromJson({
        'guardianCode': 'G1',
        'user': {'fullName': 'Jane Doe'},
      });
      expect(model.fullName, 'Jane Doe');
    });

    test('resolves to empty when no name field is present anywhere', () {
      final model = StudentGuardianModel.fromJson({'guardianCode': 'G1'});
      expect(model.fullName, '');
    });

    test(
      'the resolved override survives a toJson/fromJson cache round-trip',
      () {
        final original = StudentGuardianModel.fromJson({
          'guardianCode': 'G1',
          'user': {'firstName': 'Jane', 'lastName': 'Doe'},
        });
        final roundTripped = StudentGuardianModel.fromJson(original.toJson());
        expect(roundTripped.fullName, 'Jane Doe');
      },
    );
  });
}
