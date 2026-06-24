part of 'pay_now_cubit.dart';

enum PayNowAmountMode { currentOutstanding, custom }

class PayNowState extends Equatable {
  const PayNowState({
    this.isLoading = true,
    this.ledger,
    this.guardianCode = '',
    this.mode = PayNowAmountMode.currentOutstanding,
    this.currentAmount = 0,
    this.customAmounts = const <String, double>{},
    this.errorMessage,
  });

  final bool isLoading;
  final FamilyLedgerEntity? ledger;

  /// The logged-in guardian's code — appended to the payment idempotency key.
  final String guardianCode;
  final PayNowAmountMode mode;

  /// Amount for the "Current Outstanding" option (seeded with the family's
  /// unpaid total).
  final double currentAmount;

  /// Per-child amounts (keyed by student code) for the "Custom Amount" option.
  final Map<String, double> customAmounts;

  final String? errorMessage;

  /// The children in this family, each with their own outstanding balance.
  List<FamilyLedgerPersonEntity> get students => ledger?.students ?? const [];

  /// The family's unpaid total — what "Current Outstanding" charges.
  double get unpaid => ledger?.unpaid ?? 0;

  String get ownerType => ledger?.ownerType ?? '';
  String get ownerCode => ledger?.ownerCode ?? '';

  /// Sum of the per-child custom amounts entered.
  double get customTotal =>
      customAmounts.values.fold<double>(0, (sum, v) => sum + v);

  /// The amount that will actually be charged based on the selected mode.
  double get amount =>
      mode == PayNowAmountMode.custom ? customTotal : currentAmount;

  bool get canConfirm {
    if (isLoading) return false;
    return amount > 0;
  }

  PayNowState copyWith({
    bool? isLoading,
    FamilyLedgerEntity? Function()? ledger,
    String? guardianCode,
    PayNowAmountMode? mode,
    double? currentAmount,
    Map<String, double>? customAmounts,
    String? Function()? errorMessage,
  }) {
    return PayNowState(
      isLoading: isLoading ?? this.isLoading,
      ledger: ledger != null ? ledger() : this.ledger,
      guardianCode: guardianCode ?? this.guardianCode,
      mode: mode ?? this.mode,
      currentAmount: currentAmount ?? this.currentAmount,
      customAmounts: customAmounts ?? this.customAmounts,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        ledger,
        guardianCode,
        mode,
        currentAmount,
        customAmounts,
        errorMessage,
      ];
}
