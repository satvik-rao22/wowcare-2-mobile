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

  /// Per-child allocations for the charge — only the children the parent
  /// entered a positive amount against. Empty unless in [PayNowAmountMode.custom],
  /// so "Current Outstanding" pays family-wide (oldest invoice first).
  List<PaymentAllocationEntity> get allocations {
    if (mode != PayNowAmountMode.custom) return const [];
    final entries = customAmounts.entries
        .where((e) => e.value > 0)
        .map(
          (e) => PaymentAllocationEntity(studentCode: e.key, amount: e.value),
        )
        .toList();
    return entries;
  }

  /// The amount that will actually be charged based on the selected mode.
  double get amount =>
      mode == PayNowAmountMode.custom ? customTotal : currentAmount;

  /// Custom mode: true if any per-child amount exceeds that child's own
  /// outstanding balance (the `0.001` tolerance absorbs float rounding).
  bool customExceedsOutstandingFor(FamilyLedgerPersonEntity student) =>
      (customAmounts[student.code] ?? 0) > student.outstanding + 0.001;

  /// True when any per-child custom amount is over that child's outstanding.
  bool get customExceedsOutstanding =>
      mode == PayNowAmountMode.custom &&
      students.any(customExceedsOutstandingFor);

  /// Current Outstanding mode: true if the typed amount exceeds the family's
  /// unpaid balance (a guardian can only pay down what's owed).
  bool get currentExceedsUnpaid =>
      mode == PayNowAmountMode.currentOutstanding &&
      currentAmount > unpaid + 0.001;

  /// Any amount that exceeds what's actually owed — blocks Confirm.
  bool get exceedsOutstanding =>
      customExceedsOutstanding || currentExceedsUnpaid;

  bool get canConfirm {
    if (isLoading) return false;
    if (exceedsOutstanding) return false;
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
