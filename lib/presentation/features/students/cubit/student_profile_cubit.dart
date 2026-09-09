import 'package:bloc/bloc.dart';
import 'package:wowcare/domain/features/student/entities/student_regular_schedule_input.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/student/entities/student_health.dart';
import 'package:wowcare/domain/features/student/entities/student_settings.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_health_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_settings_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_regular_schedules_usecase.dart';

import 'package:wowcare/core/util/api_error_handler.dart';

part 'student_profile_state.dart';

/// Type-safe reads + the schedule mutation for the student profile screens.
///
/// Screens route the school-settings read, the header health read, and the
/// regular-schedule write through this cubit → use case → repository so no view
/// depends on [StudentRepository] (or the datasource) for these. Reads stay
/// Future-based (the views keep their own `FutureBuilder`s), so the cubit does
/// not hold the values — it only tracks mutation progress / errors.
///
/// The `getStudentProfile` reads remain on the datasource: they need the rich
/// [StudentProfileModel] (status/dob/address/tags/fte/...), while the domain
/// [StudentProfile] entity is a narrow projection — those are documented MVVM
/// holdouts until the entity is enriched (S6 typed-models).
class StudentProfileCubit extends Cubit<StudentProfileState> {
  StudentProfileCubit({
    required GetStudentSettingsUseCase getStudentSettingsUseCase,
    required GetStudentHealthUseCase getStudentHealthUseCase,
    required UpdateStudentRegularSchedulesUseCase
        updateStudentRegularSchedulesUseCase,
  })  : _getStudentSettingsUseCase = getStudentSettingsUseCase,
        _getStudentHealthUseCase = getStudentHealthUseCase,
        _updateStudentRegularSchedulesUseCase =
            updateStudentRegularSchedulesUseCase,
        super(const StudentProfileState.initial());

  final GetStudentSettingsUseCase _getStudentSettingsUseCase;
  final GetStudentHealthUseCase _getStudentHealthUseCase;
  final UpdateStudentRegularSchedulesUseCase
      _updateStudentRegularSchedulesUseCase;

  /// Thin Future-based read for callers that drive their own `FutureBuilder`.
  Future<StudentSettings> fetchSettings(String schoolCode) {
    return _getStudentSettingsUseCase(schoolCode: schoolCode);
  }

  /// Thin Future-based read for callers that drive their own `FutureBuilder`.
  /// State-based load of the header health record — the profile screen renders
  /// `state.health` via BlocBuilder for its allergy/medication/diet/photo icons.
  /// On error the icons simply stay hidden (health stays null), matching the
  /// previous FutureBuilder behaviour.
  Future<void> loadHealth(String studentCode) async {
    if (studentCode.isEmpty) {
      if (!isClosed) emit(state.copyWith(healthLoading: false));
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(healthLoading: true, errorMessage: null));
    try {
      final health = await _getStudentHealthUseCase(studentCode: studentCode);
      if (isClosed) return;
      emit(state.copyWith(health: health, healthLoading: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        healthLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  Future<StudentHealth> fetchHealth(String studentCode) {
    return _getStudentHealthUseCase(studentCode: studentCode);
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

  Future<String> updateRegularSchedules({
    required String schoolCode,
    required String studentCode,
    required List<StudentRegularScheduleInput> schedule,
  }) {
    return _singleFlight<String>('updateSchedule:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentRegularSchedulesUseCase(
          schoolCode: schoolCode,
          studentCode: studentCode,
          schedule: schedule,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
