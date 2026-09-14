import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_health_mapper.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/domain/features/student/entities/student_health.dart';

void main() {
  group('StudentHealthModelMapper.toEntity', () {
    test('maps every field faithfully', () {
      const model = StudentHealthModel(
        allergy: 'Peanuts, Shellfish',
        medications: 'Albuterol inhaler',
        dietRestrictions: 'Vegetarian',
        photoPermission: true,
      );

      final entity = model.toEntity();

      expect(entity, isA<StudentHealth>());
      expect(entity.allergy, 'Peanuts, Shellfish');
      expect(entity.medications, 'Albuterol inhaler');
      expect(entity.dietRestrictions, 'Vegetarian');
      expect(entity.photoPermission, true);
    });

    test('carries nulls/optionals through', () {
      const model = StudentHealthModel();

      final entity = model.toEntity();

      expect(entity.allergy, isNull);
      expect(entity.medications, isNull);
      expect(entity.dietRestrictions, isNull);
      expect(entity.photoPermission, isNull);
    });
  });
}
