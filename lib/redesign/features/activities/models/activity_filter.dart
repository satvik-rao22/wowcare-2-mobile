import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/activities/models/activity_approval.dart';
import 'package:wowcare/redesign/features/activities/models/activity_card.dart';
import 'package:wowcare/redesign/features/activities/models/activity_kind.dart';

/// What the filter sheet is holding (8c).
///
/// Three groups, each a multiple selection, exactly as
/// `activity_filter_screen.dart` posts them: Tags, Activity Type and Status.
/// No counts sit against an option: the feed pages ten at a time and returns
/// no per-type total, so a number there would be a guess.
@immutable
class ActivityFilter extends Equatable {
  const ActivityFilter({
    this.tags = const <String>{},
    this.kinds = const <ActivityKind>{},
    this.statuses = const <ActivityApproval>{},
  });

  static const ActivityFilter none = ActivityFilter();

  final Set<String> tags;
  final Set<ActivityKind> kinds;
  final Set<ActivityApproval> statuses;

  bool get isEmpty => tags.isEmpty && kinds.isEmpty && statuses.isEmpty;

  /// How many options are picked in total: the Apply key's number.
  int get chosen => tags.length + kinds.length + statuses.length;

  /// How many of the three groups are narrowing anything: the badge on the
  /// header's filter key.
  int get groupsOn =>
      (tags.isEmpty ? 0 : 1) +
      (kinds.isEmpty ? 0 : 1) +
      (statuses.isEmpty ? 0 : 1);

  bool matches(ActivityCard card) =>
      (kinds.isEmpty || kinds.contains(card.kind)) &&
      (statuses.isEmpty || statuses.contains(card.approval)) &&
      (tags.isEmpty || card.tags.any(tags.contains));

  ActivityFilter withKind(ActivityKind? kind) => ActivityFilter(
    tags: tags,
    kinds: kind == null ? const <ActivityKind>{} : <ActivityKind>{kind},
    statuses: statuses,
  );

  ActivityFilter toggleTag(String tag) => ActivityFilter(
    tags: _toggled(tags, tag),
    kinds: kinds,
    statuses: statuses,
  );

  ActivityFilter toggleKind(ActivityKind kind) => ActivityFilter(
    tags: tags,
    kinds: _toggled(kinds, kind),
    statuses: statuses,
  );

  ActivityFilter toggleStatus(ActivityApproval status) => ActivityFilter(
    tags: tags,
    kinds: kinds,
    statuses: _toggled(statuses, status),
  );

  static Set<T> _toggled<T>(Set<T> from, T value) {
    final next = <T>{...from};
    if (!next.remove(value)) next.add(value);
    return next;
  }

  @override
  List<Object?> get props => <Object?>[tags, kinds, statuses];
}
