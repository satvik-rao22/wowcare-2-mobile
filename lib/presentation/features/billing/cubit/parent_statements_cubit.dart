import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/parent_transaction_card.dart';

part 'parent_statements_state.dart';

class ParentStatementsCubit extends Cubit<ParentStatementsState> {
  ParentStatementsCubit() : super(const ParentStatementsState.initial());

  static const int _pageSize = 10;

  void initialize(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      final now = DateTime.now();
      emit(state.copyWith(
        customStartDate: () => DateTime(now.year, now.month, 1),
        customEndDate: () => DateTime(now.year, now.month + 1, 0),
        displayCount: _pageSize,
      ));
    } else {
      emit(state.copyWith(
        customStartDate: () => start,
        customEndDate: () => end,
        displayCount: _pageSize,
      ));
    }
  }

  void syncDates(DateTime? start, DateTime? end) {
    emit(state.copyWith(
      customStartDate: () => start,
      customEndDate: () => end,
      displayCount: _pageSize, // reset page on date change
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
      displayCount: _pageSize, // reset page on filter change
    ));
    await refresh();
  }

  /// Shows the next page of statements (client-side pagination).
  void loadNextPage() {
    if (!state.hasMoreStatements) return;
    emit(state.copyWith(displayCount: state.displayCount + _pageSize));
  }
}
