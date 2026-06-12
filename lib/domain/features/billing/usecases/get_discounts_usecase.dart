import '../entities/discount_entity.dart';
import '../repositories/discount_repository.dart';

class GetDiscountsUseCase {
  GetDiscountsUseCase(this._repository);

  final DiscountRepository _repository;

  Future<DiscountPageEntity> call({
    required String school,
    String? name,
    String? status,
    int page = 0,
    int size = 10,
  }) =>
      _repository.getDiscounts(
        school: school,
        name: name,
        status: status,
        page: page,
        size: size,
      );
}
