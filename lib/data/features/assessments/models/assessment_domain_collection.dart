import 'package:isar/isar.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';

part 'assessment_domain_collection.g.dart';

/// Isar persistence for the parameter hierarchy. The whole Domain →
/// Subdomain → Milestone tree is stored as a single document per domain, with
/// subdomains and milestones as embedded objects (mirrors how the Events
/// module embeds attendees). Soft-delete is an `active` flag at each level.
@collection
class AssessmentDomainCollection {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String schoolId;

  late String name;
  late String description;
  late bool active;
  late List<String> assignedClassrooms;
  late String createdBy;
  late DateTime createdAt;
  late DateTime updatedAt;

  List<SubdomainEmbedded> subdomains = <SubdomainEmbedded>[];

  AssessmentDomainCollection();

  factory AssessmentDomainCollection.fromEntity(AssessmentDomain domain) {
    return AssessmentDomainCollection()
      ..id = domain.id
      ..schoolId = domain.schoolId
      ..name = domain.name
      ..description = domain.description
      ..active = domain.active
      ..assignedClassrooms = List<String>.from(domain.assignedClassrooms)
      ..createdBy = domain.createdBy
      ..createdAt = domain.createdAt
      ..updatedAt = domain.updatedAt
      ..subdomains =
          domain.subdomains.map(SubdomainEmbedded.fromEntity).toList();
  }

  AssessmentDomain toEntity() {
    return AssessmentDomain(
      id: id,
      name: name,
      description: description,
      assignedClassrooms: List<String>.from(assignedClassrooms),
      subdomains: subdomains.map((s) => s.toEntity(id, schoolId)).toList(),
      active: active,
      schoolId: schoolId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@embedded
class SubdomainEmbedded {
  late String id;
  late String name;
  late bool active;
  List<String> assignedClassrooms = <String>[];
  List<MilestoneEmbedded> milestones = <MilestoneEmbedded>[];
  DateTime? createdAt;
  DateTime? updatedAt;

  SubdomainEmbedded();

  factory SubdomainEmbedded.fromEntity(AssessmentSubdomain subdomain) {
    return SubdomainEmbedded()
      ..id = subdomain.id
      ..name = subdomain.name
      ..active = subdomain.active
      ..assignedClassrooms = List<String>.from(subdomain.assignedClassrooms)
      ..milestones =
          subdomain.milestones.map(MilestoneEmbedded.fromEntity).toList()
      ..createdAt = subdomain.createdAt
      ..updatedAt = subdomain.updatedAt;
  }

  AssessmentSubdomain toEntity(String domainId, String schoolId) {
    final now = DateTime.now();
    return AssessmentSubdomain(
      id: id,
      domainId: domainId,
      name: name,
      assignedClassrooms: List<String>.from(assignedClassrooms),
      milestones:
          milestones.map((m) => m.toEntity(id, domainId, schoolId)).toList(),
      active: active,
      schoolId: schoolId,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }
}

@embedded
class MilestoneEmbedded {
  late String id;
  late String name;
  late String description;
  late String ageGroup;
  late bool active;
  List<String> assignedClassrooms = <String>[];
  DateTime? createdAt;
  DateTime? updatedAt;

  MilestoneEmbedded();

  factory MilestoneEmbedded.fromEntity(AssessmentMilestone milestone) {
    return MilestoneEmbedded()
      ..id = milestone.id
      ..name = milestone.name
      ..description = milestone.description
      ..ageGroup = milestone.ageGroup
      ..active = milestone.active
      ..assignedClassrooms = List<String>.from(milestone.assignedClassrooms)
      ..createdAt = milestone.createdAt
      ..updatedAt = milestone.updatedAt;
  }

  AssessmentMilestone toEntity(
    String subdomainId,
    String domainId,
    String schoolId,
  ) {
    final now = DateTime.now();
    return AssessmentMilestone(
      id: id,
      subdomainId: subdomainId,
      domainId: domainId,
      name: name,
      description: description,
      ageGroup: ageGroup,
      assignedClassrooms: List<String>.from(assignedClassrooms),
      active: active,
      schoolId: schoolId,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }
}
