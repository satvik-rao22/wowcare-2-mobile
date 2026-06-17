import 'package:wowcare/data/features/billing/datasources/invoice_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/invoice_request_models.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._dataSource);

  final InvoiceRemoteDataSource _dataSource;

  @override
  Future<InvoiceResultEntity> createInvoice(CreateInvoiceParams params) async {
    final model = await _dataSource.createInvoice(_toRequest(params));
    return _mapResult(model);
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
        .map((m) => FamilySummaryEntity(
              ownerType: m.ownerType,
              ownerCode: m.ownerCode,
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
            ))
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
  Future<InvoiceResultEntity> updateInvoice({
    required String code,
    required UpdateInvoiceParams params,
  }) async {
    final model = await _dataSource.updateInvoice(code, _toUpdateRequest(params));
    return _mapResult(model);
  }

  @override
  Future<InvoicePaymentResultEntity> createPayment(
      InvoicePaymentParams params) async {
    final m = await _dataSource.createPayment(_toPaymentRequest(params));
    return _mapPaymentResult(m);
  }

  @override
  Future<InvoicePaymentResultEntity> createRefund(
      InvoicePaymentParams params) async {
    final m = await _dataSource.createRefund(_toPaymentRequest(params));
    return _mapPaymentResult(m);
  }

  @override
  Future<void> deleteInvoice(String code) => _dataSource.deleteInvoice(code);

  @override
  Future<InvoiceResultEntity> cancelInvoice(String code) async =>
      _mapResult(await _dataSource.cancelInvoice(code));

  @override
  Future<InvoiceResultEntity> issueInvoice(String code) async =>
      _mapResult(await _dataSource.issueInvoice(code));

  @override
  Future<InvoiceResultEntity> resendInvoice(String code) async =>
      _mapResult(await _dataSource.resendInvoice(code));

  // ─── Mappers ────────────────────────────────────────────────────────────────

  InvoicePaymentResultEntity _mapPaymentResult(
          InvoicePaymentResultModel m) =>
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
        notes: p.notes,
        currency: p.currency,
        items: p.items
            .map((i) => CreateInvoiceItemRequestModel(
                  itemType: i.itemType,
                  description: i.description,
                  amount: i.amount,
                  quantity: i.quantity,
                  sourceCode: i.sourceCode,
                  valueType: i.valueType,
                  valueInput: i.valueInput,
                ))
            .toList(),
      );

  UpdateInvoiceRequestModel _toUpdateRequest(UpdateInvoiceParams p) =>
      UpdateInvoiceRequestModel(
        code: p.code,
        studentCode: p.studentCode,
        issueDate: p.issueDate,
        dueDate: p.dueDate,
        status: p.status,
        invoiceStatus: p.invoiceStatus,
        amount: p.amount,
        total: p.total,
        paidAmount: p.paidAmount,
        subjectOwnerType: p.subjectOwnerType,
        subjectOwnerCode: p.subjectOwnerCode,
        subscriptionCode: p.subscriptionCode,
        items: p.items
            ?.map((i) => UpdateInvoiceItemRequestModel(
                  description: i.description,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  totalPrice: i.totalPrice,
                ))
            .toList(),
      );
}
