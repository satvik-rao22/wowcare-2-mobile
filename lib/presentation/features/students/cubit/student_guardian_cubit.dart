import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/student/entities/student_guardian.dart';
import '../../../../domain/features/student/usecases/delete_guardian_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_guardians_usecase.dart';

part 'student_guardian_state.dart';

/// Read + delete for a student's guardians/parents.
///
/// Screens route the guardian list read and delete through this cubit → use
/// case → repository so no view depends on [StudentRepository] directly. Reads
/// stay Future-based (the views keep their own `FutureBuilder`s), so the cubit
/// does not hold the list — it only tracks mutation progress / errors.
///
/// NOTE: create/link/update-guardian belong to the CREATE wizard (S3f) and are
/// intentionally out of scope here.
class StudentGuardianCubit extends Cubit<StudentGuardianState> {
  StudentGuardianCubit({
    required GetStudentGuardiansUseCase getStudentGuardiansUseCase,
    required DeleteGuardianUseCase deleteGuardianUseCase,
  })  : _getStudentGuardiansUseCase = getStudentGuardiansUseCase,
        _deleteGuardianUseCase = deleteGuardianUseCase,
        super(const StudentGuardianState.initial());

  final GetStudentGuardiansUseCase _getStudentGuardiansUseCase;
  final DeleteGuardianUseCase _deleteGuardianUseCase;

  /// Thin Future-based read for callers that drive their own `FutureBuilder`.
  Future<List<StudentGuardian>> fetchGuardians(
    String studentCode, {
    bool forceRefresh = false,
  }) {
    if (studentCode.isEmpty) {
      return Future.value(const <StudentGuardian>[]);
    }
    return _getStudentGuardiansUseCase(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }

  /// In-flight mutations keyed by `action:code`. A second identical call while
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

  Future<String> delete({
    required String code,
    required String studentCode,
  }) {
    return _singleFlight<String>('deleteGuardian:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _deleteGuardianUseCase(
          code: code,
          studentCode: studentCode,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
