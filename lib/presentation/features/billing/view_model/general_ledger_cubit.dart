import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/deactivate_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/reactivate_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_ledgers_usecase.dart';
import 'package:wowcare/presentation/features/billing/model/ledger_account_model.dart';

part 'general_ledger_state.dart';

class GeneralLedgerCubit extends Cubit<GeneralLedgerState> {
  GeneralLedgerCubit({
    required GetLedgersUseCase getLedgersUseCase,
    required DeleteLedgerUseCase deleteLedgerUseCase,
    required DeactivateLedgerUseCase deactivateLedgerUseCase,
    required ReactivateLedgerUseCase reactivateLedgerUseCase,
    required StorageService storageService,
  })  : _getLedgersUseCase = getLedgersUseCase,
        _deleteLedgerUseCase = deleteLedgerUseCase,
        _deactivateLedgerUseCase = deactivateLedgerUseCase,
        _reactivateLedgerUseCase = reactivateLedgerUseCase,
        _storageService = storageService,
        _cacheManager = CacheManager(storageService),
        super(GeneralLedgerState.initial());

  final GetLedgersUseCase _getLedgersUseCase;
  final DeleteLedgerUseCase _deleteLedgerUseCase;
  final DeactivateLedgerUseCase _deactivateLedgerUseCase;
  final ReactivateLedgerUseCase _reactivateLedgerUseCase;
  final StorageService _storageService;
  final CacheManager _cacheManager;

  String? _orgCode;
  String? _schoolCode;

  /// Monotonic load generation. Bumped whenever the logical query changes (a
  /// fresh load, a refresh, or a filter/category/status change) so a slower
  /// in-flight response for a superseded query is discarded instead of
  /// clobbering (or appending into) the current list. A load-MORE captures the
  /// current generation WITHOUT bumping so a refresh/filter change mid-flight
  /// drops the stale page.
  int _generation = 0;

  /// Appends [incoming] onto [existing], skipping any ledger whose stable [id]
  /// is already present (keep first per non-empty id) so overlapping backend
  /// pages can't show the same account twice. Id-less rows are always kept.
  static List<LedgerAccountModel> _appendDedupById(
    List<LedgerAccountModel> existing,
    List<LedgerAccountModel> incoming,
  ) {
    final seen = existing.map((e) => e.id).where((id) => id.isNotEmpty).toSet();
    final result = List<LedgerAccountModel>.from(existing);
    for (final e in incoming) {
      if (e.id.isEmpty) {
        result.add(e);
        continue;
      }
      if (seen.add(e.id)) result.add(e);
    }
    return result;
  }

  Future<String> _resolveOrgCode() async {
    _orgCode ??=
        await _storageService.getString(StorageKeys.organizationCode) ?? '';
    return _orgCode!;
  }

  Future<String> _resolveSchoolCode() async {
    _schoolCode ??=
        await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
  }

  // ─── Cache helpers ────────────────────────────────────────────────────────

  String _cacheKey(String schoolCode) => CacheManager.buildCacheKey(
        feature: 'ledger',
        resource: 'list',
        identifier:
            '${schoolCode.trim()}|status=${state.statusFilter ?? "ALL"}|cat=${state.selectedCategory ?? "ALL"}',
      );

  Map<String, dynamic> _encodeList(List<LedgerAccountModel> items) => {
        'items': items.map((e) => e.toJson()).toList(),
      };

  List<LedgerAccountModel> _decodeList(Map<String, dynamic>? payload) {
    if (payload == null) return [];
    final raw = payload['items'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => LedgerAccountModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _invalidateAllLedgerCaches() async {
    final keys = await _storageService.getKeys();
    for (final key in keys) {
      if (key.contains('ledger_list_cache_')) {
        await _cacheManager.invalidateCache(key);
      }
    }
  }

  // ─── List management ─────────────────────────────────────────────────────

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    // A fresh load owns a new generation; a slower in-flight response for a
    // superseded query is discarded before it can emit.
    final gen = ++_generation;
    emit(state.copyWith(isLoading: true, errorMessage: () => null));

    // Hydrate from cache immediately so UI shows stale data while refreshing
    final school = await _resolveSchoolCode();
    final cacheKey = _cacheKey(school);
    final cached = await _cacheManager.loadCache(cacheKey);
    final cachedItems = _decodeList(cached);
    if (cachedItems.isNotEmpty && !isClosed && gen == _generation) {
      emit(state.copyWith(
        allLedgers: cachedItems,
        isLoading: false,
        isRefreshing: true,
      ));
    }

    await _fetchPage(page: 0, reset: true, gen: gen);
  }

  Future<void> refresh() async {
    final gen = ++_generation;
    emit(state.copyWith(isRefreshing: true, errorMessage: () => null));
    await _fetchPage(page: 0, reset: true, gen: gen);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoadingMore) return;
    // load-more continues the CURRENT query: capture its generation (do not
    // bump) so a refresh/filter change mid-flight discards this page instead of
    // appending it into a now-different list.
    final gen = _generation;
    emit(state.copyWith(isLoadingMore: true));
    await _fetchPage(page: state.currentPage + 1, reset: false, gen: gen);
  }

  Future<void> _fetchPage({
    required int page,
    required bool reset,
    required int gen,
  }) async {
    try {
      final org = await _resolveOrgCode();
      final school = await _resolveSchoolCode();
      final result = await _getLedgersUseCase(
        organizationCode: org,
        school: school,
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
        category: state.selectedCategory,
        status: state.statusFilter,
        page: page,
      );

      // Drop a superseded response: a newer load/refresh/filter change bumped
      // the generation while this request was in flight.
      if (isClosed || gen != _generation) return;

      final newItems =
          result.content.map(LedgerAccountModel.fromEntity).toList();
      final merged =
          reset ? newItems : _appendDedupById(state.allLedgers, newItems);

      emit(state.copyWith(
        allLedgers: merged,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: result.number,
        errorMessage: () => null,
      ));

      // Save to cache only for fresh first-page loads (no search query)
      if (reset && state.searchQuery.trim().isEmpty) {
        final cacheKey = _cacheKey(school);
        await _cacheManager.saveCache(cacheKey, _encodeList(merged));
      }
    } catch (e) {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: () => e.toString(),
      ));
    }
  }

  // ─── Search / filter ──────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void applySearch() {
    emit(state.copyWith(allLedgers: [], currentPage: 0, hasMore: true));
    loadInitial();
  }

  void setCategory(String? category) {
    emit(GeneralLedgerState.initial().copyWith(
      searchQuery: state.searchQuery,
      selectedCategory: () => category,
      statusFilter: () => state.statusFilter,
    ));
    loadInitial();
  }

  void setStatusFilter(String? status) {
    if (state.statusFilter == status) return;
    emit(GeneralLedgerState.initial().copyWith(
      searchQuery: state.searchQuery,
      selectedCategory: () => state.selectedCategory,
      statusFilter: () => status,
    ));
    loadInitial();
  }

  void clearFilters() {
    _orgCode = null;
    _schoolCode = null;
    emit(GeneralLedgerState.initial());
    loadInitial();
  }

  // ─── CRUD callbacks ───────────────────────────────────────────────────────

  void addLedger(LedgerAccountModel ledger) {
    unawaited(_invalidateAllLedgerCaches());
    emit(state.copyWith(
      allLedgers: <LedgerAccountModel>[ledger, ...state.allLedgers],
    ));
  }

  void updateLedger(LedgerAccountModel ledger) {
    unawaited(_invalidateAllLedgerCaches());
    final index = state.allLedgers.indexWhere((e) => e.id == ledger.id);
    if (index == -1) return;
    final updated = List<LedgerAccountModel>.from(state.allLedgers);
    updated[index] = ledger;
    emit(state.copyWith(allLedgers: updated));
  }

  Future<bool> deleteLedger(String ledgerCode) async {
    try {
      await _deleteLedgerUseCase(ledgerCode);
      await _invalidateAllLedgerCaches();
      emit(state.copyWith(
        allLedgers: state.allLedgers.where((e) => e.id != ledgerCode).toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deactivateLedger(String ledgerCode) async {
    try {
      await _deactivateLedgerUseCase(ledgerCode);
      await _invalidateAllLedgerCaches();
      if (state.statusFilter == 'ACTIVE') {
        emit(state.copyWith(
          allLedgers: state.allLedgers.where((e) => e.id != ledgerCode).toList(),
        ));
      } else {
        final updated = state.allLedgers.map((e) {
          return e.id == ledgerCode ? e.copyWith(status: 'INACTIVE') : e;
        }).toList();
        emit(state.copyWith(allLedgers: updated));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reactivateLedger(String ledgerCode) async {
    try {
      await _reactivateLedgerUseCase(ledgerCode);
      await _invalidateAllLedgerCaches();
      if (state.statusFilter == 'INACTIVE') {
        emit(state.copyWith(
          allLedgers: state.allLedgers.where((e) => e.id != ledgerCode).toList(),
        ));
      } else {
        final updated = state.allLedgers.map((e) {
          return e.id == ledgerCode ? e.copyWith(status: 'ACTIVE') : e;
        }).toList();
        emit(state.copyWith(allLedgers: updated));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
