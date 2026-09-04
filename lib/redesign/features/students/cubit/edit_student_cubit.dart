import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';
import 'package:wowcare/redesign/features/students/validation/student_validator.dart';

part 'edit_student_state.dart';

/// 5e. Fixing a record that is already on the roster.
///
/// The form opens on the record as it stands and validates on the first
/// attempt to save, which is the state the frame draws: an empty first name
/// and a birth date in the future, both named, with Save turned off until
/// they are dealt with.
class EditStudentCubit extends Cubit<EditStudentState> {
  EditStudentCubit({
    required StudentsSource source,
    required String studentId,
    required DateTime today,
  }) : _source = source,
       _validator = StudentValidator(today: today),
       super(EditStudentState(studentId: studentId));

  final StudentsSource _source;
  final StudentValidator _validator;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: EditStudentStatus.loading));

    try {
      final record = await _source.loadProfile(state.studentId);
      final classrooms = await _source.classroomNames();
      final tags = await _source.tagNames();
      if (isClosed) return;

      final student = record.student;
      emit(
        state.copyWith(
          status: EditStudentStatus.ready,
          classrooms: classrooms,
          tagNames: tags,
          original: student,
          draft: StudentDraft(
            status: student.status,
            firstName: student.firstName,
            lastName: student.lastName,
            classroomName: student.classroomName,
            dateOfBirth: student.dateOfBirth,
            tags: student.tags,
            notes: record.notes,
          ),
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: EditStudentStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// Writes [draft] and, once Save has been tried, re-checks it so a message
  /// clears the moment the field is right.
  void edit(StudentDraft draft) {
    final errors = state.hasTriedSave
        ? _validator.details(draft)
        : state.errors;
    emit(state.copyWith(draft: draft, errors: errors));
  }

  Future<void> save() async {
    if (state.isSaving) return;
    final errors = _validator.details(state.draft);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors, hasTriedSave: true));
      return;
    }

    emit(state.copyWith(status: EditStudentStatus.saving));
    try {
      final saved = await _source.updateStudent(
        id: state.studentId,
        draft: state.draft,
      );
      if (isClosed) return;
      emit(state.copyWith(status: EditStudentStatus.saved, original: saved));
    } on Exception catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(status: EditStudentStatus.ready, hasSaveFailed: true),
        );
      }
    }
  }

  /// The screen has shown the failure, so the next attempt starts clean.
  void clearFailure() => emit(state.copyWith(hasSaveFailed: false));
}
