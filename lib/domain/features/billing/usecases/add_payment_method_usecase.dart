import 'package:wowcare/core/observability/app_events.dart';

import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Adds a saved payment method from a Forte one-time token
/// (`POST /payment-gateway/payment-methods`).
class AddPaymentMethodUseCase {
  AddPaymentMethodUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<PaymentMethodEntity> call(AddPaymentMethodParams params) =>
      AppEvents.track(
        AppEvent.billingPaymentMethodAdd,
        () => _repository.addPaymentMethod(params),
      );
}
