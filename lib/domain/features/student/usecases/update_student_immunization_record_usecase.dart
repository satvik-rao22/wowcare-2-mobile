import '../entities/student_immunization.dart';
import '../repositories/student_repository.dart';

class UpdateStudentImmunizationRecordUseCase {
  UpdateStudentImmunizationRecordUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentImmunization> call({
    required String studentCode,
    required StudentImmunization record,
    required DateTime date,
    required String status,
    String? exemptionReason,
  }) {
    return _repository.updateStudentImmunizationRecord(
      studentCode: studentCode,
      record: record,
      date: date,
      status: status,
      exemptionReason: exemptionReason,
    );
  }
}
