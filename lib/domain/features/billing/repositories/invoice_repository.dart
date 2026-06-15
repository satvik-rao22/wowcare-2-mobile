import '../entities/family_summary_entity.dart';
import '../entities/invoice_entity.dart';
import '../entities/invoice_list_entity.dart';

abstract class InvoiceRepository {
  Future<InvoiceResultEntity> createInvoice(CreateInvoiceParams params);
  Future<InvoiceOverviewEntity> getOverview({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Paginated invoice list (`GET /api/v1/invoices/{organizationCode}`).
  Future<PaginatedInvoicesEntity> listInvoices({
    required String organizationCode,
    required String school,
    int page = 0,
    int size = 20,
    String? search,
    String? status,
    String? invoiceStatus,
  });
  Future<List<FamilySummaryEntity>> getFamilySummary({
    required String organizationCode,
    required String school,
  });
  Future<InvoicePaymentResultEntity> createPayment(InvoicePaymentParams params);
  Future<InvoicePaymentResultEntity> createRefund(InvoicePaymentParams params);
  Future<InvoiceResultEntity> updateInvoice({
    required String code,
    required UpdateInvoiceParams params,
  });
  Future<void> deleteInvoice(String code);
  Future<InvoiceResultEntity> cancelInvoice(String code);
  Future<InvoiceResultEntity> issueInvoice(String code);
  Future<InvoiceResultEntity> resendInvoice(String code);
}
