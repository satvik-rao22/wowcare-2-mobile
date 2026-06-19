part of 'assessments_cubit.dart';

/// Where a milestone sits in the hierarchy — used when building assessment
/// records (which carry denormalised subdomainId/domainId).
class MilestoneLocator {
  const MilestoneLocator({
    required this.milestone,
    required this.subdomainId,
    required this.domainId,
  });

  final AssessmentMilestone milestone;
  final String subdomainId;
  final String domainId;
}

class AssessmentsState extends Equatable {
  const AssessmentsState({
    required this.domains,
    required this.assessments,
    required this.classrooms,
    required this.students,
    required this.period,
    required this.isLoading,
    required this.isSaving,
    required this.selectedClassroomCode,
    required this.currentUserCode,
    required this.currentUserName,
    required this.roleKey,
    required this.schoolId,
    this.errorMessage,
  });

  factory AssessmentsState.initial() => AssessmentsState(
        domains: const [],
        assessments: const [],
        classrooms: const [],
        students: const [],
        period: AssessmentPeriod.current(),
        isLoading: true,
        isSaving: false,
        selectedClassroomCode: null,
        currentUserCode: '',
        currentUserName: '',
        roleKey: 'admin',
        schoolId: 'SCH-DEMO',
        errorMessage: null,
      );

  final List<AssessmentDomain> domains;
  final List<Assessment> assessments;
  final List<AssessmentClassroom> classrooms;
  final List<AssessmentStudent> students;
  final AssessmentPeriod period;
  final bool isLoading;
  final bool isSaving;

  /// Classroom selected in the Student Assessment list filter (null = none yet).
  final String? selectedClassroomCode;
  final String currentUserCode;
  final String currentUserName;

  /// Lowercased persona key: 'admin' | 'staff' | 'parent'.
  final String roleKey;
  final String schoolId;
  final String? errorMessage;

  bool get isStaffPersona => roleKey == 'staff' || roleKey == 'teacher';

  // ----------------------------------------------------------- parameter tree

  /// Active domains only, name-sorted (already sorted by the repository).
  List<AssessmentDomain> get activeDomains =>
      domains.where((d) => d.active).toList();

  /// Active domains whose assignment includes [classroomCode] OR that have an
  /// active milestone assigned to it — i.e. domains relevant when assessing a
  /// student in that classroom (PRD FR-SA-08/11, BR-PM-01).
  List<AssessmentDomain> domainsForClassroom(String classroomCode) {
    return activeDomains.where((d) {
      return d.activeSubdomains.any((s) =>
          s.activeMilestones.any((m) => m.isAssignedTo(classroomCode)));
    }).toList();
  }

  /// Active milestones in [domain] assigned to [classroomCode], grouped by
  /// their parent subdomain (preserves subdomain order).
  Map<AssessmentSubdomain, List<AssessmentMilestone>> milestonesBySubdomain(
    AssessmentDomain domain,
    String classroomCode,
  ) {
    final result = <AssessmentSubdomain, List<AssessmentMilestone>>{};
    for (final subdomain in domain.activeSubdomains) {
      final milestones = subdomain.activeMilestones
          .where((m) => m.isAssignedTo(classroomCode))
          .toList();
      if (milestones.isNotEmpty) result[subdomain] = milestones;
    }
    return result;
  }

  /// All active milestones in [domain] assigned to [classroomCode] (flat).
  List<AssessmentMilestone> milestonesForClassroom(
    AssessmentDomain domain,
    String classroomCode,
  ) {
    return domain.activeSubdomains
        .expand((s) => s.activeMilestones)
        .where((m) => m.isAssignedTo(classroomCode))
        .toList();
  }

  MilestoneLocator? locateMilestone(String milestoneId) {
    for (final domain in domains) {
      for (final subdomain in domain.subdomains) {
        for (final milestone in subdomain.milestones) {
          if (milestone.id == milestoneId) {
            return MilestoneLocator(
              milestone: milestone,
              subdomainId: subdomain.id,
              domainId: domain.id,
            );
          }
        }
      }
    }
    return null;
  }

  AssessmentDomain? domainById(String id) {
    for (final d in domains) {
      if (d.id == id) return d;
    }
    return null;
  }

  // ------------------------------------------------------------- references

  AssessmentClassroom? classroomByCode(String code) {
    for (final c in classrooms) {
      if (c.code == code) return c;
    }
    return null;
  }

  /// Active students in [classroomCode], name-sorted.
  List<AssessmentStudent> studentsInClassroom(String classroomCode) {
    return students
        .where((s) => s.classroomCode == classroomCode && s.isActive)
        .toList();
  }

  int studentCountIn(String classroomCode) =>
      studentsInClassroom(classroomCode).length;

  AssessmentStudent? studentByCode(String code) {
    for (final s in students) {
      if (s.code == code) return s;
    }
    return null;
  }

  // ------------------------------------------------------------- assessments

  /// Records for [period] (matched by month).
  List<Assessment> assessmentsForPeriod(AssessmentPeriod period) {
    return assessments
        .where((a) =>
            a.periodStart.year == period.start.year &&
            a.periodStart.month == period.start.month)
        .toList();
  }

  /// Records for one student in [period].
  List<Assessment> studentAssessments(String studentId, AssessmentPeriod period) {
    return assessmentsForPeriod(period)
        .where((a) => a.studentId == studentId)
        .toList();
  }

  Assessment? existingAssessment({
    required String studentId,
    required String milestoneId,
    required AssessmentPeriod period,
  }) {
    for (final a in assessmentsForPeriod(period)) {
      if (a.studentId == studentId && a.milestoneId == milestoneId) return a;
    }
    return null;
  }

  AssessmentsState copyWith({
    List<AssessmentDomain>? domains,
    List<Assessment>? assessments,
    List<AssessmentClassroom>? classrooms,
    List<AssessmentStudent>? students,
    AssessmentPeriod? period,
    bool? isLoading,
    bool? isSaving,
    String? Function()? selectedClassroomCode,
    String? currentUserCode,
    String? currentUserName,
    String? roleKey,
    String? schoolId,
    String? Function()? errorMessage,
  }) {
    return AssessmentsState(
      domains: domains ?? this.domains,
      assessments: assessments ?? this.assessments,
      classrooms: classrooms ?? this.classrooms,
      students: students ?? this.students,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedClassroomCode: selectedClassroomCode != null
          ? selectedClassroomCode()
          : this.selectedClassroomCode,
      currentUserCode: currentUserCode ?? this.currentUserCode,
      currentUserName: currentUserName ?? this.currentUserName,
      roleKey: roleKey ?? this.roleKey,
      schoolId: schoolId ?? this.schoolId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        domains,
        assessments,
        classrooms,
        students,
        period,
        isLoading,
        isSaving,
        selectedClassroomCode,
        currentUserCode,
        currentUserName,
        roleKey,
        schoolId,
        errorMessage,
      ];
}
