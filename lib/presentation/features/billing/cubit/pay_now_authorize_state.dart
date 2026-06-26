part of 'pay_now_authorize_cubit.dart';

class PayNowAuthorizeState extends Equatable {
  const PayNowAuthorizeState({
    this.isSubmitting = false,
    this.result,
    this.errorMessage,
  });

  final bool isSubmitting;
  final GuardianPayResultEntity? result;
  final String? errorMessage;

  PayNowAuthorizeState copyWith({
    bool? isSubmitting,
    GuardianPayResultEntity? Function()? result,
    String? Function()? errorMessage,
  }) {
    return PayNowAuthorizeState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: result != null ? result() : this.result,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, result, errorMessage];
}
