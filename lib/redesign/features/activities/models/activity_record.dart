import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/activities/models/activity_approval.dart';
import 'package:wowcare/redesign/features/activities/models/activity_kind.dart';
import 'package:wowcare/redesign/features/activities/models/activity_person.dart';

/// One label-and-value row on an open activity (8d).
@immutable
class ActivityField extends Equatable {
  const ActivityField(this.label, this.value);

  final String label;
  final String value;

  @override
  List<Object?> get props => <Object?>[label, value];
}

/// One activity, open (8d).
///
/// Mirrors `ActivityDetail` from `GET /api/v2/activities/{cardGroupCode}`:
/// the type, the time, who logged it, the flattened parameter values in the
/// type's own display order, the attachments and the approval status.
@immutable
class ActivityRecord extends Equatable {
  const ActivityRecord({
    required this.id,
    required this.kind,
    required this.title,
    required this.at,
    required this.loggedByName,
    required this.loggedByRole,
    this.fields = const <ActivityField>[],
    this.students = const <ActivityPerson>[],
    this.approval = ActivityApproval.notRequired,
    this.attachmentCount = 0,
    this.classroomName = '',
    this.canEdit = false,
    this.canDelete = false,
    this.canModerate = false,
    this.canAcknowledge = false,
    this.acknowledgedAt,
    this.editNote = '',
  });

  final String id;
  final ActivityKind kind;

  /// "Meal · Breakfast".
  final String title;

  final DateTime at;
  final String loggedByName;
  final String loggedByRole;

  final List<ActivityField> fields;
  final List<ActivityPerson> students;
  final ActivityApproval approval;
  final int attachmentCount;
  final String classroomName;

  /// The three permission answers the frame draws, worked out by the source
  /// from the viewer's persona and staff code the way
  /// `activity_feed_card_permissions.dart` does.
  final bool canEdit;
  final bool canDelete;

  /// Whether the two moderation keys are docked under this record.
  final bool canModerate;

  /// A guardian's Acknowledge key.
  final bool canAcknowledge;

  /// "9:41 am", once the guardian has acknowledged.
  final String? acknowledgedAt;

  /// The sentence under the fields that explains who may change this.
  final String editNote;

  bool get hasAttachments => attachmentCount > 0;

  ActivityPerson? get firstStudent =>
      students.isEmpty ? null : students.first;

  ActivityRecord copyWith({
    ActivityApproval? approval,
    bool? canEdit,
    bool? canDelete,
    bool? canModerate,
    bool? canAcknowledge,
    String? acknowledgedAt,
    String? editNote,
  }) => ActivityRecord(
    id: id,
    kind: kind,
    title: title,
    at: at,
    loggedByName: loggedByName,
    loggedByRole: loggedByRole,
    fields: fields,
    students: students,
    approval: approval ?? this.approval,
    attachmentCount: attachmentCount,
    classroomName: classroomName,
    canEdit: canEdit ?? this.canEdit,
    canDelete: canDelete ?? this.canDelete,
    canModerate: canModerate ?? this.canModerate,
    canAcknowledge: canAcknowledge ?? this.canAcknowledge,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    editNote: editNote ?? this.editNote,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    kind,
    title,
    at,
    loggedByName,
    loggedByRole,
    fields,
    students,
    approval,
    attachmentCount,
    classroomName,
    canEdit,
    canDelete,
    canModerate,
    canAcknowledge,
    acknowledgedAt,
    editNote,
  ];
}
