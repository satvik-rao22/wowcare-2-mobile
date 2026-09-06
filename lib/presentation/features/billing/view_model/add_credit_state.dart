part of 'add_credit_cubit.dart';

class AddCreditState extends Equatable {
  const AddCreditState({
    this.isSubmitting = false,
    this.amountError = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final bool amountError;
  final String? errorMessage;

  AddCreditState copyWith({
    bool? isSubmitting,
    bool? amountError,
    String? errorMessage,
  }) {
    return AddCreditState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      amountError: amountError ?? this.amountError,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, amountError, errorMessage];
}
