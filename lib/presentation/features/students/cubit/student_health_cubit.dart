import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/student/entities/student_health.dart';
import '../../../../domain/features/student/entities/student_health_update_request.dart';
import '../../../../domain/features/student/entities/student_immunization.dart';
import '../../../../domain/features/student/usecases/get_student_health_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_immunizations_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_health_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_immunization_record_usecase.dart';

part 'student_health_state.dart';

/// Reads + mutations for a student's health details and immunization records.
///
/// Screens route every health/immunization read/write through this cubit → use
/// case → repository so no view depends on [StudentRepository] directly. Reads
/// stay Future-based (the views keep their own `FutureBuilder`s), so the cubit
/// does not hold the lists — it only tracks mutation progress / errors.
class StudentHealthCubit extends Cubit<StudentHealthState> {
  StudentHealthCubit({
    required GetStudentHealthUseCase getStudentHealthUseCase,
    required UpdateStudentHealthUseCase updateStudentHealthUseCase,
    required GetStudentImmunizationsUseCase getStudentImmunizationsUseCase,
    required UpdateStudentImmunizationRecordUseCase
        updateStudentImmunizationRecordUseCase,
  })  : _getStudentHealthUseCase = getStudentHealthUseCase,
        _updateStudentHealthUseCase = updateStudentHealthUseCase,
        _getStudentImmunizationsUseCase = getStudentImmunizationsUseCase,
        _updateStudentImmunizationRecordUseCase =
            updateStudentImmunizationRecordUseCase,
        super(const StudentHealthState.initial());

  final GetStudentHealthUseCase _getStudentHealthUseCase;
  final UpdateStudentHealthUseCase _updateStudentHealthUseCase;
  final GetStudentImmunizationsUseCase _getStudentImmunizationsUseCase;
  final UpdateStudentImmunizationRecordUseCase
      _updateStudentImmunizationRecordUseCase;

  /// Thin Future-based read for callers that drive their own `FutureBuilder`.
  Future<StudentHealth> fetchHealth(String studentCode) {
    return _getStudentHealthUseCase(studentCode: studentCode);
  }

  /// Thin Future-based read for callers that drive their own `FutureBuilder`.
  Future<List<StudentImmunization>> fetchImmunizations(
    String studentCode, {
    bool forceRefresh = false,
  }) {
    return _getStudentImmunizationsUseCase(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
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

  Future<StudentHealth> updateHealth({
    required String studentCode,
    required StudentHealthUpdateRequest request,
  }) {
    return _singleFlight<StudentHealth>('health:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentHealthUseCase(
          studentCode: studentCode,
          request: request,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<StudentImmunization> updateImmunization({
    required String studentCode,
    required StudentImmunization record,
    required DateTime date,
    required String status,
    String? exemptionReason,
  }) {
    return _singleFlight<StudentImmunization>('immun:${record.code}', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentImmunizationRecordUseCase(
          studentCode: studentCode,
          record: record,
          date: date,
          status: status,
          exemptionReason: exemptionReason,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
