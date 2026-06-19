import 'package:equatable/equatable.dart';

/// The developmental framework hierarchy: Domain → Subdomain → Milestone.
///
/// All three levels share the same shape: a name, a soft-delete [active] flag
/// (deactivation never hard-deletes — PRD BR-DM-05), and a set of assigned
/// classroom codes that scope visibility. Milestones additionally carry an
/// age group and are the atomic unit of assessment scoring.
///
/// These mirror the PRD §17.1 data-model entities. `assignedClassrooms` holds
/// classroom *codes* (the app's stable identifier for a classroom).

/// Top-level developmental area (e.g. "Social & Emotional"). Scoped to a school.
class AssessmentDomain extends Equatable {
  const AssessmentDomain({
    required this.id,
    required this.name,
    this.description = '',
    this.assignedClassrooms = const <String>[],
    this.subdomains = const <AssessmentSubdomain>[],
    this.active = true,
    this.schoolId = '',
    this.createdBy = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;

  /// Classroom codes this domain applies to. Empty means none assigned.
  final List<String> assignedClassrooms;
  final List<AssessmentSubdomain> subdomains;

  /// Soft-delete flag. Inactive domains drop out of active lists but their
  /// historical assessment records are preserved (PRD FR-DM-15/16).
  final bool active;
  final String schoolId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Active subdomains only (deactivated ones are hidden from management views).
  List<AssessmentSubdomain> get activeSubdomains =>
      subdomains.where((s) => s.active).toList();

  /// Count of active milestones across all active subdomains.
  int get activeMilestoneCount => activeSubdomains.fold(
        0,
        (total, s) => total + s.activeMilestones.length,
      );

  AssessmentDomain copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? assignedClassrooms,
    List<AssessmentSubdomain>? subdomains,
    bool? active,
    String? schoolId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentDomain(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      assignedClassrooms: assignedClassrooms ?? this.assignedClassrooms,
      subdomains: subdomains ?? this.subdomains,
      active: active ?? this.active,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        assignedClassrooms,
        subdomains,
        active,
        schoolId,
        updatedAt,
      ];
}

/// A category within a Domain (e.g. "Emotional Regulation"). Groups milestones.
class AssessmentSubdomain extends Equatable {
  const AssessmentSubdomain({
    required this.id,
    required this.domainId,
    required this.name,
    this.assignedClassrooms = const <String>[],
    this.milestones = const <AssessmentMilestone>[],
    this.active = true,
    this.schoolId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String domainId;
  final String name;
  final List<String> assignedClassrooms;
  final List<AssessmentMilestone> milestones;
  final bool active;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<AssessmentMilestone> get activeMilestones =>
      milestones.where((m) => m.active).toList();

  AssessmentSubdomain copyWith({
    String? id,
    String? domainId,
    String? name,
    List<String>? assignedClassrooms,
    List<AssessmentMilestone>? milestones,
    bool? active,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentSubdomain(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      name: name ?? this.name,
      assignedClassrooms: assignedClassrooms ?? this.assignedClassrooms,
      milestones: milestones ?? this.milestones,
      active: active ?? this.active,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        domainId,
        name,
        assignedClassrooms,
        milestones,
        active,
        updatedAt,
      ];
}

/// A specific, observable developmental indicator within a Subdomain. The
/// atomic unit of assessment scoring; assigned to classrooms by age group.
class AssessmentMilestone extends Equatable {
  const AssessmentMilestone({
    required this.id,
    required this.subdomainId,
    required this.domainId,
    required this.name,
    this.description = '',
    this.ageGroup = '',
    this.assignedClassrooms = const <String>[],
    this.active = true,
    this.schoolId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subdomainId;
  final String domainId;
  final String name;
  final String description;
  final String ageGroup;
  final List<String> assignedClassrooms;
  final bool active;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether this milestone is visible to [classroomCode] (PRD BR-PM-01).
  bool isAssignedTo(String classroomCode) =>
      assignedClassrooms.contains(classroomCode);

  AssessmentMilestone copyWith({
    String? id,
    String? subdomainId,
    String? domainId,
    String? name,
    String? description,
    String? ageGroup,
    List<String>? assignedClassrooms,
    bool? active,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentMilestone(
      id: id ?? this.id,
      subdomainId: subdomainId ?? this.subdomainId,
      domainId: domainId ?? this.domainId,
      name: name ?? this.name,
      description: description ?? this.description,
      ageGroup: ageGroup ?? this.ageGroup,
      assignedClassrooms: assignedClassrooms ?? this.assignedClassrooms,
      active: active ?? this.active,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subdomainId,
        domainId,
        name,
        description,
        ageGroup,
        assignedClassrooms,
        active,
        updatedAt,
      ];
}
