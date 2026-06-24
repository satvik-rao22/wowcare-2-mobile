part of 'payment_settings_cubit.dart';

enum PaymentSettingsStatus { initial, loading, loaded, failure }

class PaymentSettingsState extends Equatable {
  const PaymentSettingsState({
    this.status = PaymentSettingsStatus.initial,
    this.settings = PaymentSettingsEntity.fallback,
    this.errorMessage,
  });

  final PaymentSettingsStatus status;

  /// Always non-null — [PaymentSettingsEntity.fallback] until real data loads,
  /// so callers never have to null-check.
  final PaymentSettingsEntity settings;
  final String? errorMessage;

  bool get isLoading => status == PaymentSettingsStatus.loading;

  PaymentSettingsState copyWith({
    PaymentSettingsStatus? status,
    PaymentSettingsEntity? settings,
    String? errorMessage,
  }) {
    return PaymentSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
