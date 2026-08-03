import '../entities/invoice_catalog_entities.dart';

abstract class InvoiceCatalogRepository {
  Future<List<FeeStructureEntity>> getFeeStructures({
    required String school,
    String? status,
  });

  Future<List<OtherFeeEntity>> getOtherFees({
    required String school,
    String? status,
  });

  Future<List<SubsidyEntity>> getSubsidies({
    required String school,
    String? status,
  });
}
