import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_family_summary_usecase.dart';

part 'family_summary_state.dart';

/// Loads the per-family billing summary list (last invoice / last payment /
/// open balance) for the Student(s) overview and Transactions lists. Search and
/// the "outstanding only" filter are applied client-side over the loaded rows.
class FamilySummaryCubit extends Cubit<FamilySummaryState> {
  FamilySummaryCubit({
    required GetFamilySummaryUseCase getFamilySummary,
    required StorageService storage,
  })  : _getFamilySummary = getFamilySummary,
        _storage = storage,
        super(const FamilySummaryState.initial());

  final GetFamilySummaryUseCase _getFamilySummary;
  final StorageService _storage;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
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
      emit(state.copyWith(families: _dedupeByOwner(families), isLoading: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  /// The API has been observed returning the same family more than once
  /// (same owner, repeated rows) — the same family/last-name showing up
  /// several times in the list. Dedupe by owner identity (falling back to
  /// family name only if the owner code is missing) so each family renders
  /// once, keeping the first occurrence returned.
  List<FamilySummaryEntity> _dedupeByOwner(List<FamilySummaryEntity> families) {
    final seen = <String>{};
    final result = <FamilySummaryEntity>[];
    for (final f in families) {
      final key = f.ownerCode.trim().isNotEmpty
          ? '${f.ownerType.trim().toUpperCase()}:${f.ownerCode.trim()}'
          : f.familyName.trim().toLowerCase();
      if (seen.add(key)) result.add(f);
    }
    return result;
  }

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  void clearSearch() => emit(state.copyWith(searchQuery: ''));

  void setShowOutstandingOnly(bool value) =>
      emit(state.copyWith(showOutstandingOnly: value));

  /// Applies the funnel sheet's selections. Values are normalised to trimmed
  /// upper case to match how the rows are compared; an empty set clears that
  /// dimension rather than matching nothing.
  void setFilters({
    required Set<String> invoiceStatuses,
    required Set<String> paymentMethods,
  }) {
    emit(state.copyWith(
      invoiceStatuses: _normalizeAll(invoiceStatuses),
      paymentMethods: _normalizeAll(paymentMethods),
    ));
  }

  /// Drops the funnel selections, leaving search and the outstanding toggle.
  void clearFilters() => emit(state.copyWith(
        invoiceStatuses: const <String>{},
        paymentMethods: const <String>{},
      ));

  static Set<String> _normalizeAll(Set<String> values) => values
      .map((v) => v.trim().toUpperCase())
      .where((v) => v.isNotEmpty)
      .toSet();
}
