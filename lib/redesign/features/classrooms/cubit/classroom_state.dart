part of 'classroom_cubit.dart';

/// The four states 7j names for one classroom.
enum ClassroomStatus { loading, ready, cached, failed }

/// The three tabs (7c). A teacher gets the first and the last: who else is in
/// the classroom is on the classroom's record, and assigning staff is admin
/// work.
enum ClassroomTab { students, staff, notes }

@immutable
class ClassroomState extends Equatable {
  const ClassroomState({
    required this.classroomId,
    required this.persona,
    this.isOwnClassroom = false,
    this.status = ClassroomStatus.loading,
    this.detail,
    this.tab = ClassroomTab.students,
    this.query = '',
    this.studentFilters = const StudentFilters(),
    this.staffFilters = const StaffFilters(),
    this.isSelectMode = false,
    this.selectedIds = const <String>{},
    this.expandedId,
    this.isWorking = false,
    this.isClockedIn = false,
  });

  final String classroomId;
  final Persona persona;

  /// The signed-in teacher's own classroom, which is the only one they see.
  final bool isOwnClassroom;

  final ClassroomStatus status;
  final ClassroomDetail? detail;

  final ClassroomTab tab;
  final String query;
  final StudentFilters studentFilters;
  final StaffFilters staffFilters;

  final bool isSelectMode;
  final Set<String> selectedIds;

  /// Which roster row has its panel open. One at a time.
  final String? expandedId;

  final bool isWorking;

  /// The teacher is on the clock. Nothing is markable until this turns.
  final bool isClockedIn;

  bool get isLoading => status == ClassroomStatus.loading;
  bool get isFailed => status == ClassroomStatus.failed;
  bool get isCached => status == ClassroomStatus.cached;

  ClassroomSummary? get summary => detail?.summary;

  /// A teacher's own classroom draws 7e: no Staff tab, a clock card at the
  /// top, and the roster locked until they are on the clock.
  bool get isTeacherView => persona == Persona.staff && isOwnClassroom;

  /// Admins change classrooms. Everybody else looks (7i, 7j "View only").
  bool get canEdit => persona == Persona.admin;

  /// The roster is readable and nothing on it can be marked yet.
  bool get isLocked => isTeacherView && !isClockedIn;

  List<ClassroomTab> get tabs => isTeacherView
      ? const <ClassroomTab>[ClassroomTab.students, ClassroomTab.notes]
      : ClassroomTab.values;

  /// The roster, after the search box, the two toggles and the sheet.
  List<RosterStudent> get visibleStudents {
    final source = studentFilters.status == StudentStatusFilter.upcoming
        ? detail?.upcomingStudents
        : detail?.students;
    if (source == null) return const <RosterStudent>[];

    return source.where((student) {
      if (!student.matches(query)) return false;
      if (studentFilters.signedInOnly && !student.isSignedIn) return false;
      if (studentFilters.nappingOnly && !student.isNapping) return false;
      if (studentFilters.tags.isEmpty) return true;
      return student.careNeeds.any(
        (t) => studentFilters.tags.contains(t.label),
      );
    }).toList();
  }

  List<ClassroomStaffMember> get visibleStaff {
    final source = detail?.staff;
    if (source == null) return const <ClassroomStaffMember>[];

    return source.where((person) {
      if (!person.matches(query)) return false;
      if (staffFilters.designations.isNotEmpty &&
          !staffFilters.designations.contains(person.designation)) {
        return false;
      }
      if (staffFilters.dutyStates.isNotEmpty &&
          !staffFilters.dutyStates.contains(person.state)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get totalStudents => detail?.students.length ?? 0;
  int get totalStaff => detail?.staff.length ?? 0;

  bool get isSearching => query.trim().isNotEmpty;

  /// Nothing on the roll at all: 7j's "Nobody in this classroom yet". A
  /// search or a filter that matched nothing is a different state.
  bool get hasNoStudents => totalStudents == 0;

  bool get hasNoStudentMatches => totalStudents > 0 && visibleStudents.isEmpty;
  bool get hasNoStaffMatches => totalStaff > 0 && visibleStaff.isEmpty;

  bool get hasFilters => !studentFilters.isClear || !staffFilters.isClear;

  ClassroomState copyWith({
    ClassroomStatus? status,
    ClassroomDetail? detail,
    ClassroomTab? tab,
    String? query,
    StudentFilters? studentFilters,
    StaffFilters? staffFilters,
    bool? isSelectMode,
    Set<String>? selectedIds,
    String? expandedId,
    bool clearExpanded = false,
    bool? isWorking,
    bool? isClockedIn,
  }) => ClassroomState(
    classroomId: classroomId,
    persona: persona,
    isOwnClassroom: isOwnClassroom,
    status: status ?? this.status,
    detail: detail ?? this.detail,
    tab: tab ?? this.tab,
    query: query ?? this.query,
    studentFilters: studentFilters ?? this.studentFilters,
    staffFilters: staffFilters ?? this.staffFilters,
    isSelectMode: isSelectMode ?? this.isSelectMode,
    selectedIds: selectedIds ?? this.selectedIds,
    expandedId: clearExpanded ? null : (expandedId ?? this.expandedId),
    isWorking: isWorking ?? this.isWorking,
    isClockedIn: isClockedIn ?? this.isClockedIn,
  );

  @override
  List<Object?> get props => [
    classroomId,
    persona,
    isOwnClassroom,
    status,
    detail,
    tab,
    query,
    studentFilters,
    staffFilters,
    isSelectMode,
    selectedIds,
    expandedId,
    isWorking,
    isClockedIn,
  ];
}
