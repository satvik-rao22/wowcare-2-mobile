import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/student/entities/student_physical_exam.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_physical_exam_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_physical_exams_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_physical_exam_usecase.dart';

import 'package:wowcare/core/utils/api_error_handler.dart';

part 'student_physical_exam_state.dart';

/// Reads + mutations for a student's physical exam records.
///
/// Screens route every physical-exam read/write through this cubit → use case →
/// repository so no view depends on [StudentRepository] directly. Reads stay
/// Future-based (the views keep their own `FutureBuilder`s), so the cubit does
/// not hold the list — it only tracks mutation progress / errors.
class StudentPhysicalExamCubit extends Cubit<StudentPhysicalExamState> {
  StudentPhysicalExamCubit({
    required GetStudentPhysicalExamsUseCase getStudentPhysicalExamsUseCase,
    required AddStudentPhysicalExamUseCase addStudentPhysicalExamUseCase,
    required UpdateStudentPhysicalExamUseCase updateStudentPhysicalExamUseCase,
  }) : _getStudentPhysicalExamsUseCase = getStudentPhysicalExamsUseCase,
       _addStudentPhysicalExamUseCase = addStudentPhysicalExamUseCase,
       _updateStudentPhysicalExamUseCase = updateStudentPhysicalExamUseCase,
       super(const StudentPhysicalExamState.initial());

  final GetStudentPhysicalExamsUseCase _getStudentPhysicalExamsUseCase;
  final AddStudentPhysicalExamUseCase _addStudentPhysicalExamUseCase;
  final UpdateStudentPhysicalExamUseCase _updateStudentPhysicalExamUseCase;

  /// State-based load of a student's physical exams — the card renders
  /// `state.exams` via BlocBuilder instead of driving its own FutureBuilder.
  Future<void> load(String studentCode, {bool forceRefresh = false}) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final exams = await _getStudentPhysicalExamsUseCase(
        studentCode: studentCode,
        forceRefresh: forceRefresh,
      );
      if (isClosed) return;
      emit(state.copyWith(exams: exams, isLoading: false, errorMessage: null));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Thin Future-based read for callers that drive their own `FutureBuilder`.
  Future<List<StudentPhysicalExam>> fetchPhysicalExams(
    String studentCode, {
    bool forceRefresh = false,
  }) {
    return _getStudentPhysicalExamsUseCase(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }

  /// Seed the add/edit form model from the caller's initial values (called from
  /// the editor's initState). Owns the two fields so the view drops its copies.
  void initializeForm({DateTime? examDate, String? status}) {
    emit(state.copyWith(formExamDate: examDate, formStatus: status));
  }

  void setFormExamDate(DateTime? date) {
    emit(state.copyWith(formExamDate: date));
  }

  void setFormStatus(String? status) {
    emit(state.copyWith(formStatus: status));
  }

  /// In-flight mutations keyed by `action:id`. A second identical call while
  /// the first is still running returns the SAME future instead of issuing a
  /// duplicate request — single-flight independent of any UI button-disabling.
  final Map<String, Future<Object?>> _inFlightMutations = {};

  Future<T> _singleFlight<T>(String key, Future<T> Function() operation) {
    final existing = _inFlightMutations[key];
    if (existing != null) return existing as Future<T>;
    final future = operation();
    _inFlightMutations[key] = future;
    // Clear the in-flight entry on completion. `whenComplete` returns a new
    // future that mirrors any error; ignore it so a rethrown mutation error
    // surfaces only through the caller's `future` and isn't double-reported as
    // an unhandled async error.
    future.whenComplete(() => _inFlightMutations.remove(key)).ignore();
    return future;
  }

  Future<StudentPhysicalExam> add({
    required String studentCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) {
    return _singleFlight<StudentPhysicalExam>('addExam:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _addStudentPhysicalExamUseCase(
          studentCode: studentCode,
          examDate: examDate,
          status: status,
          notes: notes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<StudentPhysicalExam> update({
    required String studentCode,
    required String examCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) {
    return _singleFlight<StudentPhysicalExam>('updateExam:$examCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentPhysicalExamUseCase(
          studentCode: studentCode,
          examCode: examCode,
          examDate: examDate,
          status: status,
          notes: notes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
