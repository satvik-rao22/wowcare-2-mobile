part of 'ledger_form_cubit.dart';

class LedgerFormState extends Equatable {
  const LedgerFormState({
    required this.selectedType,
    required this.isSubmitting,
    required this.isLoading,
    required this.titleError,
    required this.typeError,
  });

  const LedgerFormState.initial(String? initialType)
      : selectedType = initialType,
        isSubmitting = false,
        isLoading = false,
        titleError = false,
        typeError = false;

  final String? selectedType;
  final bool isSubmitting;
  final bool isLoading;
  final bool titleError;
  final bool typeError;

  /// [selectedType] is passed as a getter so callers can explicitly set null.
  LedgerFormState copyWith({
    String? Function()? selectedType,
    bool? isSubmitting,
    bool? isLoading,
    bool? titleError,
    bool? typeError,
  }) {
    return LedgerFormState(
      selectedType: selectedType != null ? selectedType() : this.selectedType,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoading: isLoading ?? this.isLoading,
      titleError: titleError ?? this.titleError,
      typeError: typeError ?? this.typeError,
    );
  }

  @override
  List<Object?> get props =>
      [selectedType, isSubmitting, isLoading, titleError, typeError];
}
