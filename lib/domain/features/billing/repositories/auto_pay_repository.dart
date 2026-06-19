import '../entities/auto_pay_entity.dart';

/// Auto-pay / Forte payment-method operations (Billing MS).
abstract class AutoPayRepository {
  /// School-level Forte config (provides the `apiLoginId` for tokenization).
  Future<SchoolForteConfigEntity?> getSchoolForteConfig({
    required String organizationCode,
    required String schoolCode,
  });

  /// Whether auto-pay is currently enabled for the guardian.
  Future<AutoPayStatusEntity> getAutoPayStatus(GuardianScopeParams params);

  /// Enables or disables auto-pay for the guardian.
  Future<AutoPayStatusEntity> setAutoPayStatus({
    required GuardianScopeParams scope,
    required bool autopayEnabled,
  });

  /// All saved payment methods for the guardian (max 4).
  Future<List<PaymentMethodEntity>> getPaymentMethods(
      GuardianScopeParams params);

  /// Adds a new saved payment method from a Forte one-time token.
  Future<PaymentMethodEntity> addPaymentMethod(AddPaymentMethodParams params);

  /// Marks the given payment method as primary (the auto-pay method).
  Future<PaymentMethodEntity> setPrimaryPaymentMethod({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  });

  /// Removes a saved payment method.
  Future<void> deletePaymentMethod({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  });
}
