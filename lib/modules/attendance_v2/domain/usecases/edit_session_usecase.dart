import '../repositories/attendance_v2_repository.dart';

/// Edits an attendance session's sign-in/out times (admin only).
class EditSessionUseCase {
  EditSessionUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<void> call({
    required String recordCode,
    required String staffCode,
    required DateTime signInLocal,
    DateTime? signOutLocal,
    required String timeZone,
  }) {
    return _repository.editSession(
      recordCode: recordCode,
      staffCode: staffCode,
      signInLocal: signInLocal,
      signOutLocal: signOutLocal,
      timeZone: timeZone,
    );
  }
}
