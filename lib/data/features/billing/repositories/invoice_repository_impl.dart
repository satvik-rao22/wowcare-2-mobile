import 'package:wowcare/core/util/billing_events.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/data/features/billing/datasources/invoice_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/invoice_request_models.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_analytics_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._dataSource, this._cacheManager);

  final InvoiceRemoteDataSource _dataSource;
  final CacheManager _cacheManager;

  /// Runs after every successful billing mutation: drops all cached billing /
  /// ledger reads so the next fetch is fresh, then signals open billing screens
  /// to refresh via [BillingEvents]. Cache clearing is best-effort — a storage
  /// hiccup never blocks the refresh signal.
  Future<void> _onBillingMutation() async {
    try {
      await _cacheManager.clearFeatureCaches('billing');
      await _cacheManager.clearFeatureCaches('ledger');
    } catch (_) {
      // Ignore cache errors — the refresh signal below still forces a refetch.
    }
    BillingEvents.notifyChanged();
  }

  @override
  Future<InvoiceResultEntity> createInvoice(CreateInvoiceParams params) async {
    final model = await _dataSource.createInvoice(_toRequest(params));
    await _onBillingMutation();
    return _mapResult(model);
  }

  @override
  Future<InvoiceAnalyticsEntity> getAnalytics({
    required String organizationCode,
    required String school,
    int? year,
  }) async {
    final m = await _dataSource.getAnalytics(
      organizationCode: organizationCode,
      school: school,
      year: year,
    );
    return InvoiceAnalyticsEntity(
      revenue: m.revenue
          .map((e) => AnalyticsMonthValueEntity(name: e.name, value: e.value))
          .toList(),
      invoiced: m.invoiced
          .map((e) => AnalyticsMonthValueEntity(name: e.name, value: e.value))
          .toList(),
      refunds: m.refunds
          .map((e) => AnalyticsMonthValueEntity(name: e.name, value: e.value))
          .toList(),
      subsidies: m.subsidies
          .map(
            (e) => AnalyticsSubsidyEntity(
              name: e.name,
              invoiced: e.invoiced,
              received: e.received,
              balance: e.balance,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<InvoiceOverviewEntity> getOverview({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final m = await _dataSource.getOverview(
      organizationCode: organizationCode,
      school: school,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    return InvoiceOverviewEntity(
      amountInvoiced: m.amountInvoiced,
      paid: m.paid,
      refunded: m.refunded,
      netPaid: m.netPaid,
      inProcess: m.inProcess,
      outstanding: m.outstanding,
    );
  }

  @override
  Future<InvoiceTransactionsPage> getTransactions({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final m = await _dataSource.getTransactions(
      organizationCode: organizationCode,
      school: school,
      dateFrom: dateFrom,
      dateTo: dateTo,
      type: type,
      status: status,
      page: page,
      size: size,
    );
    return m.toEntity();
  }

  @override
  Future<InvoiceListItemEntity> getInvoiceByCode(String code) async {
    final m = await _dataSource.getInvoiceByCode(code);
    return m.toEntity();
  }

  @override
  Future<PaginatedInvoicesEntity> listInvoices({
    required String organizationCode,
    required String school,
    int page = 0,
    int size = 20,
    String? search,
    String? status,
    String? invoiceStatus,
  }) async {
    final m = await _dataSource.listInvoices(
      organizationCode: organizationCode,
      school: school,
      page: page,
      size: size,
      search: search,
      status: status,
      invoiceStatus: invoiceStatus,
    );
    return m.toEntity();
  }

  @override
  Future<List<FamilySummaryEntity>> getFamilySummary({
    required String organizationCode,
    required String school,
  }) async {
    final models = await _dataSource.getFamilySummary(
      organizationCode: organizationCode,
      school: school,
    );
    return models
        .map(
          (m) => FamilySummaryEntity(
            ownerType: m.ownerType,
            ownerCode: m.ownerCode,
            studentCodes: m.studentCodes,
            familyName: m.familyName,
            guardianName: m.guardianName,
            lastInvoiceAmount: m.lastInvoiceAmount,
            lastInvoiceDate: m.lastInvoiceDate,
            lastInvoiceDueDate: m.lastInvoiceDueDate,
            lastInvoiceStatus: m.lastInvoiceStatus,
            lastPaymentAmount: m.lastPaymentAmount,
            lastPaymentDate: m.lastPaymentDate,
            lastPaymentMethod: m.lastPaymentMethod,
            openBalance: m.openBalance,
          ),
        )
        .toList();
  }

  @override
  Future<FamilyLedgerEntity> getFamilyLedger({
    required String organizationCode,
    required String school,
    required String ownerType,
    required String ownerCode,
  }) async {
    final m = await _dataSource.getFamilyLedger(
      organizationCode: organizationCode,
      school: school,
      ownerType: ownerType,
      ownerCode: ownerCode,
    );
    return m.toEntity();
  }

  @override
  Future<FamilyLedgerEntity> getGuardianFamilyLedger({
    required String organizationCode,
    required String school,
    required String guardianCode,
  }) async {
    final m = await _dataSource.getGuardianFamilyLedger(
      organizationCode: organizationCode,
      school: school,
      guardianCode: guardianCode,
    );
    return m.toEntity();
  }

  @override
  Future<InvoiceResultEntity> updateInvoice({
    required String code,
    required UpdateInvoiceParams params,
  }) async {
    final model = await _dataSource.updateInvoice(
      code,
      _toUpdateRequest(params),
    );
    await _onBillingMutation();
    return _mapResult(model);
  }

  @override
  Future<InvoicePaymentResultEntity> createPayment(
    InvoicePaymentParams params,
  ) async {
    final m = await _dataSource.createPayment(_toPaymentRequest(params));
    await _onBillingMutation();
    return _mapPaymentResult(m);
  }

  @override
  Future<InvoicePaymentResultEntity> createRefund(
    InvoicePaymentParams params,
  ) async {
    final m = await _dataSource.createRefund(_toPaymentRequest(params));
    await _onBillingMutation();
    return _mapPaymentResult(m);
  }

  @override
  Future<InvoicePaymentResultEntity> createCredit(
    CreateCreditParams params,
  ) async {
    final m = await _dataSource.createCredit(
      CreateCreditRequestModel(
        schoolCode: params.schoolCode,
        amount: params.amount,
        ownerType: params.ownerType,
        ownerCode: params.ownerCode,
        studentCode: params.studentCode,
        reason: params.reason,
        description: params.description,
      ),
    );
    await _onBillingMutation();
    return _mapPaymentResult(m);
  }

  @override
  Future<void> deleteInvoice(String code) async {
    await _dataSource.deleteInvoice(code);
    await _onBillingMutation();
  }

  @override
  Future<InvoiceResultEntity> cancelInvoice(String code) async {
    final result = _mapResult(await _dataSource.cancelInvoice(code));
    await _onBillingMutation();
    return result;
  }

  @override
  Future<InvoiceResultEntity> issueInvoice(String code) async {
    final result = _mapResult(await _dataSource.issueInvoice(code));
    await _onBillingMutation();
    return result;
  }

  @override
  Future<InvoiceResultEntity> resendInvoice(String code) async {
    final result = _mapResult(await _dataSource.resendInvoice(code));
    await _onBillingMutation();
    return result;
  }

  // ─── Mappers ────────────────────────────────────────────────────────────────

  InvoicePaymentResultEntity _mapPaymentResult(InvoicePaymentResultModel m) =>
      InvoicePaymentResultEntity(
        ledgerCode: m.ledgerCode,
        amount: m.amount,
        amountApplied: m.amountApplied,
        creditBalance: m.creditBalance,
      );

  InvoicePaymentRequestModel _toPaymentRequest(InvoicePaymentParams p) =>
      InvoicePaymentRequestModel(
        schoolCode: p.schoolCode,
        amount: p.amount,
        date: p.date,
        ownerType: p.ownerType,
        ownerCode: p.ownerCode,
        studentCode: p.studentCode,
        method: p.method,
        reference: p.reference,
        narration: p.narration,
      );

  InvoiceResultEntity _mapResult(InvoiceResultModel model) =>
      InvoiceResultEntity(
        code: model.code,
        status: model.status,
        invoiceStatus: model.invoiceStatus,
        total: model.total,
      );

  CreateInvoiceRequestModel _toRequest(CreateInvoiceParams p) =>
      CreateInvoiceRequestModel(
        organizationCode: p.organizationCode,
        schoolCode: p.schoolCode,
        studentCode: p.studentCode,
        issueDate: p.issueDate,
        dueDate: p.dueDate,
        periodStart: p.periodStart,
        periodEnd: p.periodEnd,
        notes: p.notes,
        currency: p.currency,
        items: p.items
            .map(
              (i) => CreateInvoiceItemRequestModel(
                itemType: i.itemType,
                description: i.description,
                amount: i.amount,
                quantity: i.quantity,
                sourceCode: i.sourceCode,
                valueType: i.valueType,
                valueInput: i.valueInput,
              ),
            )
            .toList(),
      );

  UpdateInvoiceRequestModel _toUpdateRequest(UpdateInvoiceParams p) =>
      UpdateInvoiceRequestModel(
        organizationCode: p.organizationCode,
        schoolCode: p.schoolCode,
        studentCode: p.studentCode,
        ownerType: p.ownerType,
        ownerCode: p.ownerCode,
        issueDate: p.issueDate,
        dueDate: p.dueDate,
        periodStart: p.periodStart,
        periodEnd: p.periodEnd,
        currency: p.currency,
        notes: p.notes,
        items: p.items
            ?.map(
              (i) => CreateInvoiceItemRequestModel(
                itemType: i.itemType,
                description: i.description,
                amount: i.amount,
                quantity: i.quantity,
                sourceCode: i.sourceCode,
                valueType: i.valueType,
                valueInput: i.valueInput,
              ),
            )
            .toList(),
      );
}
