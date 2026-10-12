import 'package:wowcare/core/observability/app_events.dart';

import '../entities/discount_entity.dart';
import '../repositories/discount_repository.dart';

class UpdateDiscountUseCase {
  UpdateDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<DiscountEntity> call({
    required String code,
    required CreateDiscountParams params,
  }) => AppEvents.track(
    AppEvent.billingDiscountUpdate,
    () => _repository.updateDiscount(code: code, params: params),
  );
}
