import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/attendance/usecases/validate_qr_code_usecase.dart';
import '../../../view_model/qr_code_validation_cubit.dart';

part 'student_sign_in_out_selection_state.dart';

/// Owns the QR-rescan-and-validate pre-step for [StudentSignInOutSelectionScreen]
/// (Sign In / Sign Out buttons), which used to hold the in-flight flag as a
/// plain `setState`-driven field (Mandate 2). Navigation and snackbar
/// display stay in the view (both are context-dependent presentation
/// concerns) — this cubit only owns the validation call and its loading
/// state, invoking the callbacks the view supplies for each outcome.
class StudentSignInOutSelectionCubit
    extends Cubit<StudentSignInOutSelectionState> {
  StudentSignInOutSelectionCubit({required QrCodeValidationCubit qrValidation})
    : _qrValidation = qrValidation,
      super(const StudentSignInOutSelectionState());

  final QrCodeValidationCubit _qrValidation;

  /// Re-validates the QR token with the correct [useCase] before letting the
  /// caller proceed — the validate endpoint must always receive the right
  /// useCase (GUARDIAN_SIGN_IN for sign-in, GUARDIAN_SIGN_OUT for sign-out).
  /// Skips validation entirely (and calls [onSuccess] immediately) when this
  /// selection didn't originate from a QR scan.
  Future<void> validateAndRun({
    required bool isQrScan,
    required String qrToken,
    required QrAttendanceUseCase useCase,
    required VoidCallback onSuccess,
    required void Function(String message) onInvalid,
    required VoidCallback onError,
  }) async {
    if (!isQrScan || qrToken.isEmpty) {
      onSuccess();
      return;
    }

    emit(state.copyWith(isValidating: true));
    try {
      final result = await _qrValidation.validate(
        qrToken: qrToken,
        useCase: useCase,
      );
      if (isClosed) return;
      if (result.valid) {
        onSuccess();
      } else {
        onInvalid(result.reason ?? 'QR code is not valid');
      }
    } catch (_) {
      if (!isClosed) onError();
    } finally {
      if (!isClosed) emit(state.copyWith(isValidating: false));
    }
  }
}
