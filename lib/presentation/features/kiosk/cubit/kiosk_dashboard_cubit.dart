import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_qr_entity.dart';
import 'package:wowcare/domain/features/kiosk/usecases/get_active_kiosk_qr_usecase.dart';

part 'kiosk_dashboard_state.dart';

class KioskDashboardCubit extends Cubit<KioskDashboardState> {
  KioskDashboardCubit({
    required GetActiveKioskQrUseCase getActiveKioskQrUseCase,
    required StorageService storageService,
  })  : _getActiveKioskQr = getActiveKioskQrUseCase,
        _storage = storageService,
        super(const KioskDashboardInitial());

  final GetActiveKioskQrUseCase _getActiveKioskQr;
  final StorageService _storage;

  /// Load the active QR code for the kiosk using the school code from storage.
  /// This bypasses dashboard context and directly fetches the live QR.
  Future<void> loadQrCode() async {
    emit(const KioskDashboardLoading());

    try {
      // Get school code from storage (set during kiosk login)
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);
      final schoolName = await _storage.getString(StorageKeys.selectedSchoolName);

      if (schoolCode == null || schoolCode.isEmpty) {
        emit(const KioskDashboardError(
          'School code not found. Please login again.',
        ));
        return;
      }

      // Fetch live QR code directly from the attendance API
      final qrCode = await _getActiveKioskQr(schoolCode: schoolCode);

      if (isClosed) return;

      emit(KioskDashboardQrLoaded(
        qrCode: qrCode,
        schoolName: schoolName ?? 'School',
      ));
    } catch (e) {
      if (isClosed) return;

      final errorMessage = _extractErrorMessage(e);
      emit(KioskDashboardError(errorMessage));
    }
  }

  /// Refresh the QR code (for expiration handling)
  Future<void> refreshQrCode() async {
    try {
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);

      if (schoolCode == null || schoolCode.isEmpty) {
        return;
      }

      final qrCode = await _getActiveKioskQr(schoolCode: schoolCode);

      if (isClosed) return;

      final schoolName = await _storage.getString(StorageKeys.selectedSchoolName);

      emit(KioskDashboardQrLoaded(
        qrCode: qrCode,
        schoolName: schoolName ?? 'School',
      ));
    } catch (e) {
      if (isClosed) return;
      // Don't emit error state on refresh failure, just log it
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Failed to load QR code. Please try again.';
  }
}
