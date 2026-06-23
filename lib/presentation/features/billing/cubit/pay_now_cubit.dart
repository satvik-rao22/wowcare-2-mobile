import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_guardian_family_ledger_usecase.dart';

part 'pay_now_state.dart';

/// Drives the "Pay Now" amount page: loads the guardian's family ledger (the
/// family's unpaid total + each child's outstanding) and tracks the chosen
/// amount — either the family's unpaid balance or a custom per-child allocation.
class PayNowCubit extends Cubit<PayNowState> {
  PayNowCubit({
    required GetGuardianFamilyLedgerUseCase getGuardianFamilyLedger,
    required StorageService storage,
  })  : _getGuardianFamilyLedger = getGuardianFamilyLedger,
        _storage = storage,
        super(const PayNowState());

  final GetGuardianFamilyLedgerUseCase _getGuardianFamilyLedger;
  final StorageService _storage;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: () => null));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final guardianCode =
          (await _storage.getString(StorageKeys.guardianCode) ?? '').trim();
      final ledger = await _getGuardianFamilyLedger(
        organizationCode: org,
        school: school,
        guardianCode: guardianCode,
      );
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        ledger: () => ledger,
        guardianCode: guardianCode,
        // Current Outstanding defaults to the family's unpaid total.
        currentAmount: ledger.unpaid,
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

  void setCustomAmount(String studentCode, String raw) {
    final next = Map<String, double>.from(state.customAmounts);
    next[studentCode] = double.tryParse(raw.trim()) ?? 0;
    emit(state.copyWith(customAmounts: next));
  }
}
