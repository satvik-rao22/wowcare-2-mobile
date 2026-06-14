import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CreateRefundUseCase {
  CreateRefundUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoicePaymentResultEntity> call(InvoicePaymentParams params) =>
      _repository.createRefund(params);
}
