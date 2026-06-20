part of 'pay_now_cubit.dart';

enum PayNowAmountMode { currentOutstanding, custom }

class PayNowState extends Equatable {
  const PayNowState({
    this.isLoading = true,
    this.families = const <FamilySummaryEntity>[],
    this.mode = PayNowAmountMode.currentOutstanding,
    this.currentAmount = 0,
    this.customAmounts = const <String, double>{},
    this.errorMessage,
  });

  final bool isLoading;
  final List<FamilySummaryEntity> families;
  final PayNowAmountMode mode;

  /// Amount entered for the "Current Outstanding (Family Balance)" option.
  final double currentAmount;

  /// Per-owner amounts (keyed by ownerCode) for the "Custom Amount" option.
  final Map<String, double> customAmounts;

  final String? errorMessage;

  /// Sum of all owners' open balances.
  double get familyTotal =>
      families.fold<double>(0, (sum, f) => sum + f.openBalance);

  /// Sum of the per-owner custom amounts entered.
  double get customTotal =>
      customAmounts.values.fold<double>(0, (sum, v) => sum + v);

  /// The amount that will actually be charged based on the selected mode.
  double get amount => mode == PayNowAmountMode.custom
      ? customTotal
      : currentAmount;

  bool get canConfirm => amount > 0 && !isLoading;

  PayNowState copyWith({
    bool? isLoading,
    List<FamilySummaryEntity>? families,
    PayNowAmountMode? mode,
    double? currentAmount,
    Map<String, double>? customAmounts,
    String? Function()? errorMessage,
  }) {
    return PayNowState(
      isLoading: isLoading ?? this.isLoading,
      families: families ?? this.families,
      mode: mode ?? this.mode,
      currentAmount: currentAmount ?? this.currentAmount,
      customAmounts: customAmounts ?? this.customAmounts,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        families,
        mode,
        currentAmount,
        customAmounts,
        errorMessage,
      ];
}
