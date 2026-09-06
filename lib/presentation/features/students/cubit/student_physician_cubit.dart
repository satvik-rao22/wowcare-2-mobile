import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import 'package:wowcare/domain/features/student/entities/student_physician.dart';
import 'package:wowcare/domain/features/student/usecases/add_physician_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_physician_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_physicians_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_physician_usecase.dart';

part 'student_physician_state.dart';

/// Read + mutations for a student's physician contacts.
///
/// Screens route every physician read/write through this cubit → use case →
/// repository so no view depends on [StudentRepository] directly.
class StudentPhysicianCubit extends Cubit<StudentPhysicianState> {
  StudentPhysicianCubit({
    required GetStudentPhysiciansUseCase getStudentPhysiciansUseCase,
    required AddPhysicianUseCase addPhysicianUseCase,
    required UpdatePhysicianUseCase updatePhysicianUseCase,
    required DeletePhysicianUseCase deletePhysicianUseCase,
  })  : _getStudentPhysiciansUseCase = getStudentPhysiciansUseCase,
        _addPhysicianUseCase = addPhysicianUseCase,
        _updatePhysicianUseCase = updatePhysicianUseCase,
        _deletePhysicianUseCase = deletePhysicianUseCase,
        super(const StudentPhysicianState.initial());

  final GetStudentPhysiciansUseCase _getStudentPhysiciansUseCase;
  final AddPhysicianUseCase _addPhysicianUseCase;
  final UpdatePhysicianUseCase _updatePhysicianUseCase;
  final DeletePhysicianUseCase _deletePhysicianUseCase;

  /// State-based load of a student's physicians. Empty [studentCode] resolves
  /// to an empty list without hitting the use case.
  Future<void> load(String studentCode) async {
    if (studentCode.isEmpty) {
      if (isClosed) return;
      emit(
        state.copyWith(
          physicians: const <StudentPhysician>[],
          isLoading: false,
          errorMessage: null,
        ),
      );
      return;
    }

    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final physicians = await _getStudentPhysiciansUseCase(
        studentCode: studentCode,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          physicians: physicians,
          isLoading: false,
          errorMessage: null,
        ),
      );
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

  /// Thin Future-based read for callers that still drive their own
  /// `FutureBuilder` (e.g. the physician tab card) — same data SOURCE as
  /// [load], without the state machine.
  Future<List<StudentPhysician>> fetchPhysicians(
    String studentCode, {
    bool forceRefresh = false,
  }) {
    if (studentCode.isEmpty) {
      return Future.value(const <StudentPhysician>[]);
    }
    return _getStudentPhysiciansUseCase(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }

  /// In-flight mutations keyed by `action:code`. A second identical call while
  /// the first is still running returns the SAME future instead of issuing a
  /// duplicate request — single-flight independent of any UI button-disabling.
  final Map<String, Future<Object?>> _inFlightMutations = {};

  Future<T> _singleFlightMutation<T>(
    String key,
    Future<T> Function() operation,
  ) {
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

  Future<StudentPhysician> add({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) {
    return _singleFlightMutation<StudentPhysician>('add:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _addPhysicianUseCase(
          schoolCode: schoolCode,
          studentCode: studentCode,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          address: address,
          specialty: specialty,
          notes: notes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<StudentPhysician> update({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) {
    return _singleFlightMutation<StudentPhysician>('update:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updatePhysicianUseCase(
          code: code,
          studentCode: studentCode,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          address: address,
          specialty: specialty,
          notes: notes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> delete({
    required String code,
    required String studentCode,
  }) {
    return _singleFlightMutation<String>('delete:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        final message = await _deletePhysicianUseCase(
          code: code,
          studentCode: studentCode,
        );
        await load(studentCode);
        return message;
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
