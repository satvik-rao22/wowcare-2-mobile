import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CreatePaymentUseCase {
  CreatePaymentUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoicePaymentResultEntity> call(InvoicePaymentParams params) =>
      _repository.createPayment(params);
}
