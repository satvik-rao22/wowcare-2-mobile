import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';

/// Persistence contract for the Assessments module.
///
/// The development implementation is local-first (Isar, seeded from bundled
/// mock JSON) — mirroring the Events/Tasks modules — so swapping in a
/// REST-backed implementation later (PRD §18) only changes where the data comes
/// from, not these signatures.
abstract class AssessmentRepository {
  // ----------------------------------------------------- parameter hierarchy

  /// Full Domain → Subdomain → Milestone hierarchy, including soft-deleted
  /// items (callers filter by [AssessmentDomain.active] etc.). Historical data
  /// behind deactivated parameters is preserved (PRD BR-DM-05).
  Future<List<AssessmentDomain>> getDomains();

  /// Creates (when [AssessmentDomain.id] is empty) or updates a domain.
  Future<AssessmentDomain> saveDomain(AssessmentDomain domain);

  /// Soft-deletes a domain (status → inactive). Does not cascade to its
  /// subdomains/milestones (PRD BR-DM-03/04).
  Future<void> deactivateDomain(String domainId);

  /// Creates or updates a subdomain under its parent domain.
  Future<AssessmentSubdomain> saveSubdomain(AssessmentSubdomain subdomain);

  Future<void> deactivateSubdomain(String subdomainId);

  /// Creates or updates a milestone under its parent subdomain.
  Future<AssessmentMilestone> saveMilestone(AssessmentMilestone milestone);

  Future<void> deactivateMilestone(String milestoneId);

  /// Updates only the classroom assignment for a milestone (PRD FR-MS-14..17).
  /// Removing a classroom does not delete existing assessment records
  /// (BR-PM-02).
  Future<AssessmentMilestone> updateMilestoneClassrooms(
    String milestoneId,
    List<String> classroomCodes,
  );

  // ------------------------------------------------------------- assessments

  /// All assessment records (local-first). Callers filter by student /
  /// classroom / period and aggregate.
  Future<List<Assessment>> getAssessments();

  /// Bulk upsert for the "Save All Assessments" flow (PRD FR-SA-12/13). Must be
  /// transactional: all records persist or none do (NFR — bulk save).
  Future<List<Assessment>> bulkUpsertAssessments(List<Assessment> assessments);

  // ----------------------------------------------------- reference snapshots

  Future<List<AssessmentClassroom>> getClassrooms();

  Future<List<AssessmentStudent>> getStudents();
}
