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
    this.schoolsByOrg = const {},
    this.isPrefetchingSchools = false,
  });

  final LoginResponseModel loginResponse;
  final Map<String, List<String>> schoolsByOrg;
  final bool isPrefetchingSchools;

  @override
  List<Object?> get props => [loginResponse, schoolsByOrg, isPrefetchingSchools];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
