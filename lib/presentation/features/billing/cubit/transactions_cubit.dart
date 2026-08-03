import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/presentation/features/billing/utils/billing_school_time.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/cancel_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_overview_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_transactions_usecase.dart';

import '../widgets/transactions/transaction_item.dart';

part 'transactions_state.dart';

enum TransactionStatus { paid, inProcess, unpaid, refund, failed }

/// The summary-card filters that scope the Transactions list to a subset of
/// rows via the `type` / `status` query params on `GET /invoices/transactions`.
///
/// - [netPaid]  → received payments and refunds together (refunds show negative)
/// - [paid]     → received payments only (refunds excluded)
/// - [inProcess]→ payments still settling (forte-scheduler)
/// - [refund]   → refunded transactions only
enum TransactionFilter { netPaid, paid, inProcess, refund }

extension TransactionFilterParams on TransactionFilter {
  /// `type` query param (a comma-joined list is sent verbatim).
  String get typeParam {
    switch (this) {
      case TransactionFilter.netPaid:
        return 'PAYMENT,REFUND';
      case TransactionFilter.paid:
      case TransactionFilter.inProcess:
        return 'PAYMENT';
      case TransactionFilter.refund:
        return 'REFUND';
    }
  }

  /// `status` query param, or null when the filter doesn't constrain status.
  String? get statusParam {
    switch (this) {
      case TransactionFilter.netPaid:
      case TransactionFilter.paid:
        return 'SUCCESS';
      case TransactionFilter.inProcess:
        return 'IN_PROCESS';
      case TransactionFilter.refund:
        return null;
    }
  }
}

class TransactionRecord {
  const TransactionRecord({required this.item, required this.status});

  final TransactionItem item;
  final TransactionStatus status;
}

/// Owns the Transactions tab's paginated list + search state and the invoice
/// overview totals (amount invoiced / net paid / outstanding …). Both come from
/// the billing API: `GET /invoices/transactions` (list) and `/invoices/overview`
/// (totals).
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit({
    required GetInvoiceOverviewUseCase getOverview,
    required GetInvoiceTransactionsUseCase getTransactions,
    required CancelInvoiceUseCase cancelInvoice,
    required DeleteInvoiceUseCase deleteInvoice,
    required StorageService storage,
  })  : _getOverview = getOverview,
        _getTransactions = getTransactions,
        _cancelInvoice = cancelInvoice,
        _deleteInvoice = deleteInvoice,
        _storage = storage,
        super(const TransactionsState.initial());

  final GetInvoiceOverviewUseCase _getOverview;
  final GetInvoiceTransactionsUseCase _getTransactions;
  final CancelInvoiceUseCase _cancelInvoice;
  final DeleteInvoiceUseCase _deleteInvoice;
  final StorageService _storage;

  static const int _pageSize = 10;

  /// Loads the invoice overview for the current (optional) date range. Silent
  /// on failure — the stat bar just falls back to zero totals.
  Future<void> loadOverview({DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty) return;
      final overview = await _getOverview(
        organizationCode: org,
        school: school,
        dateFrom: dateFrom ?? state.dateFrom,
        dateTo: dateTo ?? state.dateTo,
      );
      if (isClosed) return;
      emit(state.copyWith(overview: () => overview));
    } catch (e) {
      if (isClosed) return;
      // Totals fall back to zero; surface the error to the view.
      emit(state.copyWith(errorMessage: ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  /// Applies a date range and refetches the overview + transactions for it.
  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    emit(state.copyWith(dateFrom: () => from, dateTo: () => to));
    await Future.wait<void>([
      loadOverview(dateFrom: from, dateTo: to),
      loadTransactions(dateFrom: from, dateTo: to),
    ]);
  }

  /// Cancels an invoice (`PATCH /api/v1/invoices/{code}/cancel`) then refreshes
  /// the overview totals.
  Future<void> cancelInvoice(String code) async {
    if (code.trim().isEmpty) return;
    try {
      await _cancelInvoice(code);
      if (isClosed) return;
      emit(state.copyWith(successMessage: 'Invoice cancelled'));
      await loadOverview();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  /// Deletes an invoice (`DELETE /api/v1/invoices/{code}`), removes it from the
  /// local list, then refreshes the overview totals.
  Future<void> deleteInvoice(String code) async {
    if (code.trim().isEmpty) return;
    try {
      await _deleteInvoice(code);
      if (isClosed) return;
      final remaining = state.transactions
          .where((r) => r.item.invoiceCode?.trim() != code.trim())
          .toList();
      emit(state.copyWith(
        transactions: remaining,
        successMessage: 'Invoice deleted',
      ));
      await loadOverview();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  /// Applies (or clears, when [filter] is null) a summary-card filter and
  /// reloads the Transactions list from page 0 scoped to it. The overview
  /// totals are intentionally left untouched — they always reflect the full
  /// date range so the stat bar keeps showing every bucket.
  Future<void> applyFilter(TransactionFilter? filter) async {
    if (state.activeFilter == filter) return;
    emit(state.copyWith(activeFilter: () => filter));
    await loadTransactions();
  }

  /// Loads page 0 of the Transactions list (initial load / refresh / date
  /// change). Drives the shimmer via [TransactionsState.isLoading].
  Future<void> loadTransactions({DateTime? dateFrom, DateTime? dateTo}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty) {
        if (isClosed) return;
        emit(state.copyWith(isLoading: false, transactions: const []));
        return;
      }
      final filter = state.activeFilter;
      final result = await _getTransactions(
        organizationCode: org,
        school: school,
        dateFrom: dateFrom ?? state.dateFrom,
        dateTo: dateTo ?? state.dateTo,
        type: filter?.typeParam,
        status: filter?.statusParam,
        page: 0,
        size: _pageSize,
      );
      if (isClosed) return;
      emit(state.copyWith(
        transactions: _mapRecords(result.items),
        page: 0,
        hasMore: result.hasMore,
        isLoading: false,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  /// Appends the next transactions page (infinite scroll).
  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    final nextPage = state.page + 1;
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final filter = state.activeFilter;
      final result = await _getTransactions(
        organizationCode: org,
        school: school,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        type: filter?.typeParam,
        status: filter?.statusParam,
        page: nextPage,
        size: _pageSize,
      );
      if (isClosed) return;
      final existing =
          state.transactions.map((r) => r.item.invoiceCode).toSet();
      final merged = <TransactionRecord>[
        ...state.transactions,
        ..._mapRecords(result.items, startIndex: state.transactions.length)
            .where((r) => !existing.contains(r.item.invoiceCode)),
      ];
      emit(state.copyWith(
        transactions: merged,
        page: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  List<TransactionRecord> _mapRecords(
    List<InvoiceTransactionEntity> items, {
    int startIndex = 0,
  }) {
    return List<TransactionRecord>.generate(items.length, (i) {
      final t = items[i];
      // API sends a null studentName for family-level rows → show family name.
      final name = t.studentName.trim().isNotEmpty
          ? t.studentName.trim()
          : t.familyName;
      return TransactionRecord(
        status: _statusFromApi(t.status),
        item: TransactionItem(
          id: startIndex + i + 1,
          invoiceCode: t.invoiceCode.isNotEmpty ? t.invoiceCode : null,
          transactionType: t.type.isNotEmpty ? t.type : 'Invoice',
          date: t.date ?? billingSchoolNow(),
          amount: t.amount,
          paidAmount: t.paidAmount,
          refundedAmount: t.refundedAmount,
          status: t.status,
          description: t.description,
          studentName: name,
          familyCode: t.familyCode.isNotEmpty ? t.familyCode : null,
          classroom: '',
          studentCode: t.studentCode.isNotEmpty ? t.studentCode : null,
          refTable: t.type,
          paymentMode: (t.method ?? '').isNotEmpty ? t.method : null,
        ),
      );
    });
  }

  /// Maps the API status string to the [TransactionStatus] bucket.
  TransactionStatus _statusFromApi(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
        return TransactionStatus.paid;
      case 'IN_PROCESS':
      case 'IN PROGRESS':
      case 'PENDING':
        return TransactionStatus.inProcess;
      case 'REFUND':
      case 'REFUNDED':
        return TransactionStatus.refund;
      case 'FAILED':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.unpaid; // SENT / DRAFT / …
    }
  }

}
