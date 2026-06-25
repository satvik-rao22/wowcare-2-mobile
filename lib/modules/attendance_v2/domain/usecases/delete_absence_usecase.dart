import '../repositories/attendance_v2_repository.dart';

/// Deletes an absence record (admin only).
class DeleteAbsenceUseCase {
  DeleteAbsenceUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<void> call({required String code, required String staffCode}) {
    return _repository.deleteAbsence(code: code, staffCode: staffCode);
  }
}
