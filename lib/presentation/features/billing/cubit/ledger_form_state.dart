part of 'ledger_form_cubit.dart';

class LedgerFormState extends Equatable {
  const LedgerFormState({
    required this.selectedCategory,
    required this.isSubmitting,
    required this.isLoading,
    required this.titleError,
    required this.categoryError,
  });

  const LedgerFormState.initial(String? initialCategory)
    : selectedCategory = initialCategory,
      isSubmitting = false,
      isLoading = false,
      titleError = false,
      categoryError = false;

  final String? selectedCategory;
  final bool isSubmitting;
  final bool isLoading;
  final bool titleError;
  final bool categoryError;

  LedgerFormState copyWith({
    String? Function()? selectedCategory,
    bool? isSubmitting,
    bool? isLoading,
    bool? titleError,
    bool? categoryError,
  }) {
    return LedgerFormState(
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoading: isLoading ?? this.isLoading,
      titleError: titleError ?? this.titleError,
      categoryError: categoryError ?? this.categoryError,
    );
  }

  @override
  List<Object?> get props => [
    selectedCategory,
    isSubmitting,
    isLoading,
    titleError,
    categoryError,
  ];
}
