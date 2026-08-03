import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
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
      emit(state.copyWith(families: families, isLoading: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  void clearSearch() => emit(state.copyWith(searchQuery: ''));

  void setShowOutstandingOnly(bool value) =>
      emit(state.copyWith(showOutstandingOnly: value));
}
