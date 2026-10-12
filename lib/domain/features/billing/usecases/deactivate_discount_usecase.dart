import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/discount_repository.dart';

class DeactivateDiscountUseCase {
  DeactivateDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<void> call(String code) => AppEvents.track(
    AppEvent.billingDiscountDeactivate,
    () => _repository.deactivateDiscount(code),
  );
}
