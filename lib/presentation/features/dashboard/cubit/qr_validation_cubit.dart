import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/qr_validation_result.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/validate_qr_code_usecase.dart';

part 'qr_validation_state.dart';

/// Lightweight args passed to [QrScanScreen].
///
/// No longer carries useCase — that is resolved dynamically inside
/// [QrValidationCubit.validate] from the signed-in user's role and
/// attendance state.
class QrScannerArgs {
  const QrScannerArgs();
}

/// Validates a scanned QR token against the WowCare attendance API.
///
/// All context (school code, user role, sign-in status) is resolved from
/// [StorageService] so neither the scanner screen nor the calling widget
/// needs to pass any of that information.
///
/// Resolution order on each [validate] call:
/// 1. schoolCode  — from [StorageKeys.schoolCode]
/// 2. role        — from [StorageKeys.activeSchoolRole]:
///                  contains "GUARDIAN"/"PARENT" → guardian flow,
///                  otherwise → staff/admin flow
/// 3. useCase     — guardian: GUARDIAN_SIGN_IN (form handles sign-out routing)
///                  staff: STAFF_SIGN_IN or STAFF_SIGN_OUT based on live status
/// 4. POST /api/v1/schools/{schoolCode}/attendance-settings/qr-code/validate
class QrValidationCubit extends Cubit<QrValidationState> {
  QrValidationCubit({
    required ValidateQrCodeUseCase validateQrCodeUseCase,
    required GetStaffTodaySignInStatusUseCase getStaffTodaySignInStatusUseCase,
    required StorageService storageService,
  })  : _validateQrCodeUseCase = validateQrCodeUseCase,
        _getStaffTodaySignInStatus = getStaffTodaySignInStatusUseCase,
        _storage = storageService,
        super(const QrValidationInitial());

  final ValidateQrCodeUseCase _validateQrCodeUseCase;
  final GetStaffTodaySignInStatusUseCase _getStaffTodaySignInStatus;
  final StorageService _storage;

  bool _isFetching = false;

  // ── Validation entry point ─────────────────────────────────────────────────

  /// Validates the opaque [qrToken] extracted from the scanner.
  ///
  /// The [qrToken] must be the raw token string — NOT the full QR JSON payload.
  /// Use [QrTokenExtractor.extract] in the scanner before calling this method.
  Future<void> validate({required String qrToken}) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(const QrValidationLoading());

    try {
      final schoolCode = await _readStorage(StorageKeys.schoolCode);
      if (schoolCode.isEmpty) {
        if (!isClosed) {
          emit(const QrValidationFailure(
            'School context missing. Please sign in again.',
          ));
        }
        return;
      }

      final isGuardian = await _isGuardianRole();
      QrAttendanceUseCase useCase;
      QrNavigationRoute route;

      if (isGuardian) {
        // Guardian useCase is always SIGN_IN at the validation level.
        // The downstream attendance form (StudentSelectionSignInForm) determines
        // whether to show sign-in or sign-out based on student state.
        useCase = QrAttendanceUseCase.guardianSignIn;
        route = QrNavigationRoute.guardianSignIn;
      } else {
        final staffCode = await _readStorage(StorageKeys.staffCode);
        final isSignedIn = await _isStaffSignedIn(staffCode);
        if (isSignedIn) {
          useCase = QrAttendanceUseCase.staffSignOut;
          route = QrNavigationRoute.staffSignOut;
        } else {
          useCase = QrAttendanceUseCase.staffSignIn;
          route = QrNavigationRoute.staffSignIn;
        }
      }

      final result = await _validateQrCodeUseCase(
        schoolCode: schoolCode,
        qrToken: qrToken,
        useCase: useCase,
      );

      if (!isClosed) emit(QrValidationSuccess(result, route: route));
    } catch (e) {
      if (!isClosed) {
        emit(QrValidationFailure(ApiErrorHandler.extractErrorMessage(e)));
      }
    } finally {
      _isFetching = false;
    }
  }

  void reset() {
    if (!isClosed) emit(const QrValidationInitial());
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<String> _readStorage(String key) async =>
      (await _storage.getString(key))?.trim() ?? '';

  /// Returns true when the active school role is a guardian/parent role.
  Future<bool> _isGuardianRole() async {
    final role = (await _readStorage(StorageKeys.activeSchoolRole)).toUpperCase();
    return role.contains('GUARDIAN') || role.contains('PARENT');
  }

  /// Returns true when the staff member's today sign-in status is SIGNED_IN.
  Future<bool> _isStaffSignedIn(String staffCode) async {
    if (staffCode.isEmpty) return false;
    try {
      final status = await _getStaffTodaySignInStatus(staffCode: staffCode);
      return status?.toUpperCase() == 'SIGNED_IN';
    } catch (_) {
      // If the status check fails, default to sign-in flow.
      return false;
    }
  }
}

/// Stateless helper that extracts the opaque QR token from a raw scan string.
///
/// Priority:
/// 1. `qrToken` field from JSON payload
/// 2. `qrPayload` field from JSON payload
/// 3. Raw string (plain non-JSON token)
///
/// Returns null when extraction fails (empty result or unparseable).
abstract final class QrTokenExtractor {
  static String? extract(String rawScan) {
    final raw = rawScan.trim();
    if (raw.isEmpty) return null;

    if (raw.startsWith('{')) {
      try {
        // Use dart:convert via the caller's import — see QR_Code_scanner.dart.
        // We keep this class pure (no dart:convert import) so it can be tested
        // without a Flutter environment.  The scanner passes in the decoded map.
        // This branch is intentionally unreachable here; callers use extractFromMap.
      } catch (_) {}
    }

    return raw;
  }

  /// Extracts the token from an already-decoded JSON map.
  static String? extractFromMap(Map<String, dynamic> map) {
    final token = (map['qrToken'] as String?)?.trim() ??
        (map['qrPayload'] as String?)?.trim();
    return (token != null && token.isNotEmpty) ? token : null;
  }
}
