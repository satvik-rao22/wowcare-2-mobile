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
    required this.ageGroups,
    required this.period,
    required this.isLoading,
    required this.isSaving,
    required this.selectedClassroomCode,
    required this.currentUserCode,
    required this.currentUserName,
    required this.roleKey,
    required this.schoolId,
    this.statusFilter = const {'ACTIVE'},
    this.tagFilter = const {},
    this.themeV2 = false,
    this.errorMessage,
  });

  factory AssessmentsState.initial() => AssessmentsState(
        domains: const [],
        assessments: const [],
        classrooms: const [],
        students: const [],
        ageGroups: const [],
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

  /// The school's age bands (sorted by sortOrder, then minMonths).
  final List<AssessmentAgeGroup> ageGroups;
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

  /// Student-list status filter: subset of {'ACTIVE', 'INACTIVE'}. Defaults to
  /// active-only, matching the list's pre-filter behaviour.
  final Set<String> statusFilter;

  /// Student-list tag filter (empty = no tag restriction).
  final Set<String> tagFilter;

  /// Whether the module renders with the 2.0 colour theme. Mirrored into
  /// [AssessmentUi.palette] by the cubit; kept on state so toggling rebuilds
  /// every BlocBuilder in the shell.
  final bool themeV2;
  final String? errorMessage;

  bool get isStaffPersona => roleKey == 'staff' || roleKey == 'teacher';

  // -------------------------------------------------------------- age groups

  /// Active bands, in display order.
  List<AssessmentAgeGroup> get activeAgeGroups =>
      ageGroups.where((g) => g.active).toList();

  AssessmentAgeGroup? ageGroupById(String id) {
    for (final g in ageGroups) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// The band [student] falls into for the active [period], resolved from
  /// their date of birth **as of the period start** — a child crossing a band
  /// boundary mid-month is assessed against one deterministic band for the
  /// whole month. Null when the student has no DOB or no active band contains
  /// their age.
  AssessmentAgeGroup? resolveAgeGroup(AssessmentStudent student) {
    final months = student.ageInMonthsAt(period.start);
    if (months == null) return null;
    for (final g in activeAgeGroups) {
      if (g.contains(months)) return g;
    }
    return null;
  }

  /// The set of band ids represented by the active students of
  /// [classroomCode] in the active period. Classrooms mix ages, so classroom
  /// and school roll-ups aggregate over every band their children resolve to.
  Set<String> ageGroupIdsForClassroom(String classroomCode) {
    final ids = <String>{};
    for (final s in studentsInClassroom(classroomCode)) {
      final band = resolveAgeGroup(s);
      if (band != null) ids.add(band.id);
    }
    return ids;
  }

  // ----------------------------------------------------------- parameter tree

  /// Active domains only, name-sorted (already sorted by the repository).
  List<AssessmentDomain> get activeDomains =>
      domains.where((d) => d.active).toList();

  /// Active domains with at least one active milestone assigned to any band
  /// in [ageGroupIds] — i.e. domains relevant when assessing a student who
  /// resolved to one of those bands (adapts PRD FR-SA-08/11, BR-PM-01).
  List<AssessmentDomain> domainsForAgeGroups(Set<String> ageGroupIds) {
    if (ageGroupIds.isEmpty) return const [];
    return activeDomains.where((d) {
      return d.activeSubdomains.any((s) => s.activeMilestones
          .any((m) => m.isAssignedToAnyAgeGroup(ageGroupIds)));
    }).toList();
  }

  /// Domains relevant to [student]: resolved from their DOB band.
  List<AssessmentDomain> domainsForStudent(AssessmentStudent student) {
    final band = resolveAgeGroup(student);
    return band == null ? const [] : domainsForAgeGroups({band.id});
  }

  /// Domains relevant to [classroomCode]: the union over the bands its
  /// students resolve to (a classroom no longer gates visibility itself).
  List<AssessmentDomain> domainsForClassroom(String classroomCode) =>
      domainsForAgeGroups(ageGroupIdsForClassroom(classroomCode));

  /// Active milestones in [domain] assigned to any band in [ageGroupIds],
  /// grouped by their parent subdomain (preserves subdomain order).
  Map<AssessmentSubdomain, List<AssessmentMilestone>> milestonesBySubdomain(
    AssessmentDomain domain,
    Set<String> ageGroupIds,
  ) {
    final result = <AssessmentSubdomain, List<AssessmentMilestone>>{};
    for (final subdomain in domain.activeSubdomains) {
      final milestones = subdomain.activeMilestones
          .where((m) => m.isAssignedToAnyAgeGroup(ageGroupIds))
          .toList();
      if (milestones.isNotEmpty) result[subdomain] = milestones;
    }
    return result;
  }

  /// All active milestones in [domain] assigned to any band in [ageGroupIds]
  /// (flat).
  List<AssessmentMilestone> milestonesForAgeGroups(
    AssessmentDomain domain,
    Set<String> ageGroupIds,
  ) {
    return domain.activeSubdomains
        .expand((s) => s.activeMilestones)
        .where((m) => m.isAssignedToAnyAgeGroup(ageGroupIds))
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

  /// Students in [classroomCode] matching the Students-tab [statusFilter] and
  /// [tagFilter] (used by [StudentsListBody] instead of [studentsInClassroom],
  /// which stays active-only for classroom/school roll-up aggregation).
  List<AssessmentStudent> visibleStudentsInClassroom(String classroomCode) {
    return students.where((s) {
      if (s.classroomCode != classroomCode) return false;
      if (statusFilter.isNotEmpty &&
          !statusFilter.contains(s.status.toUpperCase())) {
        return false;
      }
      if (tagFilter.isNotEmpty && !tagFilter.any(s.tags.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// All distinct student tags across the school, sorted for the filter sheet.
  List<String> get allTags {
    final set = <String>{};
    for (final s in students) {
      set.addAll(s.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

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

  /// Whether every scored record for [studentId] in [period] has been
  /// published (records are always published together, so any one record's
  /// flag represents the whole set — checking `every` is just the safe form).
  bool isPublished(String studentId, AssessmentPeriod period) {
    final records = studentAssessments(studentId, period);
    return records.isNotEmpty && records.every((a) => a.published);
  }

  AssessmentsState copyWith({
    List<AssessmentDomain>? domains,
    List<Assessment>? assessments,
    List<AssessmentClassroom>? classrooms,
    List<AssessmentStudent>? students,
    List<AssessmentAgeGroup>? ageGroups,
    AssessmentPeriod? period,
    bool? isLoading,
    bool? isSaving,
    String? Function()? selectedClassroomCode,
    String? currentUserCode,
    String? currentUserName,
    String? roleKey,
    String? schoolId,
    Set<String>? statusFilter,
    Set<String>? tagFilter,
    bool? themeV2,
    String? Function()? errorMessage,
  }) {
    return AssessmentsState(
      domains: domains ?? this.domains,
      assessments: assessments ?? this.assessments,
      classrooms: classrooms ?? this.classrooms,
      students: students ?? this.students,
      ageGroups: ageGroups ?? this.ageGroups,
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
      statusFilter: statusFilter ?? this.statusFilter,
      tagFilter: tagFilter ?? this.tagFilter,
      themeV2: themeV2 ?? this.themeV2,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        domains,
        assessments,
        classrooms,
        students,
        ageGroups,
        period,
        isLoading,
        isSaving,
        selectedClassroomCode,
        currentUserCode,
        currentUserName,
        roleKey,
        schoolId,
        statusFilter,
        tagFilter,
        themeV2,
        errorMessage,
      ];
}
