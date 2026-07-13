import 'package:wowcare/data/features/billing/datasources/invoice_catalog_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/invoice_catalog_models.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_catalog_entities.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_catalog_repository.dart';

class InvoiceCatalogRepositoryImpl implements InvoiceCatalogRepository {
  InvoiceCatalogRepositoryImpl(this._dataSource);

  final InvoiceCatalogRemoteDataSource _dataSource;

  @override
  Future<List<FeeStructureEntity>> getFeeStructures({
    required String school,
    String? status,
  }) async {
    final models =
        await _dataSource.getFeeStructures(school: school, status: status);
    return models.map(_mapFeeStructure).toList();
  }

  @override
  Future<List<OtherFeeEntity>> getOtherFees({
    required String school,
    String? status,
  }) async {
    final models =
        await _dataSource.getOtherFees(school: school, status: status);
    return models.map(_mapOtherFee).toList();
  }

  @override
  Future<List<SubsidyEntity>> getSubsidies({
    required String school,
    String? status,
  }) async {
    final models =
        await _dataSource.getSubsidies(school: school, status: status);
    return models.map(_mapSubsidy).toList();
  }

  // ─── Mappers ────────────────────────────────────────────────────────────────

  FeeStructureEntity _mapFeeStructure(FeeStructureModel m) => FeeStructureEntity(
        code: m.code,
        ageGroupName: m.ageGroupName,
        daysPerWeek: m.daysPerWeek,
        availabilityType: m.availabilityType,
        feesDetails: m.feesDetails.map(_mapFeeDetail).toList(),
        status: m.status,
      );

  FeeDetailEntity _mapFeeDetail(FeeDetailModel m) => FeeDetailEntity(
        code: m.code,
        billingCycle: m.billingCycle,
        cost: m.cost,
        status: m.status,
      );

  OtherFeeEntity _mapOtherFee(OtherFeeModel m) => OtherFeeEntity(
        code: m.code,
        description: m.description,
        cost: m.cost,
        status: m.status,
      );

  SubsidyEntity _mapSubsidy(SubsidyModel m) => SubsidyEntity(
        code: m.code,
        name: m.name,
        description: m.description,
        deductionAmount: m.deductionAmount,
        price: m.price,
        discountType: m.discountType,
        status: m.status,
      );
}
