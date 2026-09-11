import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/validators/app_validators.dart';
import 'package:wowcare/domain/features/auth/usecases/forgot_password_usecase.dart';

part 'forgot_password_state.dart';

/// Owns the "Forgot Password" screen's submit flow. The view only ever
/// reads this cubit's state and calls [submit] — it never resolves
/// [ForgotPasswordUseCase] itself.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._forgotPasswordUseCase)
    : super(const ForgotPasswordInitial());

  final ForgotPasswordUseCase _forgotPasswordUseCase;

  Future<void> submit(String email) async {
    final trimmed = email.trim();
    if (!AppValidators.isValidEmail(trimmed)) {
      emit(const ForgotPasswordFailure('Please enter a valid email address'));
      return;
    }

    emit(const ForgotPasswordLoading());
    final result = await _forgotPasswordUseCase(trimmed);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        ForgotPasswordFailure(failure.message ?? failure.toString()),
      ),
      (message) => emit(ForgotPasswordSuccess(message)),
    );
  }

  /// Resets back to [ForgotPasswordInitial] so a dismissed error/success
  /// banner doesn't reappear if the state is read again (e.g. after a
  /// rebuild triggered by something unrelated).
  void reset() => emit(const ForgotPasswordInitial());
}
