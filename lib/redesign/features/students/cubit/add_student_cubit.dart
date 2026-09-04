import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/validation/student_validator.dart';

part 'add_student_state.dart';

/// 5d. Adding a student, in three steps of which two may be skipped.
///
/// The shape follows the existing wizard: step one is the `createStudent`
/// call and is the only required one; the parent link and the regular
/// schedule are separate writes, which is why skipping them still leaves a
/// student on the roster.
///
/// [today] is passed in rather than read off the clock, because a school's
/// day is its own timezone's and because a date rule has to be testable.
class AddStudentCubit extends Cubit<AddStudentState> {
  AddStudentCubit({required StudentsSource source, required DateTime today})
    : _source = source,
      _validator = StudentValidator(today: today),
      super(const AddStudentState());

  final StudentsSource _source;
  final StudentValidator _validator;

  bool _isFetching = false;

  /// The classrooms and parents the two pickers offer.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(isLoadingOptions: true));

    try {
      final classrooms = await _source.classroomNames();
      final guardians = await _source.guardianOptions();
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingOptions: false,
          classrooms: classrooms,
          guardians: guardians,
          draft: state.draft.week.isEmpty
              ? state.draft.copyWith(week: ScheduleEntry.week())
              : state.draft,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isLoadingOptions: false));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  // --- Editing --------------------------------------------------------------

  /// Writes [draft] and, once a step has been tried, re-checks it so an error
  /// clears as soon as it is fixed.
  void edit(StudentDraft draft) {
    final errors = state.hasTriedStep
        ? _validator.forStep(state.step, draft)
        : state.errors;
    emit(state.copyWith(draft: draft, errors: errors));
  }

  /// Every day gets step three's first row's times.
  void copyTimesToAllDays() {
    final week = state.draft.week;
    if (week.isEmpty) return;
    final first = week.first;
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          week: <ScheduleEntry>[
            for (final day in week)
              day.copyWith(
                startMinutes: first.startMinutes,
                endMinutes: first.endMinutes,
              ),
          ],
        ),
      ),
    );
  }

  // --- Moving between steps -------------------------------------------------

  /// Back to a step already passed. Going forward is [next]'s job, so a step
  /// is never skipped past its own validation.
  void goToStep(int step) {
    if (step >= state.step || step < 1) return;
    emit(state.copyWith(step: step, hasTriedStep: false, errors: _noErrors));
  }

  void back() => goToStep(state.step - 1);

  /// The pink key. Step one checks for siblings before it lets go; the last
  /// step saves.
  Future<void> next() async {
    final errors = _validator.forStep(state.step, state.draft);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors, hasTriedStep: true));
      return;
    }

    if (state.step == 1 && !state.hasCheckedSiblings) {
      await _checkSiblings();
      if (state.siblings.isNotEmpty) return;
    }
    if (state.step == _lastStep) {
      await save();
      return;
    }
    _advance();
  }

  /// The optional steps' quiet second key.
  Future<void> skip() async {
    if (state.step == _lastStep) {
      await save();
      return;
    }
    _advance();
  }

  void _advance() => emit(
    state.copyWith(
      step: state.step + 1,
      hasTriedStep: false,
      errors: _noErrors,
    ),
  );

  // --- Siblings -------------------------------------------------------------

  /// Students already enrolled with the same last name are offered before
  /// the record is written, which is the only moment linking them is cheap.
  Future<void> _checkSiblings() async {
    emit(state.copyWith(isCheckingSiblings: true));
    try {
      final matches = await _source.siblingsNamed(state.draft.lastName);
      if (isClosed) return;
      emit(
        state.copyWith(
          isCheckingSiblings: false,
          hasCheckedSiblings: true,
          siblings: matches,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(isCheckingSiblings: false, hasCheckedSiblings: true),
        );
      }
    }
  }

  void linkSibling(StudentSummary sibling) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          siblingId: sibling.id,
          siblingLabel: '${sibling.fullName} · ${sibling.classroomName}',
        ),
        siblings: const <StudentSummary>[],
      ),
    );
    _advance();
  }

  void dismissSiblings() {
    emit(state.copyWith(siblings: const <StudentSummary>[]));
    _advance();
  }

  // --- Saving ---------------------------------------------------------------

  Future<void> save() async {
    if (state.status == AddStudentStatus.saving) return;
    final errors = _validator.forStep(1, state.draft);
    if (errors.isNotEmpty) {
      emit(state.copyWith(step: 1, errors: errors, hasTriedStep: true));
      return;
    }

    emit(state.copyWith(status: AddStudentStatus.saving));
    try {
      final saved = await _source.createStudent(state.draft);
      if (isClosed) return;
      emit(state.copyWith(status: AddStudentStatus.saved, saved: saved));
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: AddStudentStatus.failed));
    }
  }

  /// The screen has shown the failure, so the key goes back to Save.
  void clearFailure() => emit(state.copyWith(status: AddStudentStatus.editing));

  static const int _lastStep = 3;
  static const Map<StudentField, String> _noErrors = <StudentField, String>{};
}
