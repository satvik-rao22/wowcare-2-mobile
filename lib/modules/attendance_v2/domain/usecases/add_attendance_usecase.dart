import '../repositories/attendance_v2_repository.dart';

/// Adds an attendance session (sign-in and/or sign-out) — admin only.
class AddAttendanceUseCase {
  AddAttendanceUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<void> call({
    required String staffCode,
    required DateTime date,
    required String timeZone,
    String? signInClassroomCode,
    DateTime? signInLocal,
    String? signOutClassroomCode,
    DateTime? signOutLocal,
  }) {
    return _repository.addAttendance(
      staffCode: staffCode,
      date: date,
      timeZone: timeZone,
      signInClassroomCode: signInClassroomCode,
      signInLocal: signInLocal,
      signOutClassroomCode: signOutClassroomCode,
      signOutLocal: signOutLocal,
    );
  }
}
