import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';

part 'forgot_password_state.dart';

/// 1d and 1e: ask for the address, then hold the reviewer on the confirmation
/// while the resend key counts itself back to life.
///
/// One cubit for the pair because 1e has nothing of its own to fetch: it is
/// 1d's answer, plus a clock.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({required AuthSource source})
    : _source = source,
      super(const ForgotPasswordState());

  /// How long the link takes to arrive before offering to send another.
  static const int _resendSeconds = 45;

  final AuthSource _source;

  Timer? _countdown;
  bool _isFetching = false;

  void emailChanged(String value) => emit(
    state.copyWith(email: value, status: ForgotPasswordStatus.editing),
  );

  Future<void> send() async {
    if (_isFetching || !state.isEmailValid) {
      if (!state.isEmailValid) {
        emit(state.copyWith(status: ForgotPasswordStatus.invalid));
      }
      return;
    }
    _isFetching = true;
    emit(state.copyWith(status: ForgotPasswordStatus.sending));

    final sent = await _source.sendResetLink(state.email);
    _isFetching = false;
    if (isClosed) return;

    if (!sent) {
      emit(state.copyWith(status: ForgotPasswordStatus.failed));
      return;
    }
    emit(state.copyWith(status: ForgotPasswordStatus.sent));
    _startCountdown();
  }

  /// 1e's key, once the clock has run out.
  Future<void> resend() async {
    if (state.secondsLeft > 0) return;
    await send();
  }

  void _startCountdown() {
    _countdown?.cancel();
    emit(state.copyWith(secondsLeft: _resendSeconds));
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final left = state.secondsLeft - 1;
      emit(state.copyWith(secondsLeft: left));
      if (left <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _countdown?.cancel();
    return super.close();
  }
}
