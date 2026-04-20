part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthLoaded extends AuthState {
  const AuthLoaded({
    required this.loginResponse,
    this.schoolsByOrg = const <String, List<Map<String, String>>>{},
    this.isPrefetchingSchools = false,
    this.lastErrorMessage,
    this.orgNames = const [],
    this.hasLastSchoolFromContext = false,
    this.redirectUrl,
  });

  final LoginResponseModel loginResponse;
  /// Org code -> list of {schoolCode, schoolName} for school selection.
  final Map<String, List<Map<String, String>>> schoolsByOrg;
  final bool isPrefetchingSchools;
  final String? lastErrorMessage;
  /// Organization display names, in the same order as the codes
  /// extracted from [loginResponse.roles].
  final List<String> orgNames;
  /// True when login-context API returned last school and we saved it.
  /// UI can skip role/school selection and go straight to Dashboard.
  final bool hasLastSchoolFromContext;
  /// Redirect URL from login-context API (when schoolCode is null).
  /// Used to determine which screen to navigate to.
  final String? redirectUrl;

  @override
  List<Object?> get props => [
        loginResponse,
        schoolsByOrg,
        isPrefetchingSchools,
        lastErrorMessage,
        orgNames,
        hasLastSchoolFromContext,
        redirectUrl,
      ];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
