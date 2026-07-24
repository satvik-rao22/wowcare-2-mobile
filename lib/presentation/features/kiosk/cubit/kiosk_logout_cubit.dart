import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/kiosk/usecases/verify_kiosk_pin_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';

part 'kiosk_logout_state.dart';

class KioskLogoutCubit extends Cubit<KioskLogoutState> {
  KioskLogoutCubit({
    required AuthCubit authCubit,
    required VerifyKioskPinUseCase verifyKioskPinUseCase,
    required StorageService storageService,
    required KioskAccessControl kioskAccessControl,
  })  : _authCubit = authCubit,
        _verifyKioskPin = verifyKioskPinUseCase,
        _storage = storageService,
        _kioskAccessControl = kioskAccessControl,
        super(const KioskLogoutInitial());

  final AuthCubit _authCubit;
  final VerifyKioskPinUseCase _verifyKioskPin;
  final StorageService _storage;
  final KioskAccessControl _kioskAccessControl;

  /// Logout the kiosk user by verifying their PIN with isLogout=true flag
  /// This calls the same API as kiosk dashboard PIN verification but with
  /// isLogout=true to indicate this is a logout confirmation.
  /// User role is KIOSK.
  ///
  /// The flow ensures that kiosk mode is properly deactivated even if API calls fail,
  /// so the user can retry logout on subsequent attempts.
  Future<bool> logout({required String pin}) async {
    emit(const KioskLogoutLoading());

    try {
      AppLogger.d(
        '[Kiosk Logout] Starting logout process with isLogout=true, pinLength=${pin.length}',
      );

      // Get the school code from storage (set during kiosk login)
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);
      if (schoolCode == null || schoolCode.isEmpty) {
        AppLogger.w('[Kiosk Logout] School code not found in storage, but will attempt logout anyway');
        // Don't fail here - allow logout to proceed with empty schoolCode
        // The API might still process this for the current session
      }

      // Call verify-pin API with isLogout=true
      // This sends: {"pin": <pin>, "isLogout": true} with X-School-Code header
      // API will process this as logout confirmation for KIOSK user
      try {
        await _verifyKioskPin(
          pin: pin,
          schoolCode: schoolCode ?? '',
          isLogout: true,
        );
        AppLogger.d('[Kiosk Logout] Logout API call successful');
      } catch (apiError) {
        // API must succeed before we clear the local session - otherwise the
        // kiosk device would be logged out locally while the backend still
        // thinks the session is active.
        AppLogger.w('[Kiosk Logout] Logout API call failed: $apiError');
        if (isClosed) return false;
        emit(KioskLogoutError(ApiErrorHandler.extractErrorMessage(apiError)));
        return false;
      }

      if (isClosed) return true;

      AppLogger.d('[Kiosk Logout] Clearing session and deactivating kiosk mode');

      // Clear the session - this ensures tokens and auth state are wiped
      try {
        await _authCubit.logoutSession();
        AppLogger.d('[Kiosk Logout] Session cleared successfully');
      } catch (sessionError) {
        AppLogger.w('[Kiosk Logout] Session clear had error (non-fatal): $sessionError');
        // Continue anyway - we still need to deactivate kiosk mode
      }

      if (isClosed) return true;

      // Deactivate kiosk mode (clears kiosk_mode_active flag and in-memory cache)
      // This is CRITICAL so the router's redirect doesn't block navigation to /sign-in
      // Must happen even if API or session clear fails
      try {
        await _kioskAccessControl.deactivateKioskMode();
        AppLogger.d('[Kiosk Logout] Kiosk mode deactivated successfully');
      } catch (kioskError) {
        AppLogger.w('[Kiosk Logout] Kiosk deactivation had error: $kioskError');
        // Try to force-clear the cache synchronously as fallback
        try {
          KioskAccessControl.clearCacheForNonKioskLogin();
          AppLogger.d('[Kiosk Logout] Forced kiosk cache clear (fallback)');
        } catch (_) {}
      }

      if (isClosed) return true;

      AppLogger.d('[Kiosk Logout] Logout completed successfully');
      emit(const KioskLogoutSuccess());
      return true;
    } catch (e) {
      if (isClosed) return false;

      AppLogger.e('[Kiosk Logout] Unexpected error during logout: $e');

      // Even on unexpected error, try to deactivate kiosk mode to allow retry
      try {
        await _kioskAccessControl.deactivateKioskMode();
      } catch (_) {
        try {
          KioskAccessControl.clearCacheForNonKioskLogin();
        } catch (_) {}
      }

      emit(KioskLogoutError('Logout failed: ${e.toString()}'));
      return false;
    }
  }
}
