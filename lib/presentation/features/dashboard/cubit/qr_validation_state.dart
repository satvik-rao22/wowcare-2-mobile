part of 'qr_validation_cubit.dart';

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
  const QrValidationSuccess(this.result);
  final QrValidationResult result;
  @override
  List<Object?> get props => [result];
}

class QrValidationFailure extends QrValidationState {
  const QrValidationFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
