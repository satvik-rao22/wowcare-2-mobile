import '../repositories/discount_repository.dart';

class DeleteDiscountUseCase {
  DeleteDiscountUseCase(this._repository);

  final DiscountRepository _repository;

  Future<void> call(String code) => _repository.deleteDiscount(code);
}
