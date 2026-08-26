import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/data/features/billing/models/family_ledger_models.dart';
import 'package:wowcare/data/features/billing/models/family_summary_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_analytics_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_list_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_overview_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_request_models.dart';
import 'package:wowcare/data/features/billing/models/invoice_transaction_models.dart';

/// Serializes a date-range filter bound the user picked in the school's
/// calendar. Same rule as the invoice request models: a picked date is a
/// calendar day, so `toUtc()` would read it in the DEVICE's zone and shift the
/// window by a day (an IST-picked Jul 17 becomes Jul 16T18:30Z), silently
/// dropping/adding a day's transactions.
String _schoolRangeIso(DateTime picked) =>
    SchoolZoneDateTime.utcFromSchoolWallClockDateTime(
      picked,
      SchoolTimezoneResolver.lastKnownTimeZone,
    ).toIso8601String();

abstract class InvoiceRemoteDataSource {
  Future<InvoiceResultModel> createInvoice(CreateInvoiceRequestModel request);
  Future<InvoiceAnalyticsModel> getAnalytics({
    required String organizationCode,
    required String school,
    int? year,
  });
  Future<InvoiceOverviewModel> getOverview({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<InvoiceTransactionsPageModel> getTransactions({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    String? status,
    int page,
    int size,
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
  Future<FamilyLedgerModel> getGuardianFamilyLedger({
    required String organizationCode,
    required String school,
    required String guardianCode,
  });
  Future<InvoicePaymentResultModel> createPayment(
      InvoicePaymentRequestModel request);
  Future<InvoicePaymentResultModel> createRefund(
      InvoicePaymentRequestModel request);
  Future<InvoicePaymentResultModel> createCredit(
      CreateCreditRequestModel request);
  Future<InvoiceResultModel> updateInvoice(
      String code, UpdateInvoiceRequestModel request);
  Future<void> deleteInvoice(String code);
  Future<InvoiceResultModel> cancelInvoice(String code);
  Future<InvoiceResultModel> issueInvoice(String code);
  Future<InvoiceResultModel> resendInvoice(String code);
  Future<CheckRecipientsResultModel> checkRecipients({
    required String schoolCode,
    required List<String> studentCodes,
  });
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
  Future<InvoiceAnalyticsModel> getAnalytics({
    required String organizationCode,
    required String school,
    int? year,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesAnalytics),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'school': school,
        if (year != null) 'year': year,
      },
    );
    return InvoiceAnalyticsModel.fromJson(response.data ?? {});
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
        if (dateFrom != null) 'dateFrom': _schoolRangeIso(dateFrom),
        if (dateTo != null) 'dateTo': _schoolRangeIso(dateTo),
      },
    );
    return InvoiceOverviewModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoiceTransactionsPageModel> getTransactions({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesTransactions),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'school': school,
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (dateFrom != null) 'dateFrom': _schoolRangeIso(dateFrom),
        if (dateTo != null) 'dateTo': _schoolRangeIso(dateTo),
        'page': page,
        'size': size,
      },
    );
    return InvoiceTransactionsPageModel.fromJson(response.data ?? {});
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
  Future<FamilyLedgerModel> getGuardianFamilyLedger({
    required String organizationCode,
    required String school,
    required String guardianCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesFamilyLedgerByGuardian),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'school': school,
        'guardianCode': guardianCode,
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
  Future<InvoicePaymentResultModel> createCredit(
      CreateCreditRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceCredits),
      data: request.toJson(),
    );
    return InvoicePaymentResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<InvoiceResultModel> updateInvoice(
      String code, UpdateInvoiceRequestModel request) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoiceDraft(code)),
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

  @override
  Future<CheckRecipientsResultModel> checkRecipients({
    required String schoolCode,
    required List<String> studentCodes,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.invoicesCheckRecipients),
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
      data: studentCodes,
    );
    return CheckRecipientsResultModel.fromJson(response.data ?? {});
  }
}
