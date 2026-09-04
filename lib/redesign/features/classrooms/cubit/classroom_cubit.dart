import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';

part 'classroom_state.dart';

/// One classroom: an Admin's three tabs (7c), a teacher's two (7e), the
/// filter sheet's results (7d), the two refusals (7i) and the four edge
/// states (7j).
///
/// The persona is passed in rather than read off a locator, so the screen
/// never branches on who is looking: it draws what the state allows.
class ClassroomCubit extends Cubit<ClassroomState> {
  ClassroomCubit({
    required ClassroomsSource source,
    required String classroomId,
    required Persona persona,
    required bool isOwnClassroom,
  }) : _source = source,
       super(
         ClassroomState(
           classroomId: classroomId,
           persona: persona,
           isOwnClassroom: isOwnClassroom,
         ),
       );

  final ClassroomsSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: ClassroomStatus.loading));

    try {
      final detail = await _source.loadClassroom(state.classroomId);
      if (isClosed) return;
      emit(state.copyWith(status: ClassroomStatus.ready, detail: detail));
    } on Exception catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: state.detail == null
              ? ClassroomStatus.failed
              : ClassroomStatus.cached,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  // --- What the screen is showing -------------------------------------------

  void selectTab(ClassroomTab tab) =>
      emit(state.copyWith(tab: tab, clearExpanded: true, isSelectMode: false));

  void search(String query) => emit(state.copyWith(query: query));

  void clearSearch() => emit(state.copyWith(query: ''));

  void toggleExpanded(String studentId) => emit(
    state.expandedId == studentId
        ? state.copyWith(clearExpanded: true)
        : state.copyWith(expandedId: studentId),
  );

  void applyStudentFilters(StudentFilters filters) =>
      emit(state.copyWith(studentFilters: filters));

  void applyStaffFilters(StaffFilters filters) =>
      emit(state.copyWith(staffFilters: filters));

  void clearFilters() => emit(
    state.copyWith(
      studentFilters: const StudentFilters(),
      staffFilters: const StaffFilters(),
    ),
  );

  /// The two quick toggles that sit over the roster, which are the same two
  /// switches the filter sheet holds.
  void toggleSignedInOnly() => emit(
    state.copyWith(
      studentFilters: state.studentFilters.copyWith(
        signedInOnly: !state.studentFilters.signedInOnly,
        nappingOnly: false,
      ),
    ),
  );

  void toggleNappingOnly() => emit(
    state.copyWith(
      studentFilters: state.studentFilters.copyWith(
        nappingOnly: !state.studentFilters.nappingOnly,
        signedInOnly: false,
      ),
    ),
  );

  /// The duty chips over the Staff tab, which are the same switches the
  /// filter sheet holds.
  void toggleStaffDuty(StaffDutyState duty) {
    final next = <StaffDutyState>{...state.staffFilters.dutyStates};
    if (!next.remove(duty)) next.add(duty);
    emit(
      state.copyWith(
        staffFilters: state.staffFilters.copyWith(dutyStates: next),
      ),
    );
  }

  // --- Select mode ------------------------------------------------------------

  void toggleSelectMode() => emit(
    state.copyWith(
      isSelectMode: !state.isSelectMode,
      selectedIds: const <String>{},
      clearExpanded: true,
    ),
  );

  void toggleSelected(String studentId) {
    final next = <String>{...state.selectedIds};
    if (!next.remove(studentId)) next.add(studentId);
    emit(state.copyWith(selectedIds: next));
  }

  void selectAll() => emit(
    state.copyWith(
      selectedIds: <String>{for (final s in state.visibleStudents) s.id},
    ),
  );

  void clearSelection() => emit(state.copyWith(selectedIds: const <String>{}));

  // --- Writes -----------------------------------------------------------------

  /// The teacher's own clock. Until it turns, the roster is readable and
  /// nothing on it can be marked (7e).
  void clockIn() => emit(state.copyWith(isClockedIn: true));

  /// Take a student out of the classroom (7i's second refusal). They stay
  /// enrolled at the school.
  Future<void> removeStudent(String studentId) async {
    final detail = state.detail;
    if (detail == null || !state.canEdit) return;
    emit(state.copyWith(isWorking: true));

    try {
      await _source.removeStudent(
        classroomId: state.classroomId,
        studentId: studentId,
      );
      if (isClosed) return;
      final students = detail.students.where((s) => s.id != studentId).toList();
      emit(
        state.copyWith(
          isWorking: false,
          clearExpanded: true,
          detail: detail.copyWith(
            students: students,
            summary: detail.summary.copyWith(enrolled: students.length),
          ),
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isWorking: false));
    }
  }

  /// Move a student to another classroom, today. A student who is signed in
  /// is refused before this is ever called: their attendance would end up
  /// recorded against a classroom they are not in (7i).
  Future<void> moveStudent({
    required String studentId,
    required String toClassroomId,
  }) async {
    final detail = state.detail;
    if (detail == null || !state.canEdit) return;
    emit(state.copyWith(isWorking: true));

    try {
      await _source.moveStudent(
        fromClassroomId: state.classroomId,
        toClassroomId: toClassroomId,
        studentId: studentId,
      );
      if (isClosed) return;
      final students = detail.students.where((s) => s.id != studentId).toList();
      emit(
        state.copyWith(
          isWorking: false,
          clearExpanded: true,
          detail: detail.copyWith(
            students: students,
            summary: detail.summary.copyWith(enrolled: students.length),
          ),
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isWorking: false));
    }
  }

  Future<void> postNote(String text) async {
    final detail = state.detail;
    if (detail == null || text.trim().isEmpty) return;
    emit(state.copyWith(isWorking: true));

    try {
      final note = await _source.postNote(
        classroomId: state.classroomId,
        text: text.trim(),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          isWorking: false,
          detail: detail.copyWith(
            notes: <ClassroomNote>[...detail.notes, note],
          ),
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isWorking: false));
    }
  }
}
