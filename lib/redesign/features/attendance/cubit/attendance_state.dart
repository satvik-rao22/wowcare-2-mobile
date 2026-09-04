part of 'attendance_cubit.dart';

/// The four things a day can be. `ready` with an empty list is the fifth and
/// sixth, because "nobody on the roll" and "nobody called Kowalski" are the
/// same fetch with different answers.
enum AttendanceLoadStatus {
  loading,
  ready,

  /// The fetch threw with nothing to fall back on. A Try again key.
  failed,

  /// No signal: this is what the phone had saved, and it is read only.
  offline,
}

@immutable
class AttendanceState extends Equatable {
  const AttendanceState({
    required this.persona,
    required this.today,
    required this.day,
    this.scopeClassroom,
    this.status = AttendanceLoadStatus.loading,
    this.snapshot = const AttendanceSnapshot(),
    this.audience = AttendanceAudience.students,
    this.filter = AttendanceFilter.all,
    this.classrooms = const <String>{},
    this.query = '',
    this.isSearching = false,
    this.expandedId,
    this.isSelectMode = false,
    this.selectedIds = const <String>{},
    this.asOfLabel,
    this.isWorking = false,
  });

  final Persona persona;

  /// The school's own day, so "Today" means the school's today rather than
  /// the device's.
  final DateTime today;

  /// The day on screen.
  final DateTime day;

  /// The classroom a staff member is rostered to. Null for an admin, who
  /// sees the school.
  final String? scopeClassroom;

  final AttendanceLoadStatus status;
  final AttendanceSnapshot snapshot;
  final AttendanceAudience audience;
  final AttendanceFilter filter;

  /// The classrooms the filter left standing. Empty means all of them, which
  /// is what 4e's "your classroom filter is hiding them" is about.
  final Set<String> classrooms;

  final String query;
  final bool isSearching;

  /// The one row showing its record. Null when every row is closed.
  final String? expandedId;

  final bool isSelectMode;
  final Set<String> selectedIds;

  /// "8:02 this morning", set only while [status] is offline.
  final String? asOfLabel;

  /// A write is in flight.
  final bool isWorking;

  bool get isLoading => status == AttendanceLoadStatus.loading;
  bool get isFailed => status == AttendanceLoadStatus.failed;
  bool get isOffline => status == AttendanceLoadStatus.offline;

  bool get isGuardian => persona == Persona.guardian;
  bool get isStaffLens => persona == Persona.staff;

  /// Only an admin gets both lists. A staff member sees their classroom, a
  /// guardian sees their own children.
  bool get showsAudienceSwitch => persona == Persona.admin;

  bool get isToday => AttendanceFormats.isSameDay(day, today);

  /// A past day opens read only, and so does a day that came off the phone
  /// rather than off the network.
  bool get isReadOnly => !isToday || isOffline;

  /// 4d: the classroom is legible and inert until the staff member has
  /// signed themselves in. This is
  /// `AttendancePermissionService.hasPermissionToManageStudentAttendance`
  /// written as state.
  bool get isLocked =>
      isStaffLens && !(snapshot.selfShift?.isSignedIn ?? false);

  /// Whether this screen may write attendance at all.
  bool get canWrite => !isGuardian && !isReadOnly && !isLocked;

  /// Editing a recorded time survives a past day, for an Admin.
  bool get canEditTimes => persona == Persona.admin && !isOffline;

  SelfShift? get selfShift => snapshot.selfShift;

  // --- The list -------------------------------------------------------------

  /// Everything still standing after the search box and the live chip, in
  /// the order the day returned.
  List<AttendanceRecord> get visibleRows {
    final term = query.trim().toLowerCase();
    return <AttendanceRecord>[
      for (final row in snapshot.rows)
        if (filter.matches(row.status) &&
            _inScope(row) &&
            (term.isEmpty || row.fullName.toLowerCase().contains(term)))
          row,
    ];
  }

  /// Staff are scoped by the classrooms they cover rather than by one they
  /// belong to, which is what their record actually says.
  bool _inScope(AttendanceRecord row) =>
      classrooms.isEmpty || classrooms.any(row.classroomName.contains);

  /// A group per classroom for students, one shift-wide group for staff.
  List<AttendanceGroup> get groups {
    final visible = visibleRows;

    if (!audience.isStudents || isGuardian) {
      if (visible.isEmpty) return const <AttendanceGroup>[];
      return <AttendanceGroup>[
        AttendanceGroup(
          title: AttendanceStrings.onShiftEyebrow,
          rows: visible,
          presentCount: snapshot.staffSignedIn,
          enrolled: snapshot.staffTotal,
          isStaffGroup: true,
        ),
      ];
    }

    return <AttendanceGroup>[
      for (final name in snapshot.classroomNames)
        if (visible.any((r) => r.classroomName == name))
          _classroomGroup(name, visible),
    ];
  }

  AttendanceGroup _classroomGroup(String name, List<AttendanceRecord> visible) {
    final present = snapshot.rows
        .where(
          (r) =>
              r.classroomName == name && r.status == AttendanceStatus.signedIn,
        )
        .length;
    final staff = snapshot.staffPresent[name] ?? 0;
    final ratio = snapshot.allowedRatio[name] ?? 0;
    final needed = ratio == 0
        ? 0
        : math.max(0, (present / ratio).ceil() - staff);

    return AttendanceGroup(
      title: name,
      rows: <AttendanceRecord>[
        for (final row in visible)
          if (row.classroomName == name) row,
      ],
      presentCount: present,
      enrolled: snapshot.enrolled[name] ?? 0,
      staffPresent: staff,
      staffNeeded: needed,
    );
  }

  /// How many of each status are on the day, for the chip run. Counted over
  /// the search results but not over the chips themselves, so the numbers do
  /// not move when a chip is picked.
  int countFor(AttendanceFilter chip) {
    final term = query.trim().toLowerCase();
    return snapshot.rows
        .where(
          (r) =>
              chip.matches(r.status) &&
              _inScope(r) &&
              (term.isEmpty || r.fullName.toLowerCase().contains(term)),
        )
        .length;
  }

  /// Nobody on the roll at all, which is a different sentence from a search
  /// that matched nothing.
  bool get isEmptyDay => snapshot.isEmpty;

  bool get isNarrowed =>
      query.trim().isNotEmpty ||
      filter != AttendanceFilter.all ||
      classrooms.isNotEmpty;

  bool get hasNoResults => !isEmptyDay && visibleRows.isEmpty;

  /// 4e's reassurance: the Absent chip is up and there is nobody under it.
  bool get isNobodyAbsent =>
      filter == AttendanceFilter.absent && visibleRows.isEmpty && !isEmptyDay;

  int get classroomCount =>
      classrooms.isEmpty ? snapshot.classroomNames.length : classrooms.length;

  /// The students the admin scope note counts.
  int get scopedStudentCount => snapshot.rows
      .where((r) => r.audience == AttendanceAudience.students)
      .length;

  /// The people the picked names would be signed in or out with.
  List<AttendanceRecord> get selectedRows => <AttendanceRecord>[
    for (final row in snapshot.rows)
      if (selectedIds.contains(row.id)) row,
  ];

  AttendanceRecord? recordFor(String id) {
    for (final row in snapshot.rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  AttendanceState copyWith({
    AttendanceLoadStatus? status,
    AttendanceSnapshot? snapshot,
    AttendanceAudience? audience,
    AttendanceFilter? filter,
    Set<String>? classrooms,
    DateTime? day,
    String? query,
    bool? isSearching,
    String? expandedId,
    bool? isSelectMode,
    Set<String>? selectedIds,
    String? asOfLabel,
    bool? isWorking,
    bool clearExpanded = false,
    bool clearAsOfLabel = false,
  }) => AttendanceState(
    persona: persona,
    today: today,
    day: day ?? this.day,
    scopeClassroom: scopeClassroom,
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    audience: audience ?? this.audience,
    filter: filter ?? this.filter,
    classrooms: classrooms ?? this.classrooms,
    query: query ?? this.query,
    isSearching: isSearching ?? this.isSearching,
    expandedId: clearExpanded ? null : expandedId ?? this.expandedId,
    isSelectMode: isSelectMode ?? this.isSelectMode,
    selectedIds: selectedIds ?? this.selectedIds,
    asOfLabel: clearAsOfLabel ? null : asOfLabel ?? this.asOfLabel,
    isWorking: isWorking ?? this.isWorking,
  );

  @override
  List<Object?> get props => <Object?>[
    persona,
    today,
    day,
    scopeClassroom,
    status,
    snapshot,
    audience,
    filter,
    classrooms,
    query,
    isSearching,
    expandedId,
    isSelectMode,
    selectedIds,
    asOfLabel,
    isWorking,
  ];
}
