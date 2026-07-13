import '../repositories/discount_repository.dart';

class DeactivateDiscountUseCase {
  DeactivateDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<void> call(String code) => _repository.deactivateDiscount(code);
}
