part of 'qr_validation_cubit.dart';

/// Where the scanner navigates after a successful QR validation.
/// Resolved dynamically by [QrValidationCubit] from the user's role and
/// live attendance status — never hardcoded by the caller.
enum QrNavigationRoute {
  guardianSignIn,
  guardianSignOut,
  staffSignIn,
  staffSignOut,
}

abstract class QrValidationState extends Equatable {
  const QrValidationState();
  @override
  List<Object?> get props => [];
}

class QrValidationInitial extends QrValidationState {
  const QrValidationInitial();
}

class QrValidationLoading extends QrValidationState {
  const QrValidationLoading();
}

class QrValidationSuccess extends QrValidationState {
  const QrValidationSuccess(this.result, {required this.route});

  final QrValidationResult result;
  final QrNavigationRoute route;

  @override
  List<Object?> get props => [result, route];
}

class QrValidationFailure extends QrValidationState {
  const QrValidationFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
