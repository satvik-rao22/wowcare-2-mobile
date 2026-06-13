part of 'auto_pay_methods_cubit.dart';

class AutoPayMethodsState extends Equatable {
  const AutoPayMethodsState({
    required this.isAutoPayEnabled,
    required this.isSaving,
    required this.isLoadingSavedPaymentMethods,
    required this.hasErrorLoadingPaymentMethods,
    required this.selectedMethod,
    required this.initialSelectedMethod,
    required this.initialAutoPayEnabled,
    required this.savedCardData,
    required this.savedEcheckData,
  });

  const AutoPayMethodsState.initial()
      : isAutoPayEnabled = true,
        isSaving = false,
        isLoadingSavedPaymentMethods = false,
        hasErrorLoadingPaymentMethods = false,
        selectedMethod = 'echeck',
        initialSelectedMethod = 'echeck',
        initialAutoPayEnabled = true,
        savedCardData = const SavedCardData(
          nameOnCard: 'Emma Johnson',
          last4: '3456',
          expireMonth: 10,
          expireYear: 2028,
          cardType: 'visa',
        ),
        savedEcheckData = const SavedEcheckData(
          accountHolder: 'Emma Johnson',
          routingNumber: '123456789',
          last4: '9876',
          accountType: 'checking',
        );

  final bool isAutoPayEnabled;
  final bool isSaving;
  final bool isLoadingSavedPaymentMethods;
  final bool hasErrorLoadingPaymentMethods;
  final String? selectedMethod;
  final String? initialSelectedMethod;
  final bool initialAutoPayEnabled;
  final SavedCardData? savedCardData;
  final SavedEcheckData? savedEcheckData;

  bool get hasSelection => !isAutoPayEnabled || selectedMethod != null;
  bool get hasChanges =>
      (isAutoPayEnabled != initialAutoPayEnabled) ||
      (selectedMethod != initialSelectedMethod);
  bool get canSave => !isSaving && hasSelection && hasChanges;

  /// [selectedMethod] is passed as a getter so callers can explicitly set it to
  /// null (a plain `?? this.selectedMethod` couldn't distinguish null-vs-unset).
  AutoPayMethodsState copyWith({
    bool? isAutoPayEnabled,
    bool? isSaving,
    bool? isLoadingSavedPaymentMethods,
    bool? hasErrorLoadingPaymentMethods,
    String? Function()? selectedMethod,
    String? initialSelectedMethod,
    bool? initialAutoPayEnabled,
    SavedCardData? savedCardData,
    SavedEcheckData? savedEcheckData,
  }) {
    return AutoPayMethodsState(
      isAutoPayEnabled: isAutoPayEnabled ?? this.isAutoPayEnabled,
      isSaving: isSaving ?? this.isSaving,
      isLoadingSavedPaymentMethods:
          isLoadingSavedPaymentMethods ?? this.isLoadingSavedPaymentMethods,
      hasErrorLoadingPaymentMethods:
          hasErrorLoadingPaymentMethods ?? this.hasErrorLoadingPaymentMethods,
      selectedMethod:
          selectedMethod != null ? selectedMethod() : this.selectedMethod,
      initialSelectedMethod:
          initialSelectedMethod ?? this.initialSelectedMethod,
      initialAutoPayEnabled:
          initialAutoPayEnabled ?? this.initialAutoPayEnabled,
      savedCardData: savedCardData ?? this.savedCardData,
      savedEcheckData: savedEcheckData ?? this.savedEcheckData,
    );
  }

  @override
  List<Object?> get props => [
        isAutoPayEnabled,
        isSaving,
        isLoadingSavedPaymentMethods,
        hasErrorLoadingPaymentMethods,
        selectedMethod,
        initialSelectedMethod,
        initialAutoPayEnabled,
        savedCardData,
        savedEcheckData,
      ];
}
