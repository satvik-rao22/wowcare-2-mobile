import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/usecases/get_discounts_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/deactivate_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/reactivate_discount_usecase.dart';
import 'package:wowcare/presentation/features/billing/model/discount_account_model.dart';

part 'discount_state.dart';

class DiscountCubit extends Cubit<DiscountState> {
  DiscountCubit({
    required GetDiscountsUseCase getDiscountsUseCase,
    required DeleteDiscountUseCase deleteDiscountUseCase,
    required DeactivateDiscountUseCase deactivateDiscountUseCase,
    required ReactivateDiscountUseCase reactivateDiscountUseCase,
    required StorageService storageService,
  })  : _getDiscountsUseCase = getDiscountsUseCase,
        _deleteDiscountUseCase = deleteDiscountUseCase,
        _deactivateDiscountUseCase = deactivateDiscountUseCase,
        _reactivateDiscountUseCase = reactivateDiscountUseCase,
        _storageService = storageService,
        super(DiscountState.initial());

  final GetDiscountsUseCase _getDiscountsUseCase;
  final DeleteDiscountUseCase _deleteDiscountUseCase;
  final DeactivateDiscountUseCase _deactivateDiscountUseCase;
  final ReactivateDiscountUseCase _reactivateDiscountUseCase;
  final StorageService _storageService;

  String? _schoolCode;

  /// Monotonic load generation. Bumped on a fresh load / filter change so a
  /// superseded in-flight response is discarded; a load-MORE captures the
  /// current generation without bumping.
  int _generation = 0;

  Future<String> _resolveSchoolCode() async {
    _schoolCode ??=
        await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
  }

  /// Appends [incoming] onto [existing], skipping any discount whose stable
  /// [code] is already present (keep first per non-empty code) so overlapping
  /// backend pages can't show the same discount twice. Code-less rows are kept.
  static List<DiscountAccountModel> _appendDedupByCode(
    List<DiscountAccountModel> existing,
    List<DiscountAccountModel> incoming,
  ) {
    final seen =
        existing.map((e) => e.code).where((c) => c.isNotEmpty).toSet();
    final result = List<DiscountAccountModel>.from(existing);
    for (final e in incoming) {
      if (e.code.isEmpty) {
        result.add(e);
        continue;
      }
      if (seen.add(e.code)) result.add(e);
    }
    return result;
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    final gen = ++_generation;
    emit(state.copyWith(isLoading: true, errorMessage: () => null));
    await _fetchPage(page: 0, reset: true, gen: gen);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoadingMore) return;
    // load-more continues the CURRENT query — capture, do not bump.
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
      final school = await _resolveSchoolCode();
      // `name` is intentionally not sent — this endpoint's backend ignores
      // it, so search is applied client-side instead (see
      // DiscountState.filteredDiscounts).
      final result = await _getDiscountsUseCase(
        school: school,
        status: state.statusFilter,
        page: page,
      );
      // Drop a superseded response (a newer load/filter change bumped the gen).
      if (isClosed || gen != _generation) return;
      final newItems =
          result.content.map(DiscountAccountModel.fromEntity).toList();
      final merged =
          reset ? newItems : _appendDedupByCode(state.allDiscounts, newItems);
      emit(state.copyWith(
        allDiscounts: merged,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: result.number,
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

  // ─── Search / filter ──────────────────────────────────────────────────────

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  void setStatusFilter(String? status) {
    if (state.statusFilter == status) return;
    emit(DiscountState.initial().copyWith(
      searchQuery: state.searchQuery,
      statusFilter: () => status,
    ));
    unawaited(loadInitial());
  }

  void clearFilters() {
    _schoolCode = null;
    emit(DiscountState.initial());
    unawaited(loadInitial());
  }

  // ─── CRUD callbacks ───────────────────────────────────────────────────────

  void addDiscount(DiscountAccountModel discount) {
    emit(state.copyWith(
      allDiscounts: [discount, ...state.allDiscounts],
    ));
  }

  void updateDiscount(DiscountAccountModel discount) {
    final index =
        state.allDiscounts.indexWhere((e) => e.code == discount.code);
    if (index == -1) return;
    final updated = List<DiscountAccountModel>.from(state.allDiscounts);
    updated[index] = discount;
    emit(state.copyWith(allDiscounts: updated));
  }

  Future<bool> deleteDiscount(String code) async {
    try {
      await _deleteDiscountUseCase(code);
      emit(state.copyWith(
        allDiscounts:
            state.allDiscounts.where((e) => e.code != code).toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deactivateDiscount(String code) async {
    try {
      await _deactivateDiscountUseCase(code);
      if (state.statusFilter == 'ACTIVE') {
        emit(state.copyWith(
          allDiscounts:
              state.allDiscounts.where((e) => e.code != code).toList(),
        ));
      } else {
        final updated = state.allDiscounts.map((e) {
          return e.code == code ? e.copyWith(status: 'INACTIVE') : e;
        }).toList();
        emit(state.copyWith(allDiscounts: updated));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reactivateDiscount(String code) async {
    try {
      await _reactivateDiscountUseCase(code);
      if (state.statusFilter == 'INACTIVE') {
        emit(state.copyWith(
          allDiscounts:
              state.allDiscounts.where((e) => e.code != code).toList(),
        ));
      } else {
        final updated = state.allDiscounts.map((e) {
          return e.code == code ? e.copyWith(status: 'ACTIVE') : e;
        }).toList();
        emit(state.copyWith(allDiscounts: updated));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

}
