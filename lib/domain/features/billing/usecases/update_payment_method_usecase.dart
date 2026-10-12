import 'package:wowcare/core/observability/app_events.dart';

import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Updates a saved method's editable metadata
/// (`PUT /payment-gateway/payment-methods/{code}`).
class UpdatePaymentMethodUseCase {
  UpdatePaymentMethodUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<PaymentMethodEntity> call({
    required String paymentMethodCode,
    required UpdatePaymentMethodParams params,
  }) => AppEvents.track(
    AppEvent.billingPaymentMethodUpdate,
    () => _repository.updatePaymentMethod(
      paymentMethodCode: paymentMethodCode,
      params: params,
    ),
  );
}
