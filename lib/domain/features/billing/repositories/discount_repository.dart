import '../entities/discount_entity.dart';

abstract class DiscountRepository {
  Future<DiscountPageEntity> getDiscounts({
    required String school,
    String? name,
    String? status,
    int page = 0,
    int size = 200,
  });

  Future<DiscountEntity> createDiscount(CreateDiscountParams params);

  Future<DiscountEntity> updateDiscount({
    required String code,
    required CreateDiscountParams params,
  });

  Future<void> deleteDiscount(String code);
  Future<void> deactivateDiscount(String code);
  Future<void> reactivateDiscount(String code);
}
