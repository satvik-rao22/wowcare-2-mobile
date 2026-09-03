import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';

part 'reset_password_state.dart';

/// 1f. Two entries, three rules, one key.
///
/// The rules are checked here rather than in the widget so the strength bar,
/// the tick beside each line and whether the key is live all read the same
/// three booleans.
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit({required AuthSource source})
    : _source = source,
      super(const ResetPasswordState());

  final AuthSource _source;

  bool _isFetching = false;

  void passwordChanged(String value) => emit(
    state.copyWith(password: value, status: ResetPasswordStatus.editing),
  );

  void confirmationChanged(String value) => emit(
    state.copyWith(confirmation: value, status: ResetPasswordStatus.editing),
  );

  Future<void> save() async {
    if (_isFetching || !state.isValid) return;
    _isFetching = true;
    emit(state.copyWith(status: ResetPasswordStatus.saving));

    final saved = await _source.savePassword(state.password);
    _isFetching = false;
    if (isClosed) return;

    emit(
      state.copyWith(
        status: saved
            ? ResetPasswordStatus.saved
            : ResetPasswordStatus.failed,
      ),
    );
  }
}
