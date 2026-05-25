import '../entities/qr_validation_result.dart';
import '../repositories/attendance_repository.dart';

enum QrAttendanceUseCase {
  guardianSignIn('GUARDIAN_SIGN_IN'),
  guardianSignOut('GUARDIAN_SIGN_OUT'),
  staffSignIn('STAFF_SIGN_IN'),
  staffSignOut('STAFF_SIGN_OUT'),
  adminSignIn('ADMIN_SIGN_IN'),
  adminSignOut('ADMIN_SIGN_OUT');

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
    return _repository.validateQrCode(
      schoolCode: schoolCode,
      qrToken: qrToken,
      useCase: useCase.apiValue,
    );
  }
}
