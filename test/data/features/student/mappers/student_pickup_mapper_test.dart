import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_pickup_mapper.dart';
import 'package:wowcare/data/features/student/models/student_pickup_models.dart';
import 'package:wowcare/domain/features/student/entities/student_pickup.dart';

void main() {
  group('StudentPickupModelMapper.toEntity', () {
    test('maps every field faithfully', () {
      const model = StudentPickupModel(
        code: 'PKP_001',
        studentCode: 'STU_001',
        firstName: 'Grace',
        lastName: 'Hopper',
        email: 'grace.hopper@example.com',
        phoneNumber: '+15553334444',
        relation: 'AUNT',
        clockPin: '9021',
        relationshipDescription: "Mother's sister",
        pickupType: 'AUTHORIZED',
        carpoolId: 'CAR_777',
        profilePhotoUrl: 'https://cdn.example.com/grace.png',
        profilePhotoAssetCode: 'ASSET_GRACE',
      );

      final entity = model.toEntity();

      expect(entity, isA<StudentPickup>());
      expect(entity.code, 'PKP_001');
      expect(entity.studentCode, 'STU_001');
      expect(entity.firstName, 'Grace');
      expect(entity.lastName, 'Hopper');
      expect(entity.email, 'grace.hopper@example.com');
      expect(entity.phoneNumber, '+15553334444');
      expect(entity.relation, 'AUNT');
      expect(entity.clockPin, '9021');
      expect(entity.relationshipDescription, "Mother's sister");
      expect(entity.pickupType, 'AUTHORIZED');
      expect(entity.carpoolId, 'CAR_777');
      expect(entity.profilePhotoUrl, 'https://cdn.example.com/grace.png');
      expect(entity.profilePhotoAssetCode, 'ASSET_GRACE');
    });

    test('carries nulls/optionals through', () {
      const model = StudentPickupModel(
        firstName: 'Sam',
        lastName: 'Lee',
        email: '',
        phoneNumber: '',
        relation: 'FRIEND',
      );

      final entity = model.toEntity();

      // Required fields carried through.
      expect(entity.firstName, 'Sam');
      expect(entity.lastName, 'Lee');
      expect(entity.email, '');
      expect(entity.phoneNumber, '');
      expect(entity.relation, 'FRIEND');
      // Optional fields null.
      expect(entity.code, isNull);
      expect(entity.studentCode, isNull);
      expect(entity.clockPin, isNull);
      expect(entity.relationshipDescription, isNull);
      expect(entity.pickupType, isNull);
      expect(entity.carpoolId, isNull);
      expect(entity.profilePhotoUrl, isNull);
      expect(entity.profilePhotoAssetCode, isNull);
    });
  });

  group('StudentPickupModel.fromJson', () {
    test('fully-populated json maps all fields', () {
      final model = StudentPickupModel.fromJson(<String, dynamic>{
        'code': 'PKP_100',
        'studentCode': 'STU_100',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
        'phoneNumber': '+15556667777',
        'relation': 'GRANDPARENT',
        'clockPin': '1815',
        'relationshipDescription': 'Paternal grandmother',
        'pickupType': 'AUTHORIZED',
        'carpoolId': 'CAR_100',
        'profilePhotoUrl': 'https://cdn.example.com/ada.png',
        'profilePhotoAssetCode': 'ASSET_ADA',
      });

      expect(model.code, 'PKP_100');
      expect(model.studentCode, 'STU_100');
      expect(model.firstName, 'Ada');
      expect(model.lastName, 'Lovelace');
      expect(model.email, 'ada@example.com');
      expect(model.phoneNumber, '+15556667777');
      expect(model.relation, 'GRANDPARENT');
      expect(model.clockPin, '1815');
      expect(model.relationshipDescription, 'Paternal grandmother');
      expect(model.pickupType, 'AUTHORIZED');
      expect(model.carpoolId, 'CAR_100');
      expect(model.profilePhotoUrl, 'https://cdn.example.com/ada.png');
      expect(model.profilePhotoAssetCode, 'ASSET_ADA');
    });

    test('alias keys and missing keys resolve to aliases/defaults', () {
      final model = StudentPickupModel.fromJson(<String, dynamic>{
        // `code` falls back to the `pickup_code` alias.
        'pickup_code': 'PKP_ALIAS',
        'firstName': 'Alan',
        'lastName': 'Turing',
        // email / phoneNumber missing -> default to ''.
        'relation': 'UNCLE',
        // carpoolId falls back to the `guardianCode` alias.
        'guardianCode': 'GRD_555',
        // Photo URL resolved from the `photoUrl` alias via firstNonEmpty.
        'photoUrl': 'https://cdn.example.com/alan.png',
        // Photo asset code resolved from the `mediaAssetCode` alias.
        'mediaAssetCode': 'ASSET_ALAN',
      });

      expect(model.code, 'PKP_ALIAS');
      expect(model.studentCode, isNull);
      expect(model.firstName, 'Alan');
      expect(model.lastName, 'Turing');
      expect(model.email, '');
      expect(model.phoneNumber, '');
      expect(model.relation, 'UNCLE');
      expect(model.clockPin, isNull);
      expect(model.carpoolId, 'GRD_555');
      expect(model.profilePhotoUrl, 'https://cdn.example.com/alan.png');
      expect(model.profilePhotoAssetCode, 'ASSET_ALAN');
    });
  });
}
