import 'package:wowcare/core/observability/app_events.dart';

import '../entities/qr_validation_result.dart';
import '../repositories/attendance_repository.dart';

enum QrAttendanceUseCase {
  guardianSignIn('GUARDIAN_SIGN_IN'),
  guardianSignOut('GUARDIAN_SIGN_OUT'),
  staffSignIn('STAFF_SELF_SIGN_IN'),
  staffSignOut('STAFF_SELF_SIGN_OUT'),
  adminSignIn('STAFF_SELF_SIGN_IN'),
  adminSignOut('STAFF_SELF_SIGN_OUT');

  const QrAttendanceUseCase(this.apiValue);
  final String apiValue;
}

class ValidateQrCodeUseCase {
  ValidateQrCodeUseCase(this._repository);
  final AttendanceRepository _repository;

  Future<QrValidationResult> call({
    required String schoolCode,
    required String qrToken,
    required QrAttendanceUseCase useCase,
  }) {
    // An expired or unknown QR comes back as `valid: false`, not a throw.
    return AppEvents.track(
      AppEvent.attendanceQrValidate,
      () => _repository.validateQrCode(
        schoolCode: schoolCode,
        qrToken: qrToken,
        useCase: useCase.apiValue,
      ),
      failureOf: (result) => result.valid ? null : EventFailure.validation,
    );
  }
}
