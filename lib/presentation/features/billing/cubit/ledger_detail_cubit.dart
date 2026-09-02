import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_transaction_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/add_ledger_transaction_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_ledger_by_code_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_ledger_transactions_usecase.dart';
import 'package:wowcare/presentation/features/billing/model/ledger_account_model.dart';

part 'ledger_detail_state.dart';

class LedgerDetailCubit extends Cubit<LedgerDetailState> {
  LedgerDetailCubit({
    required GetLedgerTransactionsUseCase getTransactionsUseCase,
    required AddLedgerTransactionUseCase addTransactionUseCase,
    required GetLedgerByCodeUseCase getLedgerByCodeUseCase,
  })  : _getTransactionsUseCase = getTransactionsUseCase,
        _addTransactionUseCase = addTransactionUseCase,
        _getLedgerByCodeUseCase = getLedgerByCodeUseCase,
        super(LedgerDetailState.initial());

  final GetLedgerTransactionsUseCase _getTransactionsUseCase;
  final AddLedgerTransactionUseCase _addTransactionUseCase;
  final GetLedgerByCodeUseCase _getLedgerByCodeUseCase;

  String? _ledgerCode;

  /// Monotonic load generation. Bumped on a fresh (page-0) load / date-range
  /// change so a superseded in-flight response is discarded; a load-MORE
  /// (page > 0) captures the current generation without bumping.
  int _generation = 0;

  /// Appends [incoming] onto [existing], skipping any transaction whose stable
  /// [code] is already present (keep first per non-empty code) so overlapping
  /// backend pages can't show the same row twice. Code-less rows are kept.
  static List<LedgerTransactionEntity> _appendDedupByCode(
    List<LedgerTransactionEntity> existing,
    List<LedgerTransactionEntity> incoming,
  ) {
    final seen = existing
        .map((e) => e.code)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet();
    final result = List<LedgerTransactionEntity>.from(existing);
    for (final e in incoming) {
      final code = e.code;
      if (code == null || code.isEmpty) {
        result.add(e);
        continue;
      }
      if (seen.add(code)) result.add(e);
    }
    return result;
  }

  void init(String ledgerCode) {
    _ledgerCode = ledgerCode;
    unawaited(_fetchLedger(ledgerCode));
    unawaited(loadPage(0));
  }

  Future<void> _fetchLedger(String ledgerCode) async {
    emit(state.copyWith(isLoadingLedger: true));
    try {
      final entity = await _getLedgerByCodeUseCase(ledgerCode);
      if (isClosed) return;
      emit(state.copyWith(
        ledger: LedgerAccountModel.fromEntity(entity),
        isLoadingLedger: false,
      ));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isLoadingLedger: false));
    }
  }

  Future<void> loadPage(int page) async {
    if (state.isLoading) return;
    final isFirst = page == 0;
    // A page-0 load is a fresh query (initial / refresh / date change) and owns
    // a new generation; a later page continues the current query and captures
    // its generation so a mid-flight reset discards the stale page.
    final gen = isFirst ? ++_generation : _generation;
    emit(state.copyWith(
      isLoading: isFirst,
      isLoadingMore: !isFirst,
      errorMessage: () => null,
    ));
    await _fetch(page: page, reset: isFirst, gen: gen);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoadingMore) return;
    await loadPage(state.currentPage + 1);
  }

  Future<void> loadPrevPage() async {
    if (state.currentPage <= 0) return;
    await loadPage(state.currentPage - 1);
  }

  Future<void> setDateRange({String? from, String? to}) async {
    emit(state.copyWith(
      fromDate: () => from,
      toDate: () => to,
      transactions: [],
      currentPage: 0,
      hasMore: true,
      totalElements: 0,
    ));
    await loadPage(0);
  }

  Future<void> clearDateRange() => setDateRange();

  Future<void> _fetch({
    required int page,
    required bool reset,
    required int gen,
  }) async {
    if (_ledgerCode == null) return;
    try {
      final result = await _getTransactionsUseCase(
        ledgerCode: _ledgerCode!,
        from: state.fromDate,
        to: state.toDate,
        page: page,
      );
      // Drop a superseded response (a newer page-0 load / date change bumped
      // the generation while this request was in flight).
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        transactions: reset
            ? result.content
            : _appendDedupByCode(state.transactions, result.content),
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: result.number,
        totalElements: result.totalElements,
        pageSize: result.size,
        numberOfElements: result.numberOfElements,
        errorMessage: () => null,
      ));
    } catch (e) {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: () => e.toString(),
      ));
    }
  }

  Future<bool> addTransaction(AddTransactionParams params) async {
    emit(state.copyWith(isAddingTransaction: true));
    try {
      await _addTransactionUseCase(params);
      if (isClosed) return true;
      // Refresh from page 0 to reflect the new entry
      await loadPage(0);
      if (isClosed) return true;
      emit(state.copyWith(isAddingTransaction: false));
      return true;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isAddingTransaction: false));
      return false;
    }
  }
}
