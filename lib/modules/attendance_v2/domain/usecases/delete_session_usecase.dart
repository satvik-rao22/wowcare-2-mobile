import '../repositories/attendance_v2_repository.dart';

/// Deletes an attendance session record (admin only).
class DeleteSessionUseCase {
  DeleteSessionUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<void> call({
    required String recordCode,
    required String staffCode,
  }) {
    return _repository.deleteSession(
      recordCode: recordCode,
      staffCode: staffCode,
    );
  }
}
