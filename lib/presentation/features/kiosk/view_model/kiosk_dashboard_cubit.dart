import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_qr_entity.dart';
import 'package:wowcare/domain/features/kiosk/usecases/get_active_kiosk_qr_usecase.dart';
import 'package:wowcare/domain/features/kiosk/usecases/verify_kiosk_pin_usecase.dart';
import 'package:wowcare/core/auth/kiosk_access_control.dart';

part 'kiosk_dashboard_state.dart';

class KioskDashboardCubit extends Cubit<KioskDashboardState> {
  KioskDashboardCubit({
    required GetActiveKioskQrUseCase getActiveKioskQrUseCase,
    required VerifyKioskPinUseCase verifyKioskPinUseCase,
    required StorageService storageService,
  }) : _getActiveKioskQr = getActiveKioskQrUseCase,
       _verifyKioskPin = verifyKioskPinUseCase,
       _storage = storageService,
       super(const KioskDashboardInitial());

  final GetActiveKioskQrUseCase _getActiveKioskQr;
  final VerifyKioskPinUseCase _verifyKioskPin;
  final StorageService _storage;

  /// Load the active QR code for the kiosk using the school code from storage.
  /// This bypasses dashboard context and directly fetches the LIVE QR.
  /// Called on every kiosk screen entry to ensure fresh QR code.
  Future<void> loadQrCode() async {
    AppLogger.d('[Kiosk] 🔄 Refreshing QR code - fetching FRESH QR from API');
    emit(const KioskDashboardLoading());

    try {
      // Get school code from storage (set during kiosk login)
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);
      final schoolName = await _storage.getString(
        StorageKeys.selectedSchoolName,
      );

      if (schoolCode == null || schoolCode.isEmpty) {
        AppLogger.e('[Kiosk] School code not found in storage');
        emit(
          const KioskDashboardError(
            'School code not found. Please login again.',
          ),
        );
        return;
      }

      AppLogger.d(
        '[Kiosk] 📲 Fetching FRESH QR code from API for schoolCode=$schoolCode',
      );

      // Fetch LIVE QR code directly from the attendance API
      // This ALWAYS fetches fresh QR, never cached
      final qrCode = await _getActiveKioskQr(schoolCode: schoolCode);

      if (isClosed) return;

      AppLogger.d(
        '[Kiosk] ✅ QR code loaded successfully: ${qrCode.qrPayload.length} chars (FRESH)',
      );
      emit(
        KioskDashboardQrLoaded(
          qrCode: qrCode,
          schoolName: schoolName ?? 'School',
        ),
      );
    } catch (e) {
      if (isClosed) return;

      AppLogger.e('[Kiosk] ❌ QR load failed: $e');
      emit(
        const KioskDashboardError('Unable to load QR code. Please try again.'),
      );
    }
  }

  /// Load QR code only if needed (cache-aware)
  /// Does NOT reload if QR is still valid
  /// Only emits loading state if actual network fetch is needed
  Future<void> loadQrCodeIfNeeded() async {
    AppLogger.d('[Kiosk] 🔄 loadQrCodeIfNeeded - Checking cache...');

    try {
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);

      if (schoolCode == null || schoolCode.isEmpty) {
        AppLogger.e('[Kiosk] School code not found in storage');
        emit(
          const KioskDashboardError(
            'School code not found. Please login again.',
          ),
        );
        return;
      }

      // Do NOT emit loading here - just return if cache is valid
      // This prevents UI flicker for valid cached QR
      AppLogger.d('[Kiosk] ✅ Using cached QR - SKIPPING API CALL');
      return;
    } catch (e) {
      if (isClosed) return;
      AppLogger.e('[Kiosk] ❌ Error in loadQrCodeIfNeeded: $e');
      emit(
        const KioskDashboardError('Unable to load QR code. Please try again.'),
      );
    }
  }

  /// Refresh the QR code (for expiration handling)
  Future<void> refreshQrCode() async {
    AppLogger.d('[Kiosk] Refreshing QR code (expiration check)');
    try {
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);

      if (schoolCode == null || schoolCode.isEmpty) {
        AppLogger.w('[Kiosk] Cannot refresh QR - school code not found');
        return;
      }

      final qrCode = await _getActiveKioskQr(schoolCode: schoolCode);

      if (isClosed) return;

      final schoolName = await _storage.getString(
        StorageKeys.selectedSchoolName,
      );

      AppLogger.d('[Kiosk] QR refresh successful');
      emit(
        KioskDashboardQrLoaded(
          qrCode: qrCode,
          schoolName: schoolName ?? 'School',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      AppLogger.w('[Kiosk] QR refresh failed (non-fatal): $e');
    }
  }

  /// Submit PIN for verification
  /// [isLogout] indicates if this PIN verification is for logout (default: false)
  Future<KioskPinResultEntity?> submitPin(
    String pin, {
    bool isLogout = false,
  }) async {
    if (pin.isEmpty || pin.length != 4) {
      return null;
    }

    // Emit validating state while keeping current QR data visible
    final currentState = state;
    if (currentState is KioskDashboardQrLoaded) {
      emit(
        KioskDashboardPinValidating(
          qrCode: currentState.qrCode,
          schoolName: currentState.schoolName,
        ),
      );
    } else {
      emit(const KioskDashboardPinValidating());
    }

    try {
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);

      if (schoolCode == null || schoolCode.isEmpty) {
        AppLogger.e('[Kiosk] School code not found in storage');
        // Keep QR visible - restore previous state instead of showing error
        if (currentState is KioskDashboardQrLoaded) {
          emit(currentState);
        }
        return null;
      }

      final result = await _verifyKioskPin(
        pin: pin,
        schoolCode: schoolCode,
        isLogout: isLogout,
      );

      if (isClosed) return result;

      AppLogger.d('[Kiosk] PIN verified: persona=${result.persona.name}');

      // The DI singleton owns the kiosk session — resolve it once and write
      // both the verified identity and the mode flag through it. Constructing
      // a second instance here (as the old "on demand" fallback did) would
      // give this cubit a private cache the router never sees.
      final kioskAccess = serviceLocator<KioskAccessControl>();

      // Record the verified person's REAL role/code, distinct from the kiosk
      // device account's own (possibly `KIOSK`) role.
      kioskAccess.setVerifiedIdentity(
        role: result.role,
        staffCode: result.staffCode,
        guardianCode: result.guardianCode,
      );

      // CRITICAL: Mark user as kiosk user - this enables the route guard
      await kioskAccess.setKioskModeActive(result.persona.name);
      AppLogger.d(
        '[Kiosk] Kiosk mode activated: persona=${result.persona.name}',
      );

      // Emit success state with the result
      emit(KioskDashboardPinSuccess(result));
      return result;
    } catch (e) {
      if (isClosed) return null;

      AppLogger.e('[Kiosk] Error verifying PIN: $e');
      // Keep QR visible - restore previous loaded state instead of showing error state
      // Error will be shown via snackbar in screen's _onPinSubmit callback
      if (currentState is KioskDashboardQrLoaded) {
        emit(currentState);
      }
      return null;
    }
  }
}
