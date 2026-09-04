import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/activities/models/activity_card.dart';

/// Whether the feed is showing one day or a span of them (8a, 8b).
enum FeedMode {
  day,
  range;

  bool get isRange => this == FeedMode.range;
}

/// A span of days, inclusive at both ends.
@immutable
class ActivityDateRange extends Equatable {
  const ActivityDateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  /// How many days the header counts: "4 days · Sunflower Room".
  int get days =>
      DateTime(to.year, to.month, to.day)
          .difference(DateTime(from.year, from.month, from.day))
          .inDays +
      1;

  @override
  List<Object?> get props => <Object?>[from, to];
}

/// One day's worth of a range, under its own sticky navy header (8b).
@immutable
class ActivityDayGroup extends Equatable {
  const ActivityDayGroup({
    required this.day,
    required this.label,
    required this.cards,
    required this.total,
  });

  final DateTime day;

  /// "Thursday 20 August".
  final String label;

  final List<ActivityCard> cards;

  /// How many the day holds, which is not always how many are drawn: the
  /// feed pages ten at a time.
  final int total;

  @override
  List<Object?> get props => <Object?>[day, label, cards, total];
}

/// What one feed fetch came back with.
///
/// `ActivityFeedPage` already carries `totalElements` and `last`, so both
/// the "31 cards" count and the "Showing 10 of 23" line are free.
@immutable
class ActivityFeed extends Equatable {
  const ActivityFeed({
    this.cards = const <ActivityCard>[],
    this.total = 0,
    this.hasMore = false,
    this.pendingCount = 0,
    this.attendanceOpenAt,
    this.attendanceStudentCount = 0,
    this.classroomName = '',
  });

  final List<ActivityCard> cards;

  /// `totalElements` for the whole query, not just this page.
  final int total;

  /// The inverse of `last`.
  final bool hasMore;

  /// How many on this day are waiting for a director. Its own filtered call,
  /// which is what the pink banner and the queue badge both read.
  final int pendingCount;

  /// When the room opened, for the attendance card the rail can show.
  final DateTime? attendanceOpenAt;
  final int attendanceStudentCount;

  final String classroomName;

  bool get isEmpty => cards.isEmpty;

  @override
  List<Object?> get props => <Object?>[
    cards,
    total,
    hasMore,
    pendingCount,
    attendanceOpenAt,
    attendanceStudentCount,
    classroomName,
  ];
}
