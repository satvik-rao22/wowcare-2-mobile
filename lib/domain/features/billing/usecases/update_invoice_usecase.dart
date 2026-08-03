import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class UpdateInvoiceUseCase {
  UpdateInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceResultEntity> call({
    required String code,
    required UpdateInvoiceParams params,
  }) =>
      _repository.updateInvoice(code: code, params: params);
}
