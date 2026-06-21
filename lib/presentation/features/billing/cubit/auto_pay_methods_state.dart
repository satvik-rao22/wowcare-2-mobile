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
    this.autopayEnabled = false,
    this.initialAutopayEnabled = false,
    this.apiLoginId = '',
    this.maxMethods = 4,
    this.methods = const <PaymentMethodEntity>[],
    this.selectedMethodCode,
    this.deletingMethodCode,
    this.errorMessage,
  });

  /// Initial load of config + status + methods is in flight.
  final bool isLoading;

  /// A new method is being added (tokenize → POST → refresh).
  final bool isSaving;

  /// The Save action (commit auto-pay status + primary) is in flight.
  final bool isSettingPrimary;

  /// Current (possibly unsaved) auto-pay toggle value shown in the UI.
  final bool autopayEnabled;

  /// Auto-pay value as last known from the server; used to detect a pending
  /// toggle change that the Save button must commit.
  final bool initialAutopayEnabled;

  /// School-level Forte `apiLoginId` used to initialize the Forte JS SDK.
  final String apiLoginId;

  /// Max saved payment methods allowed (from school config).
  final int maxMethods;

  final List<PaymentMethodEntity> methods;

  /// The method the user has selected as the auto-pay method.
  final String? selectedMethodCode;

  /// Code of the method whose delete request is currently in flight (if any).
  final String? deletingMethodCode;

  final String? errorMessage;

  bool get hasForteConfig => apiLoginId.trim().isNotEmpty;

  bool get canAddMore => methods.length < maxMethods;

  bool get hasMethods => methods.isNotEmpty;

  /// The method currently flagged primary (default payment method) on the server.
  PaymentMethodEntity? get primaryMethod {
    for (final m in methods) {
      if (m.primary) return m;
    }
    return null;
  }

  /// The method currently flagged as the auto-pay method on the server.
  PaymentMethodEntity? get autopayMethod {
    for (final m in methods) {
      if (m.autopay) return m;
    }
    return null;
  }

  /// Whether the auto-pay toggle differs from the saved server value.
  bool get autopayChanged => autopayEnabled != initialAutopayEnabled;

  /// Whether (with auto-pay on) the user picked a different auto-pay method.
  bool get methodChanged {
    if (!autopayEnabled) return false;
    final code = selectedMethodCode;
    if (code == null || code.isEmpty) return false;
    return autopayMethod?.code != code;
  }

  /// The Save button commits a pending toggle change and/or a new auto-pay
  /// method. Actionable only when there's a pending change and nothing is in
  /// flight.
  bool get canSave =>
      (autopayChanged || methodChanged) &&
      !isSaving &&
      !isSettingPrimary &&
      !isLoading;

  AutoPayMethodsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSettingPrimary,
    bool? autopayEnabled,
    bool? initialAutopayEnabled,
    String? apiLoginId,
    int? maxMethods,
    List<PaymentMethodEntity>? methods,
    String? Function()? selectedMethodCode,
    String? Function()? deletingMethodCode,
    String? Function()? errorMessage,
  }) {
    return AutoPayMethodsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSettingPrimary: isSettingPrimary ?? this.isSettingPrimary,
      autopayEnabled: autopayEnabled ?? this.autopayEnabled,
      initialAutopayEnabled:
          initialAutopayEnabled ?? this.initialAutopayEnabled,
      apiLoginId: apiLoginId ?? this.apiLoginId,
      maxMethods: maxMethods ?? this.maxMethods,
      methods: methods ?? this.methods,
      selectedMethodCode: selectedMethodCode != null
          ? selectedMethodCode()
          : this.selectedMethodCode,
      deletingMethodCode: deletingMethodCode != null
          ? deletingMethodCode()
          : this.deletingMethodCode,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        isSettingPrimary,
        autopayEnabled,
        initialAutopayEnabled,
        apiLoginId,
        maxMethods,
        methods,
        selectedMethodCode,
        deletingMethodCode,
        errorMessage,
      ];
}
