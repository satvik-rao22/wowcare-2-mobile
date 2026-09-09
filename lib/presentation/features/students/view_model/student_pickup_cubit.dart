import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/student/entities/school_guardian_summary.dart';
import 'package:wowcare/domain/features/student/entities/student_pickup.dart';
import 'package:wowcare/domain/features/student/usecases/add_pickup_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_pickup_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardians_raw_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_pickups_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_pickup_usecase.dart';

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
  }) : _getStudentPickupsUseCase = getStudentPickupsUseCase,
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

  /// State-based load of a student's pickups — the card renders `state.pickups`
  /// via BlocBuilder instead of driving its own FutureBuilder.
  Future<void> load(String studentCode, {bool forceRefresh = false}) async {
    if (studentCode.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            pickups: const <StudentPickup>[],
            isLoading: false,
            errorMessage: null,
          ),
        );
      }
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final pickups = await _getStudentPickupsUseCase(
        studentCode: studentCode,
        forceRefresh: forceRefresh,
      );
      if (isClosed) return;
      emit(
        state.copyWith(pickups: pickups, isLoading: false, errorMessage: null),
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
  Future<List<SchoolGuardianSummary>> fetchGuardiansRaw(String schoolCode) {
    return _getGuardiansRawForSchoolUseCase(schoolCode: schoolCode);
  }

  // --- add-pickup form model ---

  /// Seed the form (edit/prefill mode toggles off "select from existing" and
  /// carries the incoming relation).
  void initializeForm({bool? selectFromExisting, String? selectedRelation}) {
    emit(
      state.copyWith(
        selectFromExisting: selectFromExisting,
        selectedRelation: selectedRelation,
      ),
    );
  }

  void setSelectFromExisting(bool value) {
    emit(state.copyWith(selectFromExisting: value));
  }

  void setSelectedCarer(String? carer) {
    emit(state.copyWith(selectedCarer: carer));
  }

  void setSelectedRelation(String? relation) {
    emit(state.copyWith(selectedRelation: relation));
  }

  /// Load the "select from existing" carer list. The display [names] come from
  /// the caller (same guardian-names API the filters use); this fetches the raw
  /// guardians to build the name→details lookup, and drops a stale selection.
  /// Non-fatal: on error the list stays empty (pickups still work manually).
  Future<void> loadCarers({
    required String schoolCode,
    required List<String> names,
  }) async {
    try {
      final rawGuardians = await _getGuardiansRawForSchoolUseCase(
        schoolCode: schoolCode,
      );
      final details = <String, Map<String, String>>{};
      for (final g in rawGuardians) {
        final display = g.fullName;
        if (display.isEmpty) continue;
        details[display] = <String, String>{
          'code': g.code,
          'firstName': g.firstName,
          'lastName': g.lastName,
          'email': g.email,
          'mobile': g.mobile,
        };
      }
      if (isClosed) return;
      final selected = state.selectedCarer;
      emit(
        state.copyWith(
          existingCarers: names,
          guardianDetailsByName: details,
          selectedCarer: (selected != null && !names.contains(selected))
              ? null
              : selected,
        ),
      );
    } catch (_) {
      // Non-critical for pickups; keep the list empty on error.
    }
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

  Future<String> delete({required String code, required String studentCode}) {
    return _singleFlight<String>('deletePickup:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _deletePickupUseCase(code: code, studentCode: studentCode);
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
