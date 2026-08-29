import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/student/entities/student_pickup.dart';
import '../../../../domain/features/student/usecases/add_pickup_usecase.dart';
import '../../../../domain/features/student/usecases/delete_pickup_usecase.dart';
import '../../../../domain/features/student/usecases/get_guardians_raw_for_school_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_pickups_usecase.dart';
import '../../../../domain/features/student/usecases/update_pickup_usecase.dart';

part 'student_pickup_state.dart';

/// Reads + mutations for a student's pickup contacts.
///
/// Screens route every pickup read/write through this cubit → use case →
/// repository so no view depends on [StudentRepository] directly. Reads stay
/// Future-based (the views keep their own `FutureBuilder`s), so the cubit does
/// not hold the list — it only tracks mutation progress / errors.
class StudentPickupCubit extends Cubit<StudentPickupState> {
  StudentPickupCubit({
    required GetStudentPickupsUseCase getStudentPickupsUseCase,
    required GetGuardiansRawForSchoolUseCase getGuardiansRawForSchoolUseCase,
    required AddPickupUseCase addPickupUseCase,
    required UpdatePickupUseCase updatePickupUseCase,
    required DeletePickupUseCase deletePickupUseCase,
  })  : _getStudentPickupsUseCase = getStudentPickupsUseCase,
        _getGuardiansRawForSchoolUseCase = getGuardiansRawForSchoolUseCase,
        _addPickupUseCase = addPickupUseCase,
        _updatePickupUseCase = updatePickupUseCase,
        _deletePickupUseCase = deletePickupUseCase,
        super(const StudentPickupState.initial());

  final GetStudentPickupsUseCase _getStudentPickupsUseCase;
  final GetGuardiansRawForSchoolUseCase _getGuardiansRawForSchoolUseCase;
  final AddPickupUseCase _addPickupUseCase;
  final UpdatePickupUseCase _updatePickupUseCase;
  final DeletePickupUseCase _deletePickupUseCase;

  /// Thin Future-based read for callers that drive their own `FutureBuilder`.
  Future<List<StudentPickup>> fetchPickups(
    String studentCode, {
    bool forceRefresh = false,
  }) {
    if (studentCode.isEmpty) {
      return Future.value(const <StudentPickup>[]);
    }
    return _getStudentPickupsUseCase(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }

  /// Raw guardians for the add-pickup "select from existing" dropdown.
  Future<List<Map<String, dynamic>>> fetchGuardiansRaw(String schoolCode) {
    return _getGuardiansRawForSchoolUseCase(schoolCode: schoolCode);
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

  Future<String> add({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
  }) {
    return _singleFlight<String>('addPickup:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _addPickupUseCase(
          studentCode: studentCode,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          relation: relation,
          relationshipDescription: relationshipDescription,
          pickupType: pickupType,
          carpoolId: carpoolId,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> update({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? clockPin,
    String? relationshipDescription,
    String? pickupType,
    String? carpoolId,
  }) {
    return _singleFlight<String>('updatePickup:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updatePickupUseCase(
          code: code,
          studentCode: studentCode,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          relation: relation,
          clockPin: clockPin,
          relationshipDescription: relationshipDescription,
          pickupType: pickupType,
          carpoolId: carpoolId,
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
    return _singleFlight<String>('deletePickup:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _deletePickupUseCase(
          code: code,
          studentCode: studentCode,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
