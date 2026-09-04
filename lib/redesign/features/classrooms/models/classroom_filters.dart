import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/classrooms/models/classroom_staff_member.dart';

/// Whether the roster is showing the students who are here now or the ones
/// still to start (7d, "Status · pick one").
enum StudentStatusFilter { active, upcoming }

/// What the students filter sheet has set (7d).
@immutable
class StudentFilters extends Equatable {
  const StudentFilters({
    this.status = StudentStatusFilter.active,
    this.signedInOnly = false,
    this.nappingOnly = false,
    this.tags = const <String>{},
  });

  final StudentStatusFilter status;

  /// The two quick toggles that also sit over the roster.
  final bool signedInOnly;
  final bool nappingOnly;

  /// Care-need tags. They carry no count, because a student may hold several.
  final Set<String> tags;

  bool get isClear =>
      status == StudentStatusFilter.active &&
      !signedInOnly &&
      !nappingOnly &&
      tags.isEmpty;

  StudentFilters copyWith({
    StudentStatusFilter? status,
    bool? signedInOnly,
    bool? nappingOnly,
    Set<String>? tags,
  }) => StudentFilters(
    status: status ?? this.status,
    signedInOnly: signedInOnly ?? this.signedInOnly,
    nappingOnly: nappingOnly ?? this.nappingOnly,
    tags: tags ?? this.tags,
  );

  @override
  List<Object?> get props => [status, signedInOnly, nappingOnly, tags];
}

/// What the staff filter sheet has set (7d's second half).
@immutable
class StaffFilters extends Equatable {
  const StaffFilters({
    this.designations = const <String>{},
    this.dutyStates = const <StaffDutyState>{},
  });

  final Set<String> designations;
  final Set<StaffDutyState> dutyStates;

  bool get isClear => designations.isEmpty && dutyStates.isEmpty;

  StaffFilters copyWith({
    Set<String>? designations,
    Set<StaffDutyState>? dutyStates,
  }) => StaffFilters(
    designations: designations ?? this.designations,
    dutyStates: dutyStates ?? this.dutyStates,
  );

  @override
  List<Object?> get props => [designations, dutyStates];
}
