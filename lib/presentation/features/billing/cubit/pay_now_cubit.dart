import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_family_summary_usecase.dart';

part 'pay_now_state.dart';

/// Drives the "Pay Now" amount page: loads the family-summary (per-owner open
/// balances) and tracks the chosen amount — either the full family balance or a
/// custom per-owner allocation.
class PayNowCubit extends Cubit<PayNowState> {
  PayNowCubit({
    required GetFamilySummaryUseCase getFamilySummary,
    required StorageService storage,
  })  : _getFamilySummary = getFamilySummary,
        _storage = storage,
        super(const PayNowState());

  final GetFamilySummaryUseCase _getFamilySummary;
  final StorageService _storage;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: () => null));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final families = await _getFamilySummary(
        organizationCode: org,
        school: school,
      );
      if (isClosed) return;
      final total =
          families.fold<double>(0, (sum, f) => sum + f.openBalance);
      emit(state.copyWith(
        isLoading: false,
        families: families,
        currentAmount: total,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  void setMode(PayNowAmountMode mode) {
    emit(state.copyWith(mode: mode));
  }

  void setCurrentAmount(String raw) {
    emit(state.copyWith(currentAmount: double.tryParse(raw.trim()) ?? 0));
  }

  void setCustomAmount(String ownerCode, String raw) {
    final next = Map<String, double>.from(state.customAmounts);
    next[ownerCode] = double.tryParse(raw.trim()) ?? 0;
    emit(state.copyWith(customAmounts: next));
  }
}
