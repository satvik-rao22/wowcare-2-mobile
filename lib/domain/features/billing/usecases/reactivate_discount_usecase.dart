import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/discount_repository.dart';

class ReactivateDiscountUseCase {
  ReactivateDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<void> call(String code) => AppEvents.track(
    AppEvent.billingDiscountReactivate,
    () => _repository.reactivateDiscount(code),
  );
}
