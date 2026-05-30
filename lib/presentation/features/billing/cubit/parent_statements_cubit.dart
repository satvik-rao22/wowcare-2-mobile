import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/parent_transaction_card.dart';

part 'parent_statements_state.dart';

/// Owns the parent "Statements" tab state: the selected date range, the
/// generate/refresh loading flags, and the (demo) statements list.
class ParentStatementsCubit extends Cubit<ParentStatementsState> {
  ParentStatementsCubit() : super(const ParentStatementsState.initial());

  /// Seeds the date range, defaulting to the current month when not provided.
  void initialize(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      final now = DateTime.now();
      emit(state.copyWith(
        customStartDate: () => DateTime(now.year, now.month, 1),
        customEndDate: () => DateTime(now.year, now.month + 1, 0),
      ));
    } else {
      emit(state.copyWith(
        customStartDate: () => start,
        customEndDate: () => end,
      ));
    }
  }

  /// Syncs the date range from the parent widget (didUpdateWidget).
  void syncDates(DateTime? start, DateTime? end) {
    emit(state.copyWith(
      customStartDate: () => start,
      customEndDate: () => end,
    ));
  }

  Future<void> refresh() async {
    emit(state.copyWith(isStatementsLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (isClosed) return;
    emit(state.copyWith(isStatementsLoading: false));
  }

  Future<void> generate() async {
    emit(state.copyWith(isGenerating: true));
    await Future<void>.delayed(const Duration(seconds: 1));
    if (isClosed) return;
    emit(state.copyWith(isGenerating: false));
  }

  Future<void> applyDateRange(DateTime startDate, DateTime? endDate) async {
    emit(state.copyWith(
      customStartDate: () => startDate,
      customEndDate: () => endDate ??
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59),
    ));
    await refresh();
  }
}
