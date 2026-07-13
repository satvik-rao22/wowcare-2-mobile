import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../view/activity_item.dart';

part 'activity_daily_feed_state.dart';

/// Owns the daily activity feed's list + pagination/loading/error state — the
/// shared state that the ~67 `setState` calls in `activity_daily_tab.dart`
/// currently mutate directly.
///
/// The view keeps its input-computing helpers (classroom/date/filter
/// resolution) and the usecase orchestration for now; it should drive this
/// cubit instead of calling `setState` for feed state:
///
///   * `beginInitialLoad()`  before a refresh/first load
///   * `beginLoadMore()`     before fetching the next page
///   * `appendPage(items, hasMore: …)` when a page resolves
///   * `replaceItems(items)` after client-side regroup/sort
///   * `failLoad(message)`   on error
///   * `reset()`             when switching classroom/date/filters
///
/// The view reads `state.activities` / `state.isLoadingMore` / `state.hasMore`
/// / `state.nextPage` / `state.error` (via `BlocBuilder` or a stream listener)
/// instead of private fields.
class ActivityDailyFeedCubit extends Cubit<ActivityDailyFeedState> {
  ActivityDailyFeedCubit() : super(const ActivityDailyFeedState.initial());

  /// Marks the start of an initial / refresh load (page 0).
  void beginInitialLoad() {
    emit(state.copyWith(isLoadingInitial: true, error: () => null));
  }

  /// Marks the start of a next-page fetch.
  void beginLoadMore() {
    emit(state.copyWith(isLoadingMore: true));
  }

  /// Appends a freshly-fetched page and advances pagination.
  void appendPage(List<ActivityItem> items, {required bool hasMore}) {
    final next = <ActivityItem>[...state.activities, ...items];
    emit(state.copyWith(
      activities: next,
      hasMore: hasMore,
      nextPage: hasMore ? state.nextPage + 1 : 0,
      isLoadingInitial: false,
      isLoadingMore: false,
      error: () => null,
    ));
  }

  /// Replaces the full list (e.g. after client-side regroup/sort) without
  /// touching pagination.
  void replaceItems(List<ActivityItem> items) {
    emit(state.copyWith(activities: items));
  }

  /// Records a load failure and stops pagination.
  void failLoad(String message) {
    emit(state.copyWith(
      isLoadingInitial: false,
      isLoadingMore: false,
      hasMore: false,
      error: () => message,
    ));
  }

  /// Clears the feed back to page 0 (classroom/date/filter change).
  void reset() {
    emit(const ActivityDailyFeedState.initial());
  }
}
