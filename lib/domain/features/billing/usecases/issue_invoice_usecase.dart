import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class IssueInvoiceUseCase {
  IssueInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceResultEntity> call(String code) =>
      _repository.issueInvoice(code);
}
