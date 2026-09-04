import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// Where M07 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation fans out across the calls the module already makes:
/// `GET /api/v1/classroom` for the list with its ratio and capacity, the
/// by-classrooms attendance summary for today's counts, the school capacity
/// and FTE readings for the navy card, `/api/v1/staff-classrooms` for a
/// classroom's staff, `/api/v1/student-classroom` for its roster, and the two
/// assign endpoints.
///
/// Nothing here is new API work. Every field traces to a response the app
/// already receives.
abstract interface class ClassroomsSource {
  /// The whole 7a screen: the school's figures and every classroom on it.
  Future<ClassroomBoard> loadBoard();

  /// One classroom with its three tabs (7c, 7e).
  Future<ClassroomDetail> loadClassroom(String id);

  /// The classroom's own record (7f).
  Future<ClassroomProfile> loadProfile(String id);

  /// Post a note to the classroom's board.
  Future<ClassroomNote> postNote({
    required String classroomId,
    required String text,
  });

  /// Put a photo on the classroom's record. Throws when the upload fails,
  /// which is the state 7f draws.
  Future<ClassroomPhoto> uploadPhoto({
    required String classroomId,
    required String fileName,
  });

  Future<void> removePhoto(String classroomId);

  /// Everybody who could join this classroom (7g step one, 7h step one).
  Future<List<AssignCandidate>> loadCandidates({
    required String classroomId,
    required AssignKind kind,
  });

  /// Apply the assignment. It takes effect immediately: a future-dated move
  /// is on the module's costly list and is not offered.
  Future<void> assign({
    required String classroomId,
    required AssignKind kind,
    required List<String> ids,
  });

  /// Take a student out of the classroom. They stay enrolled at the school.
  Future<void> removeStudent({
    required String classroomId,
    required String studentId,
  });

  /// Move a student to another classroom, today. Refused while they are
  /// signed in, which is the refusal 7i draws.
  Future<void> moveStudent({
    required String fromClassroomId,
    required String toClassroomId,
    required String studentId,
  });

  Future<ClassroomSummary> createClassroom(ClassroomDraft draft);
}
