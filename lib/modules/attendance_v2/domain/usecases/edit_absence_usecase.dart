import '../repositories/attendance_v2_repository.dart';

/// Edits an absence record (admin only).
class EditAbsenceUseCase {
  EditAbsenceUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<void> call({
    required String code,
    required String staffCode,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String type,
    required String note,
  }) {
    return _repository.editAbsence(
      code: code,
      staffCode: staffCode,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      type: type,
      note: note,
    );
  }
}
