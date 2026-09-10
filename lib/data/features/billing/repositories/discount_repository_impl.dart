import 'package:wowcare/data/features/billing/datasources/discount_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/discount_models.dart';
import 'package:wowcare/domain/features/billing/entities/discount_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/discount_repository.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  DiscountRepositoryImpl(this._dataSource);

  final DiscountRemoteDataSource _dataSource;

  @override
  Future<DiscountPageEntity> getDiscounts({
    required String school,
    String? name,
    String? status,
    int page = 0,
    int size = 200,
  }) async {
    final model = await _dataSource.getDiscounts(
      school: school,
      name: name,
      status: status,
      page: page,
      size: size,
    );
    return DiscountPageEntity(
      content: model.content.map(_mapModel).toList(),
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      number: model.number,
      last: model.last,
    );
  }

  @override
  Future<DiscountEntity> createDiscount(CreateDiscountParams params) async {
    final model =
        await _dataSource.createDiscount(_toRequest(params));
    return _mapModel(model);
  }

  @override
  Future<DiscountEntity> updateDiscount({
    required String code,
    required CreateDiscountParams params,
  }) async {
    final model = await _dataSource.updateDiscount(
      code: code,
      request: _toRequest(params),
    );
    return _mapModel(model);
  }

  @override
  Future<void> deleteDiscount(String code) =>
      _dataSource.deleteDiscount(code);

  @override
  Future<void> deactivateDiscount(String code) =>
      _dataSource.deactivateDiscount(code);

  @override
  Future<void> reactivateDiscount(String code) =>
      _dataSource.reactivateDiscount(code);

  // ─── Mappers ──────────────────────────────────────────────────────────────

  DiscountEntity _mapModel(DiscountModel m) => DiscountEntity(
        code: m.code,
        name: m.name,
        description: m.description,
        percentage: m.percentage,
        deductionAmount: m.deductionAmount,
        maxInvoiceAmount: m.maxInvoiceAmount,
        reference: m.reference,
        discountType: m.discountType,
        price: m.price,
        status: m.status,
        school: m.school,
        totalAmountDiscounted: m.totalAmountDiscounted,
      );

  DiscountRequestModel _toRequest(CreateDiscountParams p) =>
      DiscountRequestModel(
        name: p.name,
        school: p.school,
        percentage: p.percentage,
        description: p.description,
        deductionAmount: p.deductionAmount,
        maxInvoiceAmount: p.maxInvoiceAmount,
        reference: p.reference,
        discountType: p.discountType,
        price: p.price,
        status: p.status,
      );
}
