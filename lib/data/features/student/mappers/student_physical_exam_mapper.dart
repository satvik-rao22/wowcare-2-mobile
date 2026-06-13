import '../../../../domain/features/student/entities/student_physical_exam.dart';
import '../models/student_models.dart';

/// Translates the data-layer [StudentPhysicalExamModel] DTO into the pure domain
/// [StudentPhysicalExam] entity.
extension StudentPhysicalExamModelMapper on StudentPhysicalExamModel {
  StudentPhysicalExam toEntity() => StudentPhysicalExam(
        code: code,
        examDate: examDate,
        status: status,
        notes: notes,
      );
}
