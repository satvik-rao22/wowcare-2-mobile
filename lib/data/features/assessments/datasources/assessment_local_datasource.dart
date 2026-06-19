import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/data/features/assessments/models/assessment_collection.dart';
import 'package:wowcare/data/features/assessments/models/assessment_domain_collection.dart';
import 'package:wowcare/data/features/assessments/models/assessment_reference_collection.dart';

/// Isar-backed persistence for the Assessments module. All reads/writes go
/// through the shared [CacheService] so they live in the same database (and
/// follow the same wipe-on-logout rules) as the rest of the app's local data.
abstract class AssessmentLocalDataSource {
  Future<List<AssessmentDomainCollection>> getDomains();
  Future<AssessmentDomainCollection?> getDomainById(String id);
  Future<void> upsertDomain(AssessmentDomainCollection domain);
  Future<void> upsertDomains(List<AssessmentDomainCollection> domains);

  Future<List<AssessmentCollection>> getAssessments();
  Future<void> upsertAssessments(List<AssessmentCollection> assessments);

  Future<List<AssessmentClassroomCollection>> getClassrooms();
  Future<void> upsertClassrooms(List<AssessmentClassroomCollection> classrooms);

  Future<List<AssessmentStudentCollection>> getStudents();
  Future<void> upsertStudents(List<AssessmentStudentCollection> students);
}

class AssessmentLocalDataSourceImpl implements AssessmentLocalDataSource {
  AssessmentLocalDataSourceImpl(this._cacheService);

  final CacheService _cacheService;

  @override
  Future<List<AssessmentDomainCollection>> getDomains() =>
      _cacheService.getAll<AssessmentDomainCollection>();

  @override
  Future<AssessmentDomainCollection?> getDomainById(String id) =>
      _cacheService.get<AssessmentDomainCollection>(fastHash(id));

  @override
  Future<void> upsertDomain(AssessmentDomainCollection domain) =>
      _cacheService.put<AssessmentDomainCollection>(domain);

  @override
  Future<void> upsertDomains(List<AssessmentDomainCollection> domains) =>
      _cacheService.putAll<AssessmentDomainCollection>(domains);

  @override
  Future<List<AssessmentCollection>> getAssessments() =>
      _cacheService.getAll<AssessmentCollection>();

  @override
  Future<void> upsertAssessments(List<AssessmentCollection> assessments) =>
      _cacheService.putAll<AssessmentCollection>(assessments);

  @override
  Future<List<AssessmentClassroomCollection>> getClassrooms() =>
      _cacheService.getAll<AssessmentClassroomCollection>();

  @override
  Future<void> upsertClassrooms(
    List<AssessmentClassroomCollection> classrooms,
  ) =>
      _cacheService.putAll<AssessmentClassroomCollection>(classrooms);

  @override
  Future<List<AssessmentStudentCollection>> getStudents() =>
      _cacheService.getAll<AssessmentStudentCollection>();

  @override
  Future<void> upsertStudents(List<AssessmentStudentCollection> students) =>
      _cacheService.putAll<AssessmentStudentCollection>(students);
}
