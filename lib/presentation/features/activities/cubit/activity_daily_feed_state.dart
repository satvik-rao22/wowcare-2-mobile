part of 'activity_daily_feed_cubit.dart';

class ActivityDailyFeedState extends Equatable {
  const ActivityDailyFeedState({
    required this.activities,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.hasMore,
    required this.nextPage,
    required this.error,
  });

  const ActivityDailyFeedState.initial()
      : activities = const <ActivityItem>[],
        isLoadingInitial = false,
        isLoadingMore = false,
        hasMore = false,
        nextPage = 0,
        error = null;

  final List<ActivityItem> activities;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextPage;
  final String? error;

  /// `error` uses a function-wrapped setter so callers can explicitly set it to
  /// null (clear) vs. leave it unchanged.
  ActivityDailyFeedState copyWith({
    List<ActivityItem>? activities,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextPage,
    String? Function()? error,
  }) {
    return ActivityDailyFeedState(
      activities: activities ?? this.activities,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [
        activities,
        isLoadingInitial,
        isLoadingMore,
        hasMore,
        nextPage,
        error,
      ];
}
