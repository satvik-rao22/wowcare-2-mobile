import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';

part 'sign_in_state.dart';

/// The sign-in lane, 1a through 1c.
///
/// One cubit spans the three screens because they are one decision taken in
/// three steps: the credentials, then the organization, then the school. The
/// router provides it above all three so a back gesture from 1c returns to a
/// still-answered 1b rather than to an empty form.
///
/// There is no sign-up path here and never will be: accounts are created on
/// the web by the school administrator.
class SignInCubit extends Cubit<SignInState> {
  SignInCubit({
    required AuthSource source,
    String prefillEmail = '',
    String prefillPassword = '',
  }) : _source = source,
       super(
         SignInState(email: prefillEmail, password: prefillPassword),
       );

  final AuthSource _source;

  bool _isFetching = false;

  void emailChanged(String value) => emit(
    state.copyWith(email: value, status: SignInStatus.editing),
  );

  void passwordChanged(String value) => emit(
    state.copyWith(password: value, status: SignInStatus.editing),
  );

  Future<void> submit() async {
    if (_isFetching || !state.canSubmit) return;
    _isFetching = true;
    emit(state.copyWith(status: SignInStatus.submitting));

    final result = await _source.signIn(
      email: state.email,
      password: state.password,
    );
    _isFetching = false;
    if (isClosed) return;

    switch (result) {
      case SignInOffline():
        emit(state.copyWith(status: SignInStatus.offline));
      case SignInRejected():
        emit(state.copyWith(status: SignInStatus.rejected));
      case SignInSuccess(:final account):
        emit(_scoped(account));
    }
  }

  /// 1b. Picking an organization clears whatever school the last one had.
  void selectOrganization(AuthOrganization organization) => emit(
    state.copyWith(organization: organization, clearSchool: true),
  );

  /// 1c. Picking a school is the last step; the page reads [SignInState.user]
  /// and hands it to the `SessionCubit`.
  void selectSchool(AuthSchool school) {
    if (school.isLocked) return;
    emit(state.copyWith(school: school, status: SignInStatus.scoped));
  }

  void searchSchools(String query) => emit(state.copyWith(schoolQuery: query));

  /// An account with one organization holding one open school has no scope to
  /// choose, so 1b and 1c are skipped rather than shown answered.
  SignInState _scoped(AuthAccount account) {
    final organizations = account.organizations;
    final onlyOrg = organizations.length == 1 ? organizations.first : null;
    final onlySchool = onlyOrg != null && onlyOrg.openSchools.length == 1
        ? onlyOrg.openSchools.first
        : null;

    return state.copyWith(
      status: onlySchool != null ? SignInStatus.scoped : SignInStatus.signedIn,
      account: account,
      organization: onlyOrg,
      school: onlySchool,
    );
  }
}
