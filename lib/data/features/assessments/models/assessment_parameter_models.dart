import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';

/// JSON-serialisable DTOs for the parameter hierarchy. The shape mirrors what
/// the future Assessments API is expected to return (PRD §18) so the bundled
/// mock seed and a remote datasource can share these models untouched.

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
}

DateTime _date(dynamic raw) =>
    DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();

class MilestoneModel {
  const MilestoneModel({
    required this.id,
    required this.name,
    this.description = '',
    this.assignedAgeGroups = const <String>[],
    this.active = true,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) => MilestoneModel(
        id: (json['id'] ?? '').toString().trim(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        assignedAgeGroups: _stringList(json['assignedAgeGroups']),
        active: json['active'] != false,
      );

  final String id;
  final String name;
  final String description;
  final List<String> assignedAgeGroups;
  final bool active;

  AssessmentMilestone toEntity({
    required String subdomainId,
    required String domainId,
    required String schoolId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) =>
      AssessmentMilestone(
        id: id,
        subdomainId: subdomainId,
        domainId: domainId,
        name: name,
        description: description,
        assignedAgeGroups: assignedAgeGroups,
        active: active,
        schoolId: schoolId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class SubdomainModel {
  const SubdomainModel({
    required this.id,
    required this.name,
    this.assignedAgeGroups = const <String>[],
    this.milestones = const <MilestoneModel>[],
    this.active = true,
  });

  factory SubdomainModel.fromJson(Map<String, dynamic> json) => SubdomainModel(
        id: (json['id'] ?? '').toString().trim(),
        name: (json['name'] ?? '').toString(),
        assignedAgeGroups: _stringList(json['assignedAgeGroups']),
        milestones: (json['milestones'] is List)
            ? (json['milestones'] as List)
                .whereType<Map>()
                .map((m) => MilestoneModel.fromJson(
                    m.map((k, v) => MapEntry(k.toString(), v))))
                .toList()
            : const <MilestoneModel>[],
        active: json['active'] != false,
      );

  final String id;
  final String name;
  final List<String> assignedAgeGroups;
  final List<MilestoneModel> milestones;
  final bool active;

  AssessmentSubdomain toEntity({
    required String domainId,
    required String schoolId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) =>
      AssessmentSubdomain(
        id: id,
        domainId: domainId,
        name: name,
        assignedAgeGroups: assignedAgeGroups,
        milestones: milestones
            .map((m) => m.toEntity(
                  subdomainId: id,
                  domainId: domainId,
                  schoolId: schoolId,
                  createdAt: createdAt,
                  updatedAt: updatedAt,
                ))
            .toList(),
        active: active,
        schoolId: schoolId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class DomainModel {
  const DomainModel({
    required this.id,
    required this.name,
    this.description = '',
    this.assignedAgeGroups = const <String>[],
    this.subdomains = const <SubdomainModel>[],
    this.active = true,
    this.schoolId = '',
  });

  factory DomainModel.fromJson(Map<String, dynamic> json) => DomainModel(
        id: (json['id'] ?? '').toString().trim(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        assignedAgeGroups: _stringList(json['assignedAgeGroups']),
        subdomains: (json['subdomains'] is List)
            ? (json['subdomains'] as List)
                .whereType<Map>()
                .map((m) => SubdomainModel.fromJson(
                    m.map((k, v) => MapEntry(k.toString(), v))))
                .toList()
            : const <SubdomainModel>[],
        active: json['active'] != false,
        schoolId: (json['schoolId'] ?? '').toString(),
      );

  final String id;
  final String name;
  final String description;
  final List<String> assignedAgeGroups;
  final List<SubdomainModel> subdomains;
  final bool active;
  final String schoolId;

  AssessmentDomain toEntity() {
    final now = _date(null);
    return AssessmentDomain(
      id: id,
      name: name,
      description: description,
      assignedAgeGroups: assignedAgeGroups,
      subdomains: subdomains
          .map((s) => s.toEntity(
                domainId: id,
                schoolId: schoolId,
                createdAt: now,
                updatedAt: now,
              ))
          .toList(),
      active: active,
      schoolId: schoolId,
      createdAt: now,
      updatedAt: now,
    );
  }
}
