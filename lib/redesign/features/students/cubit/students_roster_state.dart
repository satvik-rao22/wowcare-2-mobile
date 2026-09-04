part of 'students_roster_cubit.dart';

/// The five things the roster can be. 5g draws four of them; [ready] with an
/// empty list is the fifth and sixth, because "no students yet" and "nobody
/// called Kowalski" are the same fetch with different answers.
enum RosterStatus {
  loading,
  ready,

  /// The fetch threw. A Try again key, not an empty state.
  failed,

  /// No signal: this is what the phone had saved.
  offline,

  /// This account may not read student records here.
  restricted,
}

@immutable
class StudentsRosterState extends Equatable {
  const StudentsRosterState({
    required this.persona,
    this.scopeClassroom,
    this.status = RosterStatus.loading,
    this.snapshot = const RosterSnapshot(),
    this.filter = const StudentFilter(),
    this.query = '',
    this.expandedId,
    this.isSelectMode = false,
    this.selectedIds = const <String>{},
    this.asOfLabel,
    this.isWorking = false,
  });

  final Persona persona;

  /// The classroom a staff member is rostered to. Null for an admin, who
  /// sees the school.
  final String? scopeClassroom;

  final RosterStatus status;
  final RosterSnapshot snapshot;
  final StudentFilter filter;
  final String query;

  /// The one row showing its detail block. Null when every row is closed.
  final String? expandedId;

  final bool isSelectMode;
  final Set<String> selectedIds;

  /// "8:12 this morning", set only while [status] is offline.
  final String? asOfLabel;

  /// A deactivate is in flight.
  final bool isWorking;

  bool get isLoading => status == RosterStatus.loading;
  bool get isFailed => status == RosterStatus.failed;
  bool get isOffline => status == RosterStatus.offline;
  bool get isRestricted => status == RosterStatus.restricted;

  /// Adding, editing and deactivating students is admin work. A staff member
  /// reads their own classroom and nothing more.
  bool get canWrite => persona == Persona.admin;

  /// The school has nobody on it at all, which is a different sentence from
  /// a filter that matched nothing.
  bool get isEmptySchool => snapshot.isEmpty;

  bool get isNarrowed => query.trim().isNotEmpty || !filter.isDefault;

  /// The list the Status filter picks from. The demo world has no inactive
  /// students, which is itself one of 5g's states.
  List<StudentSummary> get _pool => switch (filter.status) {
    StudentStatus.active => snapshot.students,
    StudentStatus.upcoming => snapshot.upcoming,
    StudentStatus.inactive => const <StudentSummary>[],
  };

  /// Everything still standing after the search and the five filter
  /// sections, in the order the roster returned.
  List<StudentSummary> get visibleStudents {
    final term = query.trim().toLowerCase();
    return <StudentSummary>[
      for (final student in _pool)
        if (_matches(student, term)) student,
    ];
  }

  bool _matches(StudentSummary student, String term) {
    if (term.isNotEmpty &&
        !student.fullName.toLowerCase().contains(term) &&
        !student.guardianNames.any((g) => g.toLowerCase().contains(term))) {
      return false;
    }
    if (filter.classrooms.isNotEmpty &&
        !filter.classrooms.contains(student.classroomName)) {
      return false;
    }
    if (filter.tags.isNotEmpty &&
        !student.tags.any((t) => filter.tags.contains(t.label))) {
      return false;
    }
    if (filter.guardians.isNotEmpty &&
        !student.guardianNames.any(filter.guardians.contains)) {
      return false;
    }
    if (filter.attendance.isNotEmpty &&
        !filter.attendance.contains(student.attendance)) {
      return false;
    }
    return true;
  }

  /// A group per classroom, in the school's own classroom order, skipping
  /// the ones the filter emptied.
  List<RosterGroup> get groups {
    final visible = visibleStudents;
    return <RosterGroup>[
      for (final name in snapshot.classroomNames)
        if (visible.any((s) => s.classroomName == name))
          RosterGroup(
            classroomName: name,
            students: <StudentSummary>[
              for (final student in visible)
                if (student.classroomName == name) student,
            ],
          ),
    ];
  }

  /// "Starting soon" is a section of the active roster, not a filter of it,
  /// so it goes away as soon as the list is narrowed to something else.
  List<StudentSummary> get startingSoon =>
      canWrite && !isNarrowed && filter.status == StudentStatus.active
      ? snapshot.upcoming
      : const <StudentSummary>[];

  /// The filter matched nothing, but the school is not empty.
  bool get hasNoResults => !isEmptySchool && visibleStudents.isEmpty;

  /// How many students today's counts are drawn from, for the offline line.
  int get savedCount => snapshot.activeCount;

  StudentsRosterState copyWith({
    RosterStatus? status,
    RosterSnapshot? snapshot,
    StudentFilter? filter,
    String? query,
    String? expandedId,
    bool? isSelectMode,
    Set<String>? selectedIds,
    String? asOfLabel,
    bool? isWorking,
    bool clearExpanded = false,
    bool clearAsOfLabel = false,
  }) => StudentsRosterState(
    persona: persona,
    scopeClassroom: scopeClassroom,
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    expandedId: clearExpanded ? null : expandedId ?? this.expandedId,
    isSelectMode: isSelectMode ?? this.isSelectMode,
    selectedIds: selectedIds ?? this.selectedIds,
    asOfLabel: clearAsOfLabel ? null : asOfLabel ?? this.asOfLabel,
    isWorking: isWorking ?? this.isWorking,
  );

  @override
  List<Object?> get props => [
    persona,
    scopeClassroom,
    status,
    snapshot,
    filter,
    query,
    expandedId,
    isSelectMode,
    selectedIds,
    asOfLabel,
    isWorking,
  ];
}
