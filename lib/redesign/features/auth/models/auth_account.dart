import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/features/auth/models/auth_organization.dart';

/// What a successful sign-in hands back: who signed in, and where they can
/// work. Mirrors the login response (user + roles) once the roles are folded
/// into organizations and schools.
@immutable
class AuthAccount extends Equatable {
  const AuthAccount({required this.user, required this.organizations});

  final SessionUser user;
  final List<AuthOrganization> organizations;

  @override
  List<Object?> get props => [user, organizations];
}

/// The three outcomes a sign-in attempt can have. Login returns a generic
/// failure and nothing else, so there is no lockout or attempts-left case.
@immutable
sealed class SignInResult {
  const SignInResult();
}

class SignInSuccess extends SignInResult {
  const SignInSuccess(this.account);

  final AuthAccount account;
}

/// Wrong email or password.
class SignInRejected extends SignInResult {
  const SignInRejected();
}

/// The request never reached the server.
class SignInOffline extends SignInResult {
  const SignInOffline();
}
