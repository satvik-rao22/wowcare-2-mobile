import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/domain/features/student/usecases/change_guardian_pin_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/generate_guardian_pin_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_guardians_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/resend_guardian_invite_usecase.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

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
    required ResendGuardianInviteUseCase resendGuardianInviteUseCase,
    required ChangeGuardianPinUseCase changeGuardianPinUseCase,
    required GenerateGuardianPinUseCase generateGuardianPinUseCase,
    required StorageService storageService,
  }) : _getStudentGuardiansUseCase = getStudentGuardiansUseCase,
       _deleteGuardianUseCase = deleteGuardianUseCase,
       _resendGuardianInviteUseCase = resendGuardianInviteUseCase,
       _changeGuardianPinUseCase = changeGuardianPinUseCase,
       _generateGuardianPinUseCase = generateGuardianPinUseCase,
       _storageService = storageService,
       super(const StudentGuardianState.initial());

  final GetStudentGuardiansUseCase _getStudentGuardiansUseCase;
  final DeleteGuardianUseCase _deleteGuardianUseCase;
  final ResendGuardianInviteUseCase _resendGuardianInviteUseCase;
  final ChangeGuardianPinUseCase _changeGuardianPinUseCase;
  final GenerateGuardianPinUseCase _generateGuardianPinUseCase;
  final StorageService _storageService;

  /// State-based load of a student's guardians — the card renders
  /// `state.guardians` via BlocBuilder instead of driving its own FutureBuilder.
  Future<void> load(String studentCode, {bool forceRefresh = false}) async {
    if (studentCode.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            guardians: const <StudentGuardian>[],
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
      final guardians = await _getStudentGuardiansUseCase(
        studentCode: studentCode,
        forceRefresh: forceRefresh,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          guardians: guardians,
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

  Future<String> delete({required String code, required String studentCode}) {
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

  /// Thrown when the active org/school context can't be resolved from storage,
  /// so the caller can surface the same guidance it always has.
  static const String missingSchoolContextMessage =
      'Organization is missing. Re-select your school from the menu and try again.';

  /// Resolves the active org + school codes from storage.
  ///
  /// Lives here rather than in the view: Mandate 5 forbids `StorageService`
  /// under `lib/presentation`'s view layer, and the invite payload needs both.
  /// [fallbackSchoolCode] is the school the host screen was opened with, which
  /// wins over the stored value when present.
  Future<({String organizationCode, String schoolCode})>
  _resolveSchoolContext(String fallbackSchoolCode) async {
    final organizationCode =
        (await _storageService.getString(StorageKeys.organizationCode) ?? '')
            .trim();
    var schoolCode = fallbackSchoolCode.trim();
    if (schoolCode.isEmpty) {
      schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    }
    return (organizationCode: organizationCode, schoolCode: schoolCode);
  }

  /// Re-sends the app invite to ONE guardian, identified by their own
  /// [userCode] + [invitedEmail]. Single-flighted per user code so a double tap
  /// cannot send two emails.
  ///
  /// Resolves the org/school context itself; [schoolCode] is the host screen's
  /// school, used in preference to the stored one when non-empty.
  ///
  /// Returns the server's message; throws on failure (including a 200 with
  /// `success: false`) for the caller to surface via [ApiErrorHandler].
  Future<String> resendInvite({
    required String invitedEmail,
    required String userCode,
    String schoolCode = '',
  }) {
    return _singleFlight<String>('resendInvite:$userCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        final context = await _resolveSchoolContext(schoolCode);
        if (context.organizationCode.isEmpty || context.schoolCode.isEmpty) {
          throw Exception(missingSchoolContextMessage);
        }
        return await _resendGuardianInviteUseCase(
          invitedEmail: invitedEmail,
          userCode: userCode,
          organizationCode: context.organizationCode,
          schoolCode: context.schoolCode,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  /// Sets ONE guardian's clock PIN to the operator-entered [pin].
  ///
  /// Returns `(message, newClockPin)`; throws on failure. The repository drops
  /// the cached guardian list, so a subsequent [load] shows the new PIN.
  Future<({String message, String newClockPin})> changePin({
    required String guardianCode,
    required String pin,
    required String studentCode,
  }) {
    return _singleFlight<({String message, String newClockPin})>(
      'changePin:$guardianCode',
      () async {
        if (!isClosed) emit(state.copyWith(mutationInProgress: true));
        try {
          return await _changeGuardianPinUseCase(
            guardianCode: guardianCode,
            pin: pin,
            studentCode: studentCode,
          );
        } finally {
          if (!isClosed) emit(state.copyWith(mutationInProgress: false));
        }
      },
    );
  }

  /// Asks the server to generate a fresh clock PIN for ONE guardian.
  ///
  /// Shares the `changePin:` single-flight key with [changePin] — both mutate
  /// the same PIN, so they must never run concurrently for one guardian.
  Future<({String message, String newClockPin})> generatePin({
    required String guardianCode,
    required String studentCode,
  }) {
    return _singleFlight<({String message, String newClockPin})>(
      'changePin:$guardianCode',
      () async {
        if (!isClosed) emit(state.copyWith(mutationInProgress: true));
        try {
          return await _generateGuardianPinUseCase(
            guardianCode: guardianCode,
            studentCode: studentCode,
          );
        } finally {
          if (!isClosed) emit(state.copyWith(mutationInProgress: false));
        }
      },
    );
  }
}
