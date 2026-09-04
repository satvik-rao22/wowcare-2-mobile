import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// What a day fetch came back with.
///
/// Two outcomes rather than one, because 4e draws both: the day, and the copy
/// the phone already had. A thrown exception is the third, and the cubit
/// turns that into the failed state.
@immutable
sealed class AttendanceDayResult {
  const AttendanceDayResult();
}

/// The day, live.
@immutable
class AttendanceDayLoaded extends AttendanceDayResult {
  const AttendanceDayLoaded(this.snapshot);

  final AttendanceSnapshot snapshot;
}

/// No signal. What is here is what the phone had saved, at [asOfLabel], and
/// it is read only: nothing in this app has ever queued a write.
@immutable
class AttendanceDayOffline extends AttendanceDayResult {
  const AttendanceDayOffline({required this.snapshot, required this.asOfLabel});

  final AttendanceSnapshot snapshot;

  /// "8:02 this morning".
  final String asOfLabel;
}

/// Where M04 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation over `AttendanceRepository`.
///
/// Nothing here is new API work. [loadDay] is `getStudentAttendanceDaily` or
/// `getStaffAttendanceDaily` with the two expected-summary cards beside it,
/// [loadRange] is `getStudentAttendanceCustom` / `getStaffAttendanceCustom`,
/// and every write below already exists: `createStudentSignInRecords`,
/// `submitStudentSignOut`, `markStudentsAbsent`,
/// `deleteStudentAbsenceRecord` (which is what Override Sign In does),
/// `submitStudentTransfer` and `updateStudentAttendanceRecord`.
abstract interface class AttendanceSource {
  /// One day for one audience. A staff member sees [scopeClassroom] only; a
  /// guardian sees their own children and nobody else's.
  Future<AttendanceDayResult> loadDay({
    required Persona persona,
    required AttendanceAudience audience,
    required DateTime day,
    String? scopeClassroom,
    String query = '',
  });

  /// The school's classrooms, in its own order: the transfer picker and the
  /// range filter both read this.
  Future<List<String>> classroomNames();

  /// One page of 4f. Both totals come back on this call already.
  Future<RangePage> loadRange({
    required AttendanceAudience audience,
    required DateRange range,
    Set<String> classrooms = const <String>{},
    String query = '',
    int page = 0,
  });

  /// Whether the device is on site. The staff member's own sign-in needs it;
  /// so, by the school's own rule, does the sign-in form.
  Future<bool> isInsideGeofence();

  /// The staff member's own sign-in, the only one that is geofenced.
  Future<SelfShift> signSelfIn();

  /// And their own sign-out, which ends their shift and locks the classroom
  /// back up.
  Future<SelfShift> signSelfOut();

  /// Creates a record. There is no create-attendance endpoint: this is it.
  Future<void> signIn({
    required List<String> ids,
    required AttendanceAudience audience,
    required DateTime at,
  });

  Future<void> signOut({
    required List<String> ids,
    required AttendanceAudience audience,
    required DateTime at,
  });

  /// The one action that takes a reason.
  Future<void> markAbsent({
    required List<String> ids,
    required DateTime date,
    required String reason,
  });

  /// Deletes the absence record, which is what Override Sign In leans on.
  Future<void> undoAbsence(String id);

  Future<void> transfer({required String id, required String toClassroom});

  /// Corrects a recorded time. Leaves an audit note with the editor's name.
  Future<void> editTimes({
    required String id,
    required DateTime at,
    required bool isSignOut,
  });
}
