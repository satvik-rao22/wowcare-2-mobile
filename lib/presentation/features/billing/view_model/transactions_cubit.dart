import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/cancel_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_overview_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_transactions_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';

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
    required GetActiveClassroomsUseCase getActiveClassrooms,
    required GetTagNameCodeMapForSchoolUseCase getTagNameCodeMap,
    required GetStudentPageUseCase getStudentPage,
    required StorageService storage,
  })  : _getOverview = getOverview,
        _getTransactions = getTransactions,
        _cancelInvoice = cancelInvoice,
        _deleteInvoice = deleteInvoice,
        _getActiveClassrooms = getActiveClassrooms,
        _getTagNameCodeMap = getTagNameCodeMap,
        _getStudentPage = getStudentPage,
        _storage = storage,
        super(TransactionsState.initial());

  final GetInvoiceOverviewUseCase _getOverview;
  final GetInvoiceTransactionsUseCase _getTransactions;
  final CancelInvoiceUseCase _cancelInvoice;
  final DeleteInvoiceUseCase _deleteInvoice;
  final GetActiveClassroomsUseCase _getActiveClassrooms;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMap;
  final GetStudentPageUseCase _getStudentPage;
  final StorageService _storage;

  static const int _pageSize = 10;

  /// Students requested when resolving a classroom/tag selection — the whole
  /// matching set is needed at once to intersect against the loaded rows.
  static const int _studentLookupSize = 1000;

  /// The `type` query param for the current query. The funnel sheet's explicit
  /// selection wins over the stat-bar legend filter; they're kept mutually
  /// exclusive by [applyFilter] / [applyTransactionFilters]. Sent verbatim in
  /// its display casing (`type=Payment`), matching the web client.
  String? get _typeParam {
    final picked = state.selectedType?.trim() ?? '';
    return picked.isNotEmpty ? picked : state.activeFilter?.typeParam;
  }

  /// The `status` query param — legend-only now (see [TransactionsState.
  /// selectedStatus]'s doc). Status values go up in upper case
  /// (`status=OVERDUE`) to match the backend.
  String? get _statusParam {
    final picked = state.selectedStatus?.trim() ?? '';
    return picked.isNotEmpty
        ? picked.toUpperCase()
        : state.activeFilter?.statusParam;
  }

  /// The `mode` (payment method) query param. Sent verbatim in its display
  /// casing (`mode=Check`), matching the web client — unlike [_statusParam]
  /// this isn't upper-cased.
  String? get _modeParam {
    final picked = state.selectedMode?.trim() ?? '';
    return picked.isEmpty ? null : picked;
  }

  /// The `paymentStatus` query param — a distinct facet from [_statusParam]
  /// (see [TransactionsState.selectedPaymentStatus]'s doc). The backend
  /// value for "In Progress" is `In_Process` (confirmed from a live web
  /// request); Paid/Failed are sent as-is.
  String? get _paymentStatusParam {
    final picked = state.selectedPaymentStatus?.trim() ?? '';
    if (picked.isEmpty) return null;
    if (picked == BillingStrings.inProgress) return 'In_Process';
    return picked;
  }

  /// Monotonic load generation. Bumped whenever the logical list query changes
  /// (a fresh [loadTransactions], an [applyFilter], or a [setDateRange] — the
  /// latter two funnel through [loadTransactions]) so a slower in-flight
  /// response for a superseded query is discarded instead of clobbering (or
  /// appending into) the current list. [loadNextPage] captures the current
  /// generation WITHOUT bumping so a refresh/filter/date change mid-flight
  /// drops the stale page.
  int _generation = 0;

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

  /// Clear All on the date filter: back to the page-load default (the current
  /// school-calendar month, see [TransactionsState.initial]). Skips the
  /// refetch when the range is already the default, so a redundant tap costs
  /// nothing.
  Future<void> resetDateRange() async {
    final from = billingSchoolMonthStart();
    final to = billingSchoolMonthEnd();
    if (_sameDay(state.dateFrom, from) && _sameDay(state.dateTo, to)) return;
    await setDateRange(from, to);
  }

  static bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

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
  /// Applies a stat-bar legend filter. It owns the same `type`/`status` params
  /// as the funnel sheet, so it clears the sheet's Type/Status selections —
  /// otherwise the two would each overwrite half of the other's query.
  Future<void> applyFilter(TransactionFilter? filter) async {
    if (state.activeFilter == filter &&
        (state.selectedType ?? '').isEmpty &&
        (state.selectedStatus ?? '').isEmpty) {
      return;
    }
    emit(state.copyWith(
      activeFilter: () => filter,
      selectedType: () => null,
      selectedStatus: () => null,
    ));
    await loadTransactions();
  }

  /// Loads the funnel sheet's classroom and tag options.
  ///
  /// Non-fatal: the list is the screen's job, so an outage here leaves it
  /// rendered (the sheet simply offers fewer facets) rather than erroring.
  Future<void> loadFilterOptions() async {
    if (isClosed || state.classroomNames.isNotEmpty) return;
    try {
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final List<Classroom> classrooms =
          await _getActiveClassrooms(schoolCode: school);
      final Map<String, String> tagNameToCode =
          await _getTagNameCodeMap(schoolCode: school);

      final classroomNameToCode = <String, String>{
        for (final c in classrooms)
          if (c.name.trim().isNotEmpty) c.name.trim(): c.code.trim(),
      };

      if (isClosed) return;
      emit(state.copyWith(
        classroomNames: classroomNameToCode.keys.toList(),
        classroomNameToCode: classroomNameToCode,
        tagNames: tagNameToCode.keys.toList()..sort(),
        tagNameToCode: tagNameToCode,
      ));
    } catch (_) {
      // Options stay empty; the sheet hides those sections.
    }
  }

  /// Applies every funnel selection at once.
  ///
  /// [type], [mode] and [paymentStatus] are sent to the transactions
  /// endpoint, so they refetch from page 0. [classroomNames], [tagNames] and
  /// [studentStatus] are not supported by that endpoint — they're resolved
  /// through the student list API and intersected with each row's
  /// `studentCode` (see [TransactionsState.visibleTransactions]).
  Future<void> applyTransactionFilters({
    required List<String> classroomNames,
    required List<String> tagNames,
    String? type,
    String? mode,
    String? paymentStatus,
    String? studentStatus,
  }) async {
    final pickedStudentStatus = (studentStatus ?? '').trim();
    final hasStudentFacet = classroomNames.isNotEmpty ||
        tagNames.isNotEmpty ||
        pickedStudentStatus.isNotEmpty;
    final pickedType = (type ?? '').trim();
    final pickedMode = (mode ?? '').trim();
    final pickedPaymentStatus = (paymentStatus ?? '').trim();

    emit(state.copyWith(
      selectedType: () => pickedType.isEmpty ? null : pickedType,
      selectedMode: () => pickedMode.isEmpty ? null : pickedMode,
      selectedPaymentStatus: () =>
          pickedPaymentStatus.isEmpty ? null : pickedPaymentStatus,
      selectedStudentStatus: () =>
          pickedStudentStatus.isEmpty ? null : pickedStudentStatus,
      selectedClassroomNames: classroomNames,
      selectedTagNames: tagNames,
      // An explicit Type pick supersedes the legend filter (they share the
      // `type` query param — see [TransactionsState.activeFilter]'s doc).
      activeFilter: () => pickedType.isEmpty ? state.activeFilter : null,
      matchingStudentCodes: () => null,
      isApplyingFilters: hasStudentFacet,
    ));

    // Type/Mode/Payment Status changed the server query, so the list
    // reloads from page 0.
    final reload = loadTransactions();
    if (!hasStudentFacet) {
      await reload;
      return;
    }
    await Future.wait<void>([
      reload,
      _resolveStudentCodes(classroomNames, tagNames, pickedStudentStatus),
    ]);
  }

  Future<void> _resolveStudentCodes(
    List<String> classroomNames,
    List<String> tagNames,
    String studentStatus,
  ) async {
    // Reuses the list generation: a newer list query (filter, date change or
    // refresh) invalidates this lookup too.
    final gen = _generation;
    try {
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final classroomCodes = classroomNames
          .map((n) => state.classroomNameToCode[n])
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toList();
      final tagCodes = tagNames
          .map((n) => state.tagNameToCode[n])
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toList();

      final page = await _getStudentPage(
        schoolCode: school,
        classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
        tagCodes: tagCodes.isEmpty ? null : tagCodes,
        status: studentStatus.isEmpty ? null : studentStatus.toUpperCase(),
        page: 0,
        size: _studentLookupSize,
      );
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        matchingStudentCodes: () => page.items
            .map((s) => s.code.trim())
            .where((c) => c.isNotEmpty)
            .toSet(),
        isApplyingFilters: false,
      ));
    } catch (e) {
      if (isClosed || gen != _generation) return;
      // Leave the restriction unset so the list stays usable, and say why.
      emit(state.copyWith(
        isApplyingFilters: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  /// Drops every funnel selection and the legend filter, then reloads.
  Future<void> clearFilters() async {
    emit(state.copyWith(
      activeFilter: () => null,
      selectedType: () => null,
      selectedStatus: () => null,
      selectedMode: () => null,
      selectedPaymentStatus: () => null,
      selectedStudentStatus: () => null,
      selectedClassroomNames: const <String>[],
      selectedTagNames: const <String>[],
      matchingStudentCodes: () => null,
      isApplyingFilters: false,
    ));
    await loadTransactions();
  }

  /// Loads page 0 of the Transactions list (initial load / refresh / date
  /// change). Drives the shimmer via [TransactionsState.isLoading].
  Future<void> loadTransactions({DateTime? dateFrom, DateTime? dateTo}) async {
    // A fresh list load owns a new generation; a slower in-flight response for
    // a superseded query is discarded before it can emit.
    final gen = ++_generation;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty) {
        if (isClosed || gen != _generation) return;
        emit(state.copyWith(isLoading: false, transactions: const []));
        return;
      }
      final result = await _getTransactions(
        organizationCode: org,
        school: school,
        dateFrom: dateFrom ?? state.dateFrom,
        dateTo: dateTo ?? state.dateTo,
        type: _typeParam,
        status: _statusParam,
        mode: _modeParam,
        paymentStatus: _paymentStatusParam,
        page: 0,
        size: _pageSize,
      );
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        transactions: _mapRecords(result.items),
        page: 0,
        hasMore: result.hasMore,
        isLoading: false,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed || gen != _generation) return;
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
    // load-more continues the CURRENT query — capture its generation (do not
    // bump) so a refresh/filter/date change mid-flight discards this page
    // instead of appending it into a now-different list.
    final gen = _generation;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    final nextPage = state.page + 1;
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final result = await _getTransactions(
        organizationCode: org,
        school: school,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        type: _typeParam,
        status: _statusParam,
        mode: _modeParam,
        paymentStatus: _paymentStatusParam,
        page: nextPage,
        size: _pageSize,
      );
      if (isClosed || gen != _generation) return;
      // De-duplicate across pages by the STABLE server transaction id only —
      // never by invoiceCode (which is null for many rows and shared between an
      // invoice and its payment/refund rows, so the old code silently dropped
      // valid transactions). Rows without a server id are always kept.
      final existing = state.transactions
          .map((r) => r.item.transactionId)
          .whereType<String>()
          .toSet();
      final merged = <TransactionRecord>[
        ...state.transactions,
        ..._mapRecords(result.items, startIndex: state.transactions.length)
            .where((r) =>
                r.item.transactionId == null ||
                existing.add(r.item.transactionId!)),
      ];
      emit(state.copyWith(
        transactions: merged,
        page: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed || gen != _generation) return;
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
          transactionId: t.id.isNotEmpty ? t.id : null,
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
          gatewayPayment: t.gatewayPayment,
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
