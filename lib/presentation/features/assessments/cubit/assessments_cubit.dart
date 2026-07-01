import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/domain/features/assessments/usecases/bulk_upsert_assessments_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/deactivate_assessment_domain_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/deactivate_assessment_milestone_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/deactivate_assessment_subdomain_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/get_assessment_classrooms_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/get_assessment_domains_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/get_assessment_students_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/get_assessments_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/save_assessment_domain_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/save_assessment_milestone_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/save_assessment_subdomain_usecase.dart';
import 'package:wowcare/domain/features/assessments/usecases/update_milestone_classrooms_usecase.dart';

part 'assessments_state.dart';

/// Single source of truth for the Assessments module, shared across Parameter
/// Management and the Student/Classroom/School assessment screens (mirrors the
/// singleton EventsCubit/TasksCubit). Holds the full parameter hierarchy, the
/// scored records, the reference classrooms/students, and the currently
/// selected assessment period.
///
/// MVVM golden rule: no View dependency (no BuildContext / widgets / nav).
class AssessmentsCubit extends Cubit<AssessmentsState> {
  AssessmentsCubit({
    required GetAssessmentDomainsUseCase getDomains,
    required SaveAssessmentDomainUseCase saveDomain,
    required DeactivateAssessmentDomainUseCase deactivateDomain,
    required SaveAssessmentSubdomainUseCase saveSubdomain,
    required DeactivateAssessmentSubdomainUseCase deactivateSubdomain,
    required SaveAssessmentMilestoneUseCase saveMilestone,
    required DeactivateAssessmentMilestoneUseCase deactivateMilestone,
    required UpdateMilestoneClassroomsUseCase updateMilestoneClassrooms,
    required GetAssessmentsUseCase getAssessments,
    required BulkUpsertAssessmentsUseCase bulkUpsertAssessments,
    required GetAssessmentClassroomsUseCase getClassrooms,
    required GetAssessmentStudentsUseCase getStudents,
    required StorageService storageService,
  })  : _getDomains = getDomains,
        _saveDomain = saveDomain,
        _deactivateDomain = deactivateDomain,
        _saveSubdomain = saveSubdomain,
        _deactivateSubdomain = deactivateSubdomain,
        _saveMilestone = saveMilestone,
        _deactivateMilestone = deactivateMilestone,
        _updateMilestoneClassrooms = updateMilestoneClassrooms,
        _getAssessments = getAssessments,
        _bulkUpsertAssessments = bulkUpsertAssessments,
        _getClassrooms = getClassrooms,
        _getStudents = getStudents,
        _storageService = storageService,
        super(AssessmentsState.initial());

  final GetAssessmentDomainsUseCase _getDomains;
  final SaveAssessmentDomainUseCase _saveDomain;
  final DeactivateAssessmentDomainUseCase _deactivateDomain;
  final SaveAssessmentSubdomainUseCase _saveSubdomain;
  final DeactivateAssessmentSubdomainUseCase _deactivateSubdomain;
  final SaveAssessmentMilestoneUseCase _saveMilestone;
  final DeactivateAssessmentMilestoneUseCase _deactivateMilestone;
  final UpdateMilestoneClassroomsUseCase _updateMilestoneClassrooms;
  final GetAssessmentsUseCase _getAssessments;
  final BulkUpsertAssessmentsUseCase _bulkUpsertAssessments;
  final GetAssessmentClassroomsUseCase _getClassrooms;
  final GetAssessmentStudentsUseCase _getStudents;
  final StorageService _storageService;

  static const _uuid = Uuid();

  void _safeEmit(AssessmentsState next) {
    if (!isClosed) emit(next);
  }

  // --------------------------------------------------------------- lifecycle

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _safeEmit(state.copyWith(isLoading: true, errorMessage: () => null));
    }
    try {
      final domains = await _getDomains();
      final assessments = await _getAssessments();
      final classrooms = await _getClassrooms();
      final students = await _getStudents();

      final userCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      final userName =
          (await _storageService.getString(StorageKeys.displayName) ?? '')
              .trim();
      final role =
          (await _storageService.getString(StorageKeys.activeSchoolRole) ?? '')
              .toLowerCase();
      final schoolId =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

      _safeEmit(state.copyWith(
        domains: domains,
        assessments: assessments,
        classrooms: classrooms,
        students: students,
        currentUserCode: userCode,
        currentUserName: userName,
        roleKey: role,
        schoolId: schoolId.isEmpty ? state.schoolId : schoolId,
        isLoading: false,
        errorMessage: () => null,
      ));
    } catch (e) {
      _safeEmit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to load assessments: $e',
      ));
    }
  }

  // ------------------------------------------------------------- period/scope

  void setPeriodMonth(DateTime month) {
    _safeEmit(state.copyWith(period: AssessmentPeriod.forMonth(month)));
  }

  void setSelectedClassroom(String? classroomCode) {
    _safeEmit(state.copyWith(selectedClassroomCode: () => classroomCode));
  }

  // ------------------------------------------------------- student filters

  void toggleStatusFilter(String status) {
    final next = Set<String>.from(state.statusFilter);
    if (!next.remove(status)) next.add(status);
    _safeEmit(state.copyWith(statusFilter: next));
  }

  void toggleTagFilter(String tag) {
    final next = Set<String>.from(state.tagFilter);
    if (!next.remove(tag)) next.add(tag);
    _safeEmit(state.copyWith(tagFilter: next));
  }

  void clearAssessmentFilters() {
    _safeEmit(state.copyWith(
      statusFilter: const {'ACTIVE'},
      tagFilter: const {},
    ));
  }

  // ----------------------------------------------------- parameter management

  Future<bool> saveDomain(AssessmentDomain domain) async {
    return _guardSave(() async {
      await _saveDomain(domain);
      await _reloadDomains();
    });
  }

  Future<bool> deactivateDomain(String domainId) async {
    return _guardSave(() async {
      await _deactivateDomain(domainId);
      await _reloadDomains();
    });
  }

  Future<bool> saveSubdomain(AssessmentSubdomain subdomain) async {
    return _guardSave(() async {
      await _saveSubdomain(subdomain);
      await _reloadDomains();
    });
  }

  Future<bool> deactivateSubdomain(String subdomainId) async {
    return _guardSave(() async {
      await _deactivateSubdomain(subdomainId);
      await _reloadDomains();
    });
  }

  Future<bool> saveMilestone(AssessmentMilestone milestone) async {
    return _guardSave(() async {
      await _saveMilestone(milestone);
      await _reloadDomains();
    });
  }

  Future<bool> deactivateMilestone(String milestoneId) async {
    return _guardSave(() async {
      await _deactivateMilestone(milestoneId);
      await _reloadDomains();
    });
  }

  Future<bool> updateMilestoneClassrooms(
    String milestoneId,
    List<String> classroomCodes,
  ) async {
    return _guardSave(() async {
      await _updateMilestoneClassrooms(milestoneId, classroomCodes);
      await _reloadDomains();
    });
  }

  // ------------------------------------------------------- student assessment

  /// Persists all scored milestones for a student in the current period in one
  /// transactional upsert (PRD FR-SA-12/13). [drafts] maps milestoneId → score;
  /// [notes] maps milestoneId → notes. Milestones absent from [drafts] (no
  /// score selected) are not written (edge case: unscored milestones skipped).
  Future<bool> saveStudentAssessments({
    required String studentId,
    required Map<String, int> drafts,
    Map<String, String?> notes = const <String, String?>{},
  }) async {
    return _guardSave(() async {
      final period = state.period;
      final now = DateTime.now();
      final records = <Assessment>[];
      for (final entry in drafts.entries) {
        final milestoneId = entry.key;
        final score = entry.value;
        final locator = state.locateMilestone(milestoneId);
        if (locator == null) continue;
        final existing = state.existingAssessment(
          studentId: studentId,
          milestoneId: milestoneId,
          period: period,
        );
        records.add(Assessment(
          id: existing?.id ?? 'ASMT-${_uuid.v4()}',
          studentId: studentId,
          milestoneId: milestoneId,
          subdomainId: locator.subdomainId,
          domainId: locator.domainId,
          score: score,
          notes: notes[milestoneId],
          assessedBy: state.currentUserCode,
          assessedAt: now,
          periodStart: period.start,
          periodEnd: period.end,
          schoolId: state.schoolId,
        ));
      }
      if (records.isEmpty) return;
      await _bulkUpsertAssessments(records);
      _mergeAssessments(records, studentId: studentId, period: period);
    });
  }

  /// Marks every scored record for [studentId] in the current period as
  /// published (a status flag only — publishing never locks the records from
  /// further edits).
  Future<bool> publishStudentAssessments(String studentId) async {
    return _guardSave(() async {
      final period = state.period;
      final records = state
          .studentAssessments(studentId, period)
          .map((a) => a.copyWith(published: true))
          .toList();
      if (records.isEmpty) return;
      await _bulkUpsertAssessments(records);
      _mergeAssessments(records, studentId: studentId, period: period);
    });
  }

  // -------------------------------------------------------------- internals

  Future<bool> _guardSave(Future<void> Function() action) async {
    _safeEmit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      await action();
      _safeEmit(state.copyWith(isSaving: false));
      return true;
    } catch (e) {
      _safeEmit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Operation failed: $e',
      ));
      return false;
    }
  }

  Future<void> _reloadDomains() async {
    final domains = await _getDomains();
    _safeEmit(state.copyWith(domains: domains));
  }

  /// Replaces the student's records for the saved milestones in this period,
  /// leaving other students' and other periods' records untouched.
  void _mergeAssessments(
    List<Assessment> saved, {
    required String studentId,
    required AssessmentPeriod period,
  }) {
    final savedKeys =
        saved.map((a) => '${a.studentId}#${a.milestoneId}').toSet();
    final retained = state.assessments.where((a) {
      final sameSlot = a.studentId == studentId &&
          _sameMonth(a.periodStart, period.start) &&
          savedKeys.contains('${a.studentId}#${a.milestoneId}');
      return !sameSlot;
    }).toList();
    _safeEmit(state.copyWith(assessments: [...retained, ...saved]));
  }

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
