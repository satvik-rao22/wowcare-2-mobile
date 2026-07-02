import '../entities/family_ledger_entity.dart';
import '../entities/family_summary_entity.dart';
import '../entities/invoice_analytics_entity.dart';
import '../entities/invoice_entity.dart';
import '../entities/invoice_list_entity.dart';

abstract class InvoiceRepository {
  Future<InvoiceResultEntity> createInvoice(CreateInvoiceParams params);
  Future<InvoiceAnalyticsEntity> getAnalytics({
    required String organizationCode,
    required String school,
    int? year,
  });
  Future<InvoiceOverviewEntity> getOverview({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Paginated Transactions list (`GET /api/v1/invoices/transactions`).
  /// [type] (e.g. `PAYMENT`, `REFUND`, `PAYMENT,REFUND`) and [status]
  /// (e.g. `SUCCESS`, `IN_PROCESS`) filter the rows server-side.
  Future<InvoiceTransactionsPage> getTransactions({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    String? status,
    int page,
    int size,
  });

  /// Full invoice detail (`GET /api/v1/invoices/by-code/{code}`).
  Future<InvoiceListItemEntity> getInvoiceByCode(String code);

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

  /// A family's full billing ledger
  /// (`GET /api/v1/invoices/family-ledger`).
  Future<FamilyLedgerEntity> getFamilyLedger({
    required String organizationCode,
    required String school,
    required String ownerType,
    required String ownerCode,
  });

  /// Guardian-scoped family billing ledger
  /// (`GET /api/v1/invoices/family-ledger/by-guardian`).
  Future<FamilyLedgerEntity> getGuardianFamilyLedger({
    required String organizationCode,
    required String school,
    required String guardianCode,
  });
  Future<InvoicePaymentResultEntity> createPayment(InvoicePaymentParams params);
  Future<InvoicePaymentResultEntity> createRefund(InvoicePaymentParams params);
  Future<InvoicePaymentResultEntity> createCredit(CreateCreditParams params);
  Future<InvoiceResultEntity> updateInvoice({
    required String code,
    required UpdateInvoiceParams params,
  });
  Future<void> deleteInvoice(String code);
  Future<InvoiceResultEntity> cancelInvoice(String code);
  Future<InvoiceResultEntity> issueInvoice(String code);
  Future<InvoiceResultEntity> resendInvoice(String code);
}
