import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/activities/models/activity_approval.dart';
import 'package:wowcare/redesign/features/activities/models/activity_kind.dart';
import 'package:wowcare/redesign/features/activities/models/activity_person.dart';

/// One key-and-value chip on a feed card: "Meal type · Breakfast".
///
/// Every one of these is a `parameterValues` entry the feed already returns
/// and the old card threw away.
@immutable
class ActivitySpec extends Equatable {
  const ActivitySpec(this.label, this.value);

  final String label;
  final String value;

  @override
  List<Object?> get props => <Object?>[label, value];
}

/// One card on the feed (8a, 8b, 8t).
///
/// Mirrors `ActivityFeedRow`: the type, when it happened, who it was for,
/// who logged it, the flattened `parameterValues`, the tags and how many
/// attachments came with it.
@immutable
class ActivityCard extends Equatable {
  const ActivityCard({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.detail,
    required this.who,
    required this.loggedBy,
    this.body,
    this.specs = const <ActivitySpec>[],
    this.tags = const <String>[],
    this.note,
    this.attachmentCount = 0,
    this.students = const <ActivityPerson>[],
    this.approval = ActivityApproval.notRequired,
    this.hasGoneHome = false,
    this.classroomName = '',
  });

  final String id;
  final ActivityKind kind;

  /// When it happened, in the school's own timezone.
  final DateTime at;

  /// "Meal · Breakfast", or just the type's name.
  final String title;

  /// The line under the title: "Most of it · 16 students".
  final String detail;

  /// Who it was for, at the foot of the card: "Sunflower Room",
  /// "Micah Bell", "Ivy Chen · went home 3:20 pm".
  final String who;

  /// Who logged it, on the far right.
  final String loggedBy;

  /// The free-text description, where there is one.
  final String? body;

  final List<ActivitySpec> specs;
  final List<String> tags;

  /// An incident's Additional Notes, drawn as its own recessed block.
  final String? note;

  final int attachmentCount;

  /// The stack at the foot, already trimmed to three plus an overflow.
  final List<ActivityPerson> students;

  final ActivityApproval approval;

  /// Every student on this card has gone home. "In now" hides these.
  final bool hasGoneHome;

  final String classroomName;

  bool get hasSpecs => specs.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get hasAttachments => attachmentCount > 0;
  bool get hasBody => (body ?? '').trim().isNotEmpty;
  bool get hasNote => (note ?? '').trim().isNotEmpty;

  @override
  List<Object?> get props => <Object?>[
    id,
    kind,
    at,
    title,
    detail,
    who,
    loggedBy,
    body,
    specs,
    tags,
    note,
    attachmentCount,
    students,
    approval,
    hasGoneHome,
    classroomName,
  ];
}
