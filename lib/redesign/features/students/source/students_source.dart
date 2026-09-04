import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';

/// What a roster fetch came back with.
///
/// Three outcomes rather than one, because 5g draws three of them: the list,
/// the copy that was already on the phone, and the refusal. A thrown
/// exception is the fourth, and the cubit turns that into the failed state.
@immutable
sealed class RosterResult {
  const RosterResult();
}

/// The roster, live.
@immutable
class RosterLoaded extends RosterResult {
  const RosterLoaded(this.snapshot);

  final RosterSnapshot snapshot;
}

/// No signal. What is here is what the phone had saved, at [asOfLabel].
@immutable
class RosterOffline extends RosterResult {
  const RosterOffline({required this.snapshot, required this.asOfLabel});

  final RosterSnapshot snapshot;

  /// "8:12 this morning".
  final String asOfLabel;
}

/// This account may not read student records at this school.
@immutable
class RosterRestricted extends RosterResult {
  const RosterRestricted();
}

/// Where M05 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation over `StudentRepository` and the two attendance
/// usecases the list already calls.
///
/// Nothing here is new API work. The roster is `getStudentPage` with the
/// arguments 5b already sends (`status`, `classroomCodes`, `tagCodes`,
/// `guardianCodes`, `attendanceStatuses`, `search`), plus
/// `GetStudentTodaySignInStatusMap` and
/// `GetStudentAttendanceExpectedSummary`, which is what puts the dot on the
/// avatar and the counts on the classroom header for free.
abstract interface class StudentsSource {
  /// The roster for [persona]. A staff member sees [scopeClassroom] only,
  /// which is the classroom they are rostered to; an admin sees the school.
  Future<RosterResult> loadRoster({
    required Persona persona,
    String? scopeClassroom,
    String query = '',
  });

  /// One student's whole record: the five tabs of 5c in one fetch.
  Future<StudentProfileRecord> loadProfile(String id);

  /// The classrooms a student can be put in, in the school's own order.
  Future<List<String>> classroomNames();

  /// The school's own tag list, already loaded for the filter sheet and the
  /// tag editor. It is a list rather than four fixed chips because it is.
  Future<List<String>> tagNames();

  /// The parents step two links to, and the filter sheet searches.
  Future<List<GuardianOption>> guardianOptions();

  /// Students already enrolled with the same last name, so the wizard can
  /// offer them as siblings before it saves ([excludeId] is the student being
  /// edited, who is never their own sibling).
  Future<List<StudentSummary>> siblingsNamed(
    String lastName, {
    String? excludeId,
  });

  /// Step one's `createStudent`, plus whichever optional steps were filled.
  Future<StudentSummary> createStudent(StudentDraft draft);

  /// 5e's save: the profile patch, the classroom move and the tag write.
  Future<StudentSummary> updateStudent({
    required String id,
    required StudentDraft draft,
  });

  /// 5h. Nothing is deleted; the record leaves the active list.
  Future<StudentSummary> deactivateStudent(String id);

  /// The Documents tab's own list, which pages separately from the record.
  Future<List<StudentDocumentItem>> loadDocuments(String id);

  /// The device's file picker, or its camera when [fromCamera]. Null when
  /// the sheet was dismissed without choosing anything.
  Future<PickedFile?> pickFile({bool fromCamera = false});

  /// Sends [draft] to the document store, reporting 0 to 1 as it goes.
  /// Throws when the upload does not complete, which is 5f's failed state.
  Future<StudentDocumentItem> uploadDocument({
    required String studentId,
    required DocumentDraft draft,
    required ValueChanged<double> onProgress,
  });
}
