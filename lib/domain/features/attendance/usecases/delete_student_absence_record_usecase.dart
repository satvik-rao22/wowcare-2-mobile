import '../repositories/attendance_repository.dart';

/// Deletes a student absence record (e.g. before an override sign-in).
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: completes normally on success and propagates any error
/// unchanged, so callers keep their current success/error handling verbatim.
class DeleteStudentAbsenceRecordUseCase {
  const DeleteStudentAbsenceRecordUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<void> call({
    required String absenceRecordCode,
    required String staffCode,
  }) {
    return _repository.deleteStudentAbsenceRecord(
      absenceRecordCode: absenceRecordCode,
      staffCode: staffCode,
    );
  }
}
