import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_guardian_family_ledger_usecase.dart';

part 'parent_billing_state.dart';

class ParentBillingCubit extends Cubit<ParentBillingState> {
  ParentBillingCubit({
    required GetGuardianFamilyLedgerUseCase getGuardianFamilyLedger,
    required StorageService storage,
  }) : _getGuardianFamilyLedger = getGuardianFamilyLedger,
       _storage = storage,
       super(const ParentBillingState.initial());

  final GetGuardianFamilyLedgerUseCase _getGuardianFamilyLedger;
  final StorageService _storage;

  static const int _pageSize = 10;

  Future<void> load({bool background = false}) async {
    // A background refresh (pull-to-refresh) keeps the current ledger on screen
    // instead of showing the loading state, and refetches silently.
    final keepVisible = background && state.ledger != null;
    emit(
      state.copyWith(
        isLoading: !keepVisible,
        errorMessage: () => null,
        displayCount: _pageSize,
      ),
    );
    try {
      final org = (await _storage.getString(StorageKeys.organizationCode) ?? '')
          .trim();
      final school = (await _storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      final guardianCode =
          (await _storage.getString(StorageKeys.guardianCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty || guardianCode.isEmpty) {
        emit(state.copyWith(isLoading: false));
        return;
      }
      final ledger = await _getGuardianFamilyLedger(
        organizationCode: org,
        school: school,
        guardianCode: guardianCode,
      );
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, ledger: () => ledger));
    } catch (e) {
      if (isClosed) return;
      // On a failed background refresh keep the existing ledger visible.
      if (keepVisible) {
        emit(state.copyWith(isLoading: false));
        return;
      }
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> refresh() => load(background: true);

  /// Shows the next page of transactions (client-side pagination).
  void loadNextPage() {
    if (!state.hasMoreTransactions) return;
    emit(state.copyWith(displayCount: state.displayCount + _pageSize));
  }

  /// Expands the client-side page window until the invoice deep-linked from a
  /// billing notification is inside it.
  ///
  /// Transactions are windowed by [ParentBillingState.displayCount] (10 at a
  /// time), so a notification targeting an older invoice would never mount its
  /// card — and an unmounted card can't flash. Returns true when the invoice is
  /// present in the ledger (already visible, or now revealed).
  bool revealTransaction(String invoiceCode) {
    final code = invoiceCode.trim();
    if (code.isEmpty) return false;
    final all = state.filteredTransactions;
    final index = all.indexWhere(
      (t) => t.invoiceCode.trim().toUpperCase() == code.toUpperCase(),
    );
    if (index < 0) return false; // not in this ledger / outside the date range
    if (index < state.displayCount) return true; // already rendered
    // Grow to a whole page boundary past the target.
    final needed = (((index + 1) / _pageSize).ceil()) * _pageSize;
    emit(state.copyWith(displayCount: needed));
    return true;
  }

  void setDateRange(DateTime startDate, DateTime? endDate) {
    emit(
      state.copyWith(
        startDate: startDate,
        endDate:
            endDate ??
            DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
              23,
              59,
              59,
            ),
        displayCount: _pageSize, // reset page on filter change
      ),
    );
  }

  Future<void> payNow() async {
    if (state.isPaymentLoading) return;
    emit(state.copyWith(isPaymentLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (isClosed) return;
    emit(state.copyWith(isPaymentLoading: false));
  }

  void beginAutoPay() {
    if (state.isAutoPayLoading) return;
    emit(state.copyWith(isAutoPayLoading: true));
  }

  void endAutoPay() {
    if (!state.isAutoPayLoading) return;
    emit(state.copyWith(isAutoPayLoading: false));
  }
}
