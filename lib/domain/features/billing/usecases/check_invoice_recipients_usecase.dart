import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CheckInvoiceRecipientsUseCase {
  CheckInvoiceRecipientsUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<CheckRecipientsResultEntity> call({
    required String schoolCode,
    required List<String> studentCodes,
  }) =>
      _repository.checkRecipients(
        schoolCode: schoolCode,
        studentCodes: studentCodes,
      );
}
