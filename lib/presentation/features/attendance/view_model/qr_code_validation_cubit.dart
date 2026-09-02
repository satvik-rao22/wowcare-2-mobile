import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/qr_validation_result.dart';
import 'package:wowcare/domain/features/attendance/usecases/validate_qr_code_usecase.dart';

/// ViewModel seam for the guardian sign-in/out QR pre-check. Thin by design
/// (same "fetch cubit" shape as [StudentAttendanceProfileFetchCubit] etc.):
/// it wraps the `ValidateQrCodeUseCase` call plus the schoolCode lookup that
/// used to be duplicated inline in both call sites.
class QrCodeValidationCubit {
  QrCodeValidationCubit({
    required ValidateQrCodeUseCase validateQrCodeUseCase,
    required StorageService storageService,
  }) : _validateQrCodeUseCase = validateQrCodeUseCase,
       _storageService = storageService;

  final ValidateQrCodeUseCase _validateQrCodeUseCase;
  final StorageService _storageService;

  Future<QrValidationResult> validate({
    required String qrToken,
    required QrAttendanceUseCase useCase,
  }) async {
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode))?.trim() ??
        '';
    return _validateQrCodeUseCase(
      schoolCode: schoolCode,
      qrToken: qrToken,
      useCase: useCase,
    );
  }
}
