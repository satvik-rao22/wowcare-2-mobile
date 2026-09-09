import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_physician_mapper.dart';
import 'package:wowcare/data/features/student/models/student_physician_models.dart';
import 'package:wowcare/domain/features/student/entities/student_physician.dart';

void main() {
  group('StudentPhysicianModelMapper.toEntity', () {
    test('maps every field faithfully', () {
      const model = StudentPhysicianModel(
        code: 'PHY_001',
        firstName: 'Alice',
        lastName: 'Nguyen',
        email: 'alice.nguyen@clinic.example.com',
        phoneNumber: '+15559876543',
        address: '100 Health St, Springfield',
        specialty: 'Pediatrics',
        notes: 'Preferred provider',
        status: 'ACTIVE',
      );

      final entity = model.toEntity();

      expect(entity, isA<StudentPhysician>());
      expect(entity.code, 'PHY_001');
      expect(entity.firstName, 'Alice');
      expect(entity.lastName, 'Nguyen');
      expect(entity.email, 'alice.nguyen@clinic.example.com');
      expect(entity.phoneNumber, '+15559876543');
      expect(entity.address, '100 Health St, Springfield');
      expect(entity.specialty, 'Pediatrics');
      expect(entity.notes, 'Preferred provider');
      expect(entity.status, 'ACTIVE');
    });

    test('carries minimal (empty-string) values through', () {
      const model = StudentPhysicianModel(
        code: 'PHY_002',
        firstName: '',
        lastName: '',
        email: '',
        phoneNumber: '',
        address: '',
        specialty: '',
        notes: '',
        status: '',
      );

      final entity = model.toEntity();

      expect(entity.code, 'PHY_002');
      expect(entity.firstName, '');
      expect(entity.lastName, '');
      expect(entity.email, '');
      expect(entity.phoneNumber, '');
      expect(entity.address, '');
      expect(entity.specialty, '');
      expect(entity.notes, '');
      expect(entity.status, '');
    });
  });

  group('StudentPhysicianModel.fromJson', () {
    test('fully-populated json maps all fields', () {
      final model = StudentPhysicianModel.fromJson(<String, dynamic>{
        'code': 'PHY_100',
        'firstName': 'Bob',
        'lastName': 'Carter',
        'email': 'bob.carter@clinic.example.com',
        'phoneNumber': '+15551112222',
        'address': '55 Wellness Ave',
        'specialty': 'Family Medicine',
        'notes': 'On call weekends',
        'status': 'ACTIVE',
      });

      expect(model.code, 'PHY_100');
      expect(model.firstName, 'Bob');
      expect(model.lastName, 'Carter');
      expect(model.email, 'bob.carter@clinic.example.com');
      expect(model.phoneNumber, '+15551112222');
      expect(model.address, '55 Wellness Ave');
      expect(model.specialty, 'Family Medicine');
      expect(model.notes, 'On call weekends');
      expect(model.status, 'ACTIVE');
    });

    test('missing keys resolve to empty-string defaults', () {
      final model = StudentPhysicianModel.fromJson(<String, dynamic>{
        'firstName': 'Solo',
      });

      expect(model.code, '');
      expect(model.firstName, 'Solo');
      expect(model.lastName, '');
      expect(model.email, '');
      expect(model.phoneNumber, '');
      expect(model.address, '');
      expect(model.specialty, '');
      expect(model.notes, '');
      expect(model.status, '');
    });
  });
}
