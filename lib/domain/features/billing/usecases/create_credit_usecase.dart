import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

/// Adds account credit for a family/owner (`POST /api/v1/invoices/credits`).
class CreateCreditUseCase {
  CreateCreditUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoicePaymentResultEntity> call(CreateCreditParams params) =>
      _repository.createCredit(params);
}
