part of 'discount_form_cubit.dart';

enum DiscountFormStatus { invalid, success, error }

class DiscountFormResult {
  const DiscountFormResult({required this.status, this.discount});

  final DiscountFormStatus status;
  final DiscountAccountModel? discount;
}

class DiscountFormState extends Equatable {
  const DiscountFormState({
    this.isSubmitting = false,
    this.nameError = false,
    this.percentageError = false,
  });

  final bool isSubmitting;
  final bool nameError;
  final bool percentageError;

  DiscountFormState copyWith({
    bool? isSubmitting,
    bool? nameError,
    bool? percentageError,
  }) => DiscountFormState(
    isSubmitting: isSubmitting ?? this.isSubmitting,
    nameError: nameError ?? this.nameError,
    percentageError: percentageError ?? this.percentageError,
  );

  @override
  List<Object?> get props => [isSubmitting, nameError, percentageError];
}
