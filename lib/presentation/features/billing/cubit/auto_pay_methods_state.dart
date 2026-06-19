part of 'auto_pay_methods_cubit.dart';

/// State for the auto-pay payment-methods screen.
///
/// Holds the guardian's saved Forte payment methods (max 4), the auto-pay
/// on/off status, the school's Forte `apiLoginId` (needed to launch the
/// tokenization webview), and transient save/error flags.
class AutoPayMethodsState extends Equatable {
  const AutoPayMethodsState({
    this.isLoading = true,
    this.isSaving = false,
    this.isSettingPrimary = false,
    this.isTogglingAutoPay = false,
    this.autopayEnabled = false,
    this.apiLoginId = '',
    this.methods = const <PaymentMethodEntity>[],
    this.selectedMethodCode,
    this.errorMessage,
  });

  /// Initial load of config + status + methods is in flight.
  final bool isLoading;

  /// A new method is being added (tokenize → POST → refresh).
  final bool isSaving;

  /// A `PUT .../primary` call is in flight.
  final bool isSettingPrimary;

  /// A `PUT .../autopay/status` (enable/disable) call is in flight.
  final bool isTogglingAutoPay;

  final bool autopayEnabled;

  /// School-level Forte `apiLoginId` used to initialize the Forte JS SDK.
  final String apiLoginId;

  final List<PaymentMethodEntity> methods;

  /// The method the user has selected as the auto-pay (primary) method.
  final String? selectedMethodCode;

  final String? errorMessage;

  static const int maxMethods = 4;

  bool get hasForteConfig => apiLoginId.trim().isNotEmpty;

  bool get canAddMore => methods.length < maxMethods;

  bool get hasMethods => methods.isNotEmpty;

  PaymentMethodEntity? get primaryMethod {
    for (final m in methods) {
      if (m.primary) return m;
    }
    return null;
  }

  /// Whether the user changed the selected primary away from the current one.
  bool get hasPrimaryChange {
    if (!autopayEnabled) return false;
    final code = selectedMethodCode;
    if (code == null || code.isEmpty) return false;
    return primaryMethod?.code != code;
  }

  /// The Save button is actionable only when the selected method differs from
  /// the current primary and nothing is in flight.
  bool get canSave =>
      hasPrimaryChange && !isSaving && !isSettingPrimary && !isLoading;

  AutoPayMethodsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSettingPrimary,
    bool? isTogglingAutoPay,
    bool? autopayEnabled,
    String? apiLoginId,
    List<PaymentMethodEntity>? methods,
    String? Function()? selectedMethodCode,
    String? Function()? errorMessage,
  }) {
    return AutoPayMethodsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSettingPrimary: isSettingPrimary ?? this.isSettingPrimary,
      isTogglingAutoPay: isTogglingAutoPay ?? this.isTogglingAutoPay,
      autopayEnabled: autopayEnabled ?? this.autopayEnabled,
      apiLoginId: apiLoginId ?? this.apiLoginId,
      methods: methods ?? this.methods,
      selectedMethodCode: selectedMethodCode != null
          ? selectedMethodCode()
          : this.selectedMethodCode,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        isSettingPrimary,
        isTogglingAutoPay,
        autopayEnabled,
        apiLoginId,
        methods,
        selectedMethodCode,
        errorMessage,
      ];
}
