import '../repositories/discount_repository.dart';

class ReactivateDiscountUseCase {
  ReactivateDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<void> call(String code) => _repository.reactivateDiscount(code);
}
