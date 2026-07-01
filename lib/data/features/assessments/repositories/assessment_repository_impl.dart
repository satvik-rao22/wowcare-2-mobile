import 'package:uuid/uuid.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/assessments/datasources/assessment_local_datasource.dart';
import 'package:wowcare/data/features/assessments/datasources/assessment_seed_datasource.dart';
import 'package:wowcare/data/features/assessments/models/assessment_collection.dart';
import 'package:wowcare/data/features/assessments/models/assessment_domain_collection.dart';
import 'package:wowcare/data/features/assessments/models/assessment_reference_collection.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

/// Local-first implementation: seeds bundled mock data into Isar on first run,
/// then serves all reads/writes from the local database (mirrors the Events and
/// Tasks modules). Designed so a remote (REST) implementation can replace it
/// without changing the repository contract.
class AssessmentRepositoryImpl implements AssessmentRepository {
  AssessmentRepositoryImpl(
    this._localDataSource,
    this._seedDataSource,
    this._storageService,
  );

  final AssessmentLocalDataSource _localDataSource;
  final AssessmentSeedDataSource _seedDataSource;
  final StorageService _storageService;

  static const _uuid = Uuid();

  /// One-shot seed flag so user mutations aren't resurrected by reseeding.
  static const String _seededFlagKey = 'assessments_mock_seeded_v2';

  // ----------------------------------------------------------------- domains

  @override
  Future<List<AssessmentDomain>> getDomains() async {
    await _seedIfNeeded();
    final rows = await _localDataSource.getDomains();
    final domains = rows.map((r) => r.toEntity()).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return domains;
  }

  @override
  Future<AssessmentDomain> saveDomain(AssessmentDomain domain) async {
    final now = DateTime.now();
    final isNew = domain.id.trim().isEmpty;
    final toSave = domain.copyWith(
      id: isNew ? 'DOM-${_uuid.v4()}' : domain.id,
      createdAt: isNew ? now : domain.createdAt,
      updatedAt: now,
    );
    await _localDataSource.upsertDomain(
      AssessmentDomainCollection.fromEntity(toSave),
    );
    return toSave;
  }

  @override
  Future<void> deactivateDomain(String domainId) async {
    final domain = await _findDomain(domainId);
    if (domain == null) return;
    await _localDataSource.upsertDomain(
      AssessmentDomainCollection.fromEntity(
        domain.copyWith(active: false, updatedAt: DateTime.now()),
      ),
    );
  }

  // -------------------------------------------------------------- subdomains

  @override
  Future<AssessmentSubdomain> saveSubdomain(
    AssessmentSubdomain subdomain,
  ) async {
    final domain = await _findDomain(subdomain.domainId);
    if (domain == null) {
      throw StateError('Parent domain ${subdomain.domainId} not found');
    }
    final now = DateTime.now();
    final isNew = subdomain.id.trim().isEmpty;
    final toSave = subdomain.copyWith(
      id: isNew ? 'SUB-${_uuid.v4()}' : subdomain.id,
      createdAt: isNew ? now : subdomain.createdAt,
      updatedAt: now,
    );
    final existing = List<AssessmentSubdomain>.from(domain.subdomains);
    final index = existing.indexWhere((s) => s.id == toSave.id);
    if (index >= 0) {
      // Preserve existing milestones when editing name/classrooms only.
      existing[index] = toSave.copyWith(
        milestones: toSave.milestones.isEmpty
            ? existing[index].milestones
            : toSave.milestones,
      );
    } else {
      existing.add(toSave);
    }
    await _localDataSource.upsertDomain(
      AssessmentDomainCollection.fromEntity(
        domain.copyWith(subdomains: existing, updatedAt: now),
      ),
    );
    return toSave;
  }

  @override
  Future<void> deactivateSubdomain(String subdomainId) async {
    await _mutateSubdomain(
      subdomainId,
      (s) => s.copyWith(active: false, updatedAt: DateTime.now()),
    );
  }

  // --------------------------------------------------------------- milestones

  @override
  Future<AssessmentMilestone> saveMilestone(
    AssessmentMilestone milestone,
  ) async {
    final domain = await _findDomain(milestone.domainId);
    if (domain == null) {
      throw StateError('Parent domain ${milestone.domainId} not found');
    }
    final now = DateTime.now();
    final isNew = milestone.id.trim().isEmpty;
    final toSave = milestone.copyWith(
      id: isNew ? 'MIL-${_uuid.v4()}' : milestone.id,
      createdAt: isNew ? now : milestone.createdAt,
      updatedAt: now,
    );
    final subdomains = List<AssessmentSubdomain>.from(domain.subdomains);
    final sIndex =
        subdomains.indexWhere((s) => s.id == toSave.subdomainId);
    if (sIndex < 0) {
      throw StateError('Parent subdomain ${toSave.subdomainId} not found');
    }
    final milestones =
        List<AssessmentMilestone>.from(subdomains[sIndex].milestones);
    final mIndex = milestones.indexWhere((m) => m.id == toSave.id);
    if (mIndex >= 0) {
      milestones[mIndex] = toSave;
    } else {
      milestones.add(toSave);
    }
    subdomains[sIndex] =
        subdomains[sIndex].copyWith(milestones: milestones, updatedAt: now);
    await _localDataSource.upsertDomain(
      AssessmentDomainCollection.fromEntity(
        domain.copyWith(subdomains: subdomains, updatedAt: now),
      ),
    );
    return toSave;
  }

  @override
  Future<void> deactivateMilestone(String milestoneId) async {
    await _mutateMilestone(
      milestoneId,
      (m) => m.copyWith(active: false, updatedAt: DateTime.now()),
    );
  }

  @override
  Future<AssessmentMilestone> updateMilestoneClassrooms(
    String milestoneId,
    List<String> classroomCodes,
  ) async {
    final updated = await _mutateMilestone(
      milestoneId,
      (m) => m.copyWith(
        assignedClassrooms: List<String>.from(classroomCodes),
        updatedAt: DateTime.now(),
      ),
    );
    if (updated == null) {
      throw StateError('Milestone $milestoneId not found');
    }
    return updated;
  }

  // ------------------------------------------------------------- assessments

  @override
  Future<List<Assessment>> getAssessments() async {
    await _seedIfNeeded();
    final rows = await _localDataSource.getAssessments();
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Future<List<Assessment>> bulkUpsertAssessments(
    List<Assessment> assessments,
  ) async {
    if (assessments.isEmpty) return const <Assessment>[];
    await _localDataSource.upsertAssessments(
      assessments.map(AssessmentCollection.fromEntity).toList(),
    );
    return assessments;
  }

  // ------------------------------------------------------- reference data

  @override
  Future<List<AssessmentClassroom>> getClassrooms() async {
    await _seedIfNeeded();
    final rows = await _localDataSource.getClassrooms();
    return rows.map((r) => r.toEntity()).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<AssessmentStudent>> getStudents() async {
    await _seedIfNeeded();
    final rows = await _localDataSource.getStudents();
    return rows.map((r) => r.toEntity()).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ----------------------------------------------------------------- helpers

  Future<AssessmentDomain?> _findDomain(String domainId) async {
    final row = await _localDataSource.getDomainById(domainId);
    return row?.toEntity();
  }

  /// Finds the domain holding [subdomainId], applies [transform] to that
  /// subdomain, and persists. Returns the updated subdomain, or null if absent.
  Future<AssessmentSubdomain?> _mutateSubdomain(
    String subdomainId,
    AssessmentSubdomain Function(AssessmentSubdomain) transform,
  ) async {
    final domains = await _localDataSource.getDomains();
    for (final row in domains) {
      final domain = row.toEntity();
      final index = domain.subdomains.indexWhere((s) => s.id == subdomainId);
      if (index < 0) continue;
      final updated = transform(domain.subdomains[index]);
      final subdomains = List<AssessmentSubdomain>.from(domain.subdomains)
        ..[index] = updated;
      await _localDataSource.upsertDomain(
        AssessmentDomainCollection.fromEntity(
          domain.copyWith(subdomains: subdomains, updatedAt: DateTime.now()),
        ),
      );
      return updated;
    }
    return null;
  }

  /// Finds the milestone across all domains/subdomains, applies [transform],
  /// and persists. Returns the updated milestone, or null if absent.
  Future<AssessmentMilestone?> _mutateMilestone(
    String milestoneId,
    AssessmentMilestone Function(AssessmentMilestone) transform,
  ) async {
    final domains = await _localDataSource.getDomains();
    for (final row in domains) {
      final domain = row.toEntity();
      final subdomains = List<AssessmentSubdomain>.from(domain.subdomains);
      for (var i = 0; i < subdomains.length; i++) {
        final milestones =
            List<AssessmentMilestone>.from(subdomains[i].milestones);
        final mIndex = milestones.indexWhere((m) => m.id == milestoneId);
        if (mIndex < 0) continue;
        final updated = transform(milestones[mIndex]);
        milestones[mIndex] = updated;
        subdomains[i] = subdomains[i].copyWith(milestones: milestones);
        await _localDataSource.upsertDomain(
          AssessmentDomainCollection.fromEntity(
            domain.copyWith(subdomains: subdomains, updatedAt: DateTime.now()),
          ),
        );
        return updated;
      }
    }
    return null;
  }

  Future<void> _seedIfNeeded() async {
    final alreadySeeded =
        await _storageService.getBool(_seededFlagKey) ?? false;
    if (alreadySeeded) return;

    final existingDomains = await _localDataSource.getDomains();
    if (existingDomains.isEmpty) {
      final domains = await _seedDataSource.fetchDomains();
      if (domains.isNotEmpty) {
        await _localDataSource.upsertDomains(
          domains
              .map((m) => AssessmentDomainCollection.fromEntity(m.toEntity()))
              .toList(),
        );
      }
    }

    final existingClassrooms = await _localDataSource.getClassrooms();
    if (existingClassrooms.isEmpty) {
      final classrooms = await _seedDataSource.fetchClassrooms();
      if (classrooms.isNotEmpty) {
        await _localDataSource.upsertClassrooms(
          classrooms
              .map((m) =>
                  AssessmentClassroomCollection.fromEntity(m.toEntity()))
              .toList(),
        );
      }
    }

    // Unconditionally re-upserted (unlike the other sections) so bumping
    // [_seededFlagKey] can backfill new mock fields (e.g. tags) onto students
    // an earlier version already seeded. Safe: students are a read-only
    // snapshot never mutated by this module, and the `code` index is
    // unique+replace so this overwrites in place without duplicating rows.
    final students = await _seedDataSource.fetchStudents();
    if (students.isNotEmpty) {
      await _localDataSource.upsertStudents(
        students
            .map((m) => AssessmentStudentCollection.fromEntity(m.toEntity()))
            .toList(),
      );
    }

    final existingAssessments = await _localDataSource.getAssessments();
    if (existingAssessments.isEmpty) {
      final assessments = await _seedDataSource.fetchAssessments();
      if (assessments.isNotEmpty) {
        await _localDataSource.upsertAssessments(
          assessments
              .map((m) => AssessmentCollection.fromEntity(m.toEntity()))
              .toList(),
        );
      }
    }

    await _storageService.saveBool(_seededFlagKey, true);
  }
}
