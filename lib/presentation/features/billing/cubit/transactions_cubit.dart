import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/cancel_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_overview_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoices_usecase.dart';

import '../widgets/transactions/transaction_item.dart';

part 'transactions_state.dart';

enum TransactionStatus { paid, inProcess, unpaid, refund, failed }

class TransactionRecord {
  const TransactionRecord({required this.item, required this.status});

  final TransactionItem item;
  final TransactionStatus status;
}

/// Owns the Transactions tab's paginated invoice list, search state, and the
/// invoice overview totals (amount invoiced / net paid / outstanding …).
///
/// - List rows come from `GET /api/v1/invoices/{organizationCode}` (paginated,
///   server-side search). Page 0 is loaded by [loadInvoices]; [loadNextPage]
///   appends subsequent pages for infinite scroll / "load more".
/// - Overview totals (stat bar) come from `GET /api/v1/invoices/overview` and
///   are the only thing the date range filters — the list endpoint has no date
///   filter, so [setDateRange] refreshes the overview only.
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit({
    required GetInvoiceOverviewUseCase getOverview,
    required GetInvoicesUseCase getInvoices,
    required CancelInvoiceUseCase cancelInvoice,
    required DeleteInvoiceUseCase deleteInvoice,
    required StorageService storage,
  })  : _getOverview = getOverview,
        _getInvoices = getInvoices,
        _cancelInvoice = cancelInvoice,
        _deleteInvoice = deleteInvoice,
        _storage = storage,
        super(TransactionsState.initial());

  final GetInvoiceOverviewUseCase _getOverview;
  final GetInvoicesUseCase _getInvoices;
  final CancelInvoiceUseCase _cancelInvoice;
  final DeleteInvoiceUseCase _deleteInvoice;
  final StorageService _storage;

  static const int _pageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 400);

  /// Generation guard: a fresh [loadInvoices] (page 0 / search change)
  /// invalidates any in-flight [loadNextPage] so a stale batch is never
  /// appended.
  int _listRequestId = 0;
  Timer? _searchDebounceTimer;

  String _org = '';
  String _school = '';

  /// Resolves and caches the org/school context. Returns false when either is
  /// missing (not signed in / not selected), in which case callers no-op.
  Future<bool> _ensureContext() async {
    if (_org.isNotEmpty && _school.isNotEmpty) return true;
    _org = (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    _school = (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    return _org.isNotEmpty && _school.isNotEmpty;
  }

  /// Loads page 0 of the invoice list and the overview totals. Call from the
  /// view's initState and from pull-to-refresh.
  Future<void> load() async {
    await Future.wait<void>([loadInvoices(), loadOverview()]);
  }

  /// Loads the invoice overview for the current (optional) date range. Silent
  /// on success; surfaces errors so the stat bar can fall back to zeros.
  Future<void> loadOverview({DateTime? dateFrom, DateTime? dateTo}) async {
    if (!await _ensureContext()) return;
    try {
      final overview = await _getOverview(
        organizationCode: _org,
        school: _school,
        dateFrom: dateFrom ?? state.dateFrom,
        dateTo: dateTo ?? state.dateTo,
      );
      if (isClosed) return;
      emit(state.copyWith(overview: () => overview));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  /// Fetches the first page of invoices, replacing the current list. Used for
  /// the initial load, search changes, and refresh.
  Future<void> loadInvoices() async {
    if (!await _ensureContext()) return;
    final int requestId = ++_listRequestId;
    emit(state.copyWith(isLoadingList: true));
    try {
      final pageData = await _getInvoices(
        organizationCode: _org,
        school: _school,
        page: 0,
        size: _pageSize,
        search: state.searchQuery,
      );
      if (isClosed || requestId != _listRequestId) return;
      emit(
        state.copyWith(
          transactions: _toRecords(pageData.items, startIndex: 0),
          page: 0,
          hasMore: pageData.hasMore,
          isLoadingList: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || requestId != _listRequestId) return;
      emit(
        state.copyWith(
          isLoadingList: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Appends the next page to the list. No-ops while a page/refresh is in
  /// flight or when there is nothing more to load.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || state.isLoadingList || !state.hasMore) return;
    if (!await _ensureContext()) return;

    // Bind to the active list generation; a concurrent refresh discards this.
    final int requestId = _listRequestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final pageData = await _getInvoices(
        organizationCode: _org,
        school: _school,
        page: state.page + 1,
        size: _pageSize,
        search: state.searchQuery,
      );
      if (isClosed || requestId != _listRequestId) return;
      emit(
        state.copyWith(
          transactions: <TransactionRecord>[
            ...state.transactions,
            ..._toRecords(pageData.items, startIndex: state.transactions.length),
          ],
          page: pageData.page,
          hasMore: pageData.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || requestId != _listRequestId) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Applies a date range and refetches the overview for it. The list endpoint
  /// has no date filter, so the rows are unaffected.
  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    emit(state.copyWith(dateFrom: () => from, dateTo: () => to));
    await loadOverview(dateFrom: from, dateTo: to);
  }

  /// Cancels an invoice (`PATCH /api/v1/invoices/{code}/cancel`) then refreshes
  /// the list + totals so the new status is reflected.
  Future<void> cancelInvoice(String code) async {
    if (code.trim().isEmpty) return;
    try {
      await _cancelInvoice(code);
      if (isClosed) return;
      emit(state.copyWith(successMessage: 'Invoice cancelled'));
      await loadInvoices();
      await loadOverview();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  /// Deletes an invoice (`DELETE /api/v1/invoices/{code}`) then refreshes the
  /// list + totals.
  Future<void> deleteInvoice(String code) async {
    if (code.trim().isEmpty) return;
    try {
      await _deleteInvoice(code);
      if (isClosed) return;
      emit(state.copyWith(successMessage: 'Invoice deleted'));
      await loadInvoices();
      await loadOverview();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, loadInvoices);
  }

  void clearSearch() {
    _searchDebounceTimer?.cancel();
    emit(state.copyWith(searchQuery: ''));
    loadInvoices();
  }

  List<TransactionRecord> _toRecords(
    List<InvoiceListItemEntity> invoices, {
    required int startIndex,
  }) {
    return List<TransactionRecord>.generate(invoices.length, (i) {
      final invoice = invoices[i];
      return TransactionRecord(
        status: _statusFor(invoice),
        item: TransactionItem.fromInvoice(invoice, id: startIndex + i + 1),
      );
    });
  }

  TransactionStatus _statusFor(InvoiceListItemEntity invoice) {
    final raw = (invoice.invoiceStatus.isNotEmpty
            ? invoice.invoiceStatus
            : invoice.status)
        .toUpperCase();
    if (raw.contains('REFUND')) return TransactionStatus.refund;
    if (raw == 'PAID') return TransactionStatus.paid;
    if (raw.contains('PARTIAL') ||
        raw.contains('PROCESS') ||
        raw.contains('PENDING')) {
      return TransactionStatus.inProcess;
    }
    if (raw.contains('FAIL') || raw.contains('CANCEL')) {
      return TransactionStatus.failed;
    }
    return TransactionStatus.unpaid;
  }

  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
  }
}
