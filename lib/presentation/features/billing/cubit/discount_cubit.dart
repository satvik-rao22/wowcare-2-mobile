import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/usecases/get_discounts_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/deactivate_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/reactivate_discount_usecase.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_settings/discount_account_model.dart';

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

  Future<String> _resolveSchoolCode() async {
    _schoolCode ??=
        await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: () => null));
    await _fetchPage(page: 0, reset: true);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    await _fetchPage(page: state.currentPage + 1, reset: false);
  }

  Future<void> _fetchPage({required int page, required bool reset}) async {
    try {
      final school = await _resolveSchoolCode();
      final result = await _getDiscountsUseCase(
        school: school,
        name: state.searchQuery.trim().isEmpty
            ? null
            : state.searchQuery.trim(),
        status: state.statusFilter,
        page: page,
      );
      final newItems =
          result.content.map(DiscountAccountModel.fromEntity).toList();
      final merged =
          reset ? newItems : [...state.allDiscounts, ...newItems];
      if (isClosed) return;
      emit(state.copyWith(
        allDiscounts: merged,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: result.number,
        errorMessage: () => null,
      ));
    } catch (e) {
      if (isClosed) return;
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

  void applySearch() {
    emit(state.copyWith(allDiscounts: [], currentPage: 0, hasMore: true));
    unawaited(loadInitial());
  }

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
