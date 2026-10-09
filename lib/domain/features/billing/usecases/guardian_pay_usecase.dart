import 'package:wowcare/core/observability/app_events.dart';

import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Charges a guardian's saved payment method (Pay Now —
/// `POST /payment-gateway/guardian/pay`).
class GuardianPayUseCase {
  GuardianPayUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<GuardianPayResultEntity> call(GuardianPayParams params) =>
      AppEvents.track(
        AppEvent.billingGuardianPay,
        () => _repository.guardianPay(params),
      );
}
