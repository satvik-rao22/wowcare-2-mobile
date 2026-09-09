import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_physical_exam_mapper.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/domain/features/student/entities/student_physical_exam.dart';

void main() {
  group('StudentPhysicalExamModelMapper.toEntity', () {
    test('maps every field faithfully', () {
      const model = StudentPhysicalExamModel(
        code: 'EXAM_001',
        examDate: '2026-03-15',
        status: 'COMPLETED',
        notes: 'Healthy, cleared for activities',
      );

      final entity = model.toEntity();

      expect(entity, isA<StudentPhysicalExam>());
      expect(entity.code, 'EXAM_001');
      expect(entity.examDate, '2026-03-15');
      expect(entity.status, 'COMPLETED');
      expect(entity.notes, 'Healthy, cleared for activities');
    });

    test('carries nulls/optionals through', () {
      const model = StudentPhysicalExamModel(code: 'EXAM_002');

      final entity = model.toEntity();

      // Required field carried through.
      expect(entity.code, 'EXAM_002');
      // Optional fields null.
      expect(entity.examDate, isNull);
      expect(entity.status, isNull);
      expect(entity.notes, isNull);
    });
  });
}
