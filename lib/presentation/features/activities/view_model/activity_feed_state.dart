import 'package:equatable/equatable.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_query.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart';

/// Observable state for [ActivityFeedCubit] — the grouped/deduped daily feed
/// plus the load/pagination/generation bookkeeping the View used to hold in
/// its own `setState` fields (`_activities`, `_loadingFeed`, `_loadingMoreFeed`,
/// `_feedHasMore`, `_feedNextPage`, `_feedGeneration`, `_feedError`).
class ActivityFeedState extends Equatable {
  const ActivityFeedState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
    required this.nextPage,
    required this.generation,
    this.error,
    this.query,
  });

  /// The grouped + deduped + time-desc-sorted feed rows.
  final List<ActivityItem> items;

  /// A first-page (non-refresh) load is running.
  final bool isLoading;

  /// A pull-to-refresh first-page load is running.
  final bool isRefreshing;

  /// A pagination (next-page) load is running. Single-flight guard.
  final bool isLoadingMore;

  /// Whether any sub-feed reported more pages.
  final bool hasMore;

  /// Next page index to request. 0 when [hasMore] is false.
  final int nextPage;

  /// Latest error message from a load, or null.
  final String? error;

  /// Monotonic load generation; a response captured at an older generation is
  /// discarded (refresh/filter/date/classroom/school change bumps it).
  final int generation;

  /// The query the current [items] were loaded for.
  final ActivityFeedQuery? query;

  factory ActivityFeedState.initial() => const ActivityFeedState(
        items: <ActivityItem>[],
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: false,
        nextPage: 0,
        generation: 0,
        error: null,
        query: null,
      );

  ActivityFeedState copyWith({
    List<ActivityItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextPage,
    int? generation,
    Object? error = _noChange,
    ActivityFeedQuery? query,
  }) {
    return ActivityFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      generation: generation ?? this.generation,
      error: identical(error, _noChange) ? this.error : error as String?,
      query: query ?? this.query,
    );
  }

  static const Object _noChange = Object();

  @override
  List<Object?> get props => [
        items,
        isLoading,
        isRefreshing,
        isLoadingMore,
        hasMore,
        nextPage,
        generation,
        error,
        query,
      ];
}
