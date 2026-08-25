import '../entities/discount_entity.dart';
import '../repositories/discount_repository.dart';

class UpdateDiscountUseCase {
  UpdateDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<DiscountEntity> call({
    required String code,
    required CreateDiscountParams params,
  }) => _repository.updateDiscount(code: code, params: params);
}
