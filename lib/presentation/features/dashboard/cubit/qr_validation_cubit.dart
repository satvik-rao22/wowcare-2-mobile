import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/entities/qr_validation_result.dart';
import 'package:wowcare/domain/features/attendance/usecases/validate_qr_code_usecase.dart';

part 'qr_validation_state.dart';

/// Holds routing args passed into the QR scanner.
class QrScannerArgs {
  const QrScannerArgs({
    required this.useCase,
    this.studentSignInStatuses,
    this.staffSignedIn,
  });

  final QrAttendanceUseCase useCase;

  /// Guardian flow: one entry per linked student — true = signed in today.
  final List<bool>? studentSignInStatuses;

  /// Staff flow: current sign-in state.
  final bool? staffSignedIn;

  bool get isGuardianFlow =>
      useCase == QrAttendanceUseCase.guardianSignIn ||
      useCase == QrAttendanceUseCase.guardianSignOut;
}

class QrValidationCubit extends Cubit<QrValidationState> {
  QrValidationCubit({required ValidateQrCodeUseCase validateQrCodeUseCase})
      : _validateQrCodeUseCase = validateQrCodeUseCase,
        super(const QrValidationInitial());

  final ValidateQrCodeUseCase _validateQrCodeUseCase;
  bool _isFetching = false;

  Future<void> validate({
    required String schoolCode,
    required String qrToken,
    required QrAttendanceUseCase useCase,
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(const QrValidationLoading());
    try {
      final result = await _validateQrCodeUseCase(
        schoolCode: schoolCode,
        qrToken: qrToken,
        useCase: useCase,
      );
      if (!isClosed) emit(QrValidationSuccess(result));
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
}
