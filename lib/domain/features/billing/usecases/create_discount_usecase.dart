import 'package:wowcare/core/observability/app_events.dart';

import '../entities/discount_entity.dart';
import '../repositories/discount_repository.dart';

class CreateDiscountUseCase {
  CreateDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<DiscountEntity> call(CreateDiscountParams params) => AppEvents.track(
    AppEvent.billingDiscountCreate,
    () => _repository.createDiscount(params),
  );
}
