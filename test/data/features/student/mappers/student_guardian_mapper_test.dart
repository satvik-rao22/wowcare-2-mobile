import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_guardian_mapper.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';

void main() {
  group('StudentGuardianModelMapper.toEntity', () {
    test('maps every field faithfully', () {
      const model = StudentGuardianModel(
        guardianCode: 'GRD_001',
        userCode: 'USR_001',
        firstName: 'Jane',
        lastName: 'Doe',
        mobile: '+15551234567',
        email: 'jane.doe@example.com',
        clockPin: '4821',
        relationToStudent: 'MOTHER',
        primaryContact: true,
        legalCustody: true,
        profilePhotoUrl: 'https://cdn.example.com/jane.png',
        profilePhotoAssetCode: 'ASSET_JANE',
      );

      final entity = model.toEntity();

      expect(entity, isA<StudentGuardian>());
      expect(entity.guardianCode, 'GRD_001');
      expect(entity.userCode, 'USR_001');
      expect(entity.firstName, 'Jane');
      expect(entity.lastName, 'Doe');
      expect(entity.mobile, '+15551234567');
      expect(entity.email, 'jane.doe@example.com');
      expect(entity.clockPin, '4821');
      expect(entity.relationToStudent, 'MOTHER');
      expect(entity.primaryContact, true);
      expect(entity.legalCustody, true);
      expect(entity.profilePhotoUrl, 'https://cdn.example.com/jane.png');
      expect(entity.profilePhotoAssetCode, 'ASSET_JANE');
    });

    test('carries nulls/optionals through', () {
      const model = StudentGuardianModel(
        guardianCode: 'GRD_002',
        userCode: 'USR_002',
        firstName: 'John',
        lastName: 'Smith',
        mobile: '',
        email: '',
        relationToStudent: 'FATHER',
        primaryContact: false,
        legalCustody: false,
      );

      final entity = model.toEntity();

      // Required fields carried through.
      expect(entity.guardianCode, 'GRD_002');
      expect(entity.userCode, 'USR_002');
      expect(entity.firstName, 'John');
      expect(entity.lastName, 'Smith');
      expect(entity.mobile, '');
      expect(entity.email, '');
      expect(entity.relationToStudent, 'FATHER');
      expect(entity.primaryContact, false);
      expect(entity.legalCustody, false);
      // Optional fields null.
      expect(entity.clockPin, isNull);
      expect(entity.profilePhotoUrl, isNull);
      expect(entity.profilePhotoAssetCode, isNull);
    });
  });
}
