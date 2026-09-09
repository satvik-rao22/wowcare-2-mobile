import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_immunization_mapper.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/domain/features/student/entities/student_immunization.dart';

void main() {
  group('StudentImmunizationModelMapper.toEntity', () {
    test('maps every field faithfully', () {
      const model = StudentImmunizationModel(
        code: 'IMM_001',
        studentCode: 'STU_001',
        vaccineName: 'MMR',
        vaccineDoseCode: 'DOSE_MMR_2',
        doseNumber: 2,
        dueDate: '2026-05-01',
        administeredDate: '2026-05-03',
        status: 'ADMINISTERED',
        exemptionReason: 'Medical exemption',
        notes: 'No adverse reaction',
      );

      final entity = model.toEntity();

      expect(entity, isA<StudentImmunization>());
      expect(entity.code, 'IMM_001');
      expect(entity.studentCode, 'STU_001');
      expect(entity.vaccineName, 'MMR');
      expect(entity.vaccineDoseCode, 'DOSE_MMR_2');
      expect(entity.doseNumber, 2);
      expect(entity.dueDate, '2026-05-01');
      expect(entity.administeredDate, '2026-05-03');
      expect(entity.status, 'ADMINISTERED');
      expect(entity.exemptionReason, 'Medical exemption');
      expect(entity.notes, 'No adverse reaction');
    });

    test('carries nulls/optionals through', () {
      const model = StudentImmunizationModel(
        code: 'IMM_002',
        studentCode: 'STU_002',
        vaccineName: 'DTaP',
        vaccineDoseCode: 'DOSE_DTAP_1',
        doseNumber: 1,
        status: 'DUE',
      );

      final entity = model.toEntity();

      // Required fields carried through.
      expect(entity.code, 'IMM_002');
      expect(entity.studentCode, 'STU_002');
      expect(entity.vaccineName, 'DTaP');
      expect(entity.vaccineDoseCode, 'DOSE_DTAP_1');
      expect(entity.doseNumber, 1);
      expect(entity.status, 'DUE');
      // Optional fields null.
      expect(entity.dueDate, isNull);
      expect(entity.administeredDate, isNull);
      expect(entity.exemptionReason, isNull);
      expect(entity.notes, isNull);
    });
  });
}
