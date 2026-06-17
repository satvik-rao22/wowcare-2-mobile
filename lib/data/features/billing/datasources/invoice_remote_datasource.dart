import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/billing/models/family_ledger_models.dart';
import 'package:wowcare/data/features/billing/models/family_summary_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_list_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_overview_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_request_models.dart';

abstract class InvoiceRemoteDataSource {
  Future<InvoiceResultModel> createInvoice(CreateInvoiceRequestModel request);
  Future<InvoiceOverviewModel> getOverview({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<InvoiceListItemModel> getInvoiceByCode(String code);
  Future<PaginatedInvoicesModel> listInvoices({
    required String organizationCode,
    required String school,
    int page,
    int size,
    String? search,
    String? status,
    String? invoiceStatus,
  });
  Future<List<FamilySummaryModel>> getFamilySummary({
    required String organizationCode,
    required String school,
  });
  Future<FamilyLedgerModel> getFamilyLedger({
    required String organizationCode,
    required String school,
    required String ownerType,
    required String ownerCode,
  });
  Future<InvoicePaymentResultModel> createPayment(
      InvoicePaymentRequestModel request);
  Future<InvoicePaymentResultModel> createRefund(
      InvoicePaymentRequestModel request);
  Future<InvoiceResultModel> updateInvoice(
      String code, UpdateInvoiceRequestModel request);
  Future<void> deleteInvoice(String code);
  Future<InvoiceResultModel> cancelInvoice(String code);
  Future<InvoiceResultModel> issueInvoice(String code);
  Future<InvoiceResultModel> resendInvoice(String code);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  InvoiceRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<InvoiceResultModel> createInvoice(
      CreateInvoiceRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoices),
      data: request.toJson(),
    );
    return InvoiceResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoiceOverviewModel> getOverview({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesOverview),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'school': school,
        if (dateFrom != null) 'dateFrom': dateFrom.toUtc().toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toUtc().toIso8601String(),
      },
    );
    return InvoiceOverviewModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoiceListItemModel> getInvoiceByCode(String code) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceDetailByCode(code)),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return InvoiceListItemModel.fromJson(data);
  }

  @override
  Future<PaginatedInvoicesModel> listInvoices({
    required String organizationCode,
    required String school,
    int page = 0,
    int size = 20,
    String? search,
    String? status,
    String? invoiceStatus,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesByOrganization(organizationCode)),
      queryParameters: <String, dynamic>{
        'school': school,
        'page': page,
        'size': size,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (invoiceStatus != null && invoiceStatus.trim().isNotEmpty)
          'invoiceStatus': invoiceStatus.trim(),
      },
    );
    return PaginatedInvoicesModel.fromJson(response.data ?? {});
  }

  @override
  Future<List<FamilySummaryModel>> getFamilySummary({
    required String organizationCode,
    required String school,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesFamilySummary),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'school': school,
      },
    );
    return FamilySummaryModel.listFromJson(response.data ?? {});
  }

  @override
  Future<FamilyLedgerModel> getFamilyLedger({
    required String organizationCode,
    required String school,
    required String ownerType,
    required String ownerCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesFamilyLedger),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'school': school,
        if (ownerType.trim().isNotEmpty) 'ownerType': ownerType,
        'ownerCode': ownerCode,
      },
    );
    return FamilyLedgerModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoicePaymentResultModel> createPayment(
      InvoicePaymentRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicePayments),
      data: request.toJson(),
    );
    return InvoicePaymentResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoicePaymentResultModel> createRefund(
      InvoicePaymentRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceRefunds),
      data: request.toJson(),
    );
    return InvoicePaymentResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoiceResultModel> updateInvoice(
      String code, UpdateInvoiceRequestModel request) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceByCode(code)),
      data: request.toJson(),
    );
    return InvoiceResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<void> deleteInvoice(String code) async {
    await _client.delete<void>(ApiPaths.url(ApiPaths.invoiceByCode(code)));
  }

  @override
  Future<InvoiceResultModel> cancelInvoice(String code) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceCancel(code)),
    );
    return InvoiceResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoiceResultModel> issueInvoice(String code) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceIssue(code)),
    );
    return InvoiceResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoiceResultModel> resendInvoice(String code) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceResend(code)),
    );
    return InvoiceResultModel.fromJson(response.data ?? {});
  }
}
