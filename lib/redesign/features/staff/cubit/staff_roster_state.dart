part of 'staff_roster_cubit.dart';

/// The five states the roster can be in. [denied] is 6e's "Staff is closed
/// for this school", [cached] is its offline banner over the last team that
/// was reached, and [failed] is its "Waiting for a signal".
enum StaffRosterStatus { loading, ready, cached, failed, denied }

@immutable
class StaffRosterState extends Equatable {
  const StaffRosterState({
    required this.lens,
    this.status = StaffRosterStatus.loading,
    this.roster = const StaffRoster(),
    this.query = '',
    this.filters = const StaffFilters(),
    this.expandedId,
    this.isSelectMode = false,
    this.selectedIds = const <String>{},
  });

  final StaffLens lens;
  final StaffRosterStatus status;
  final StaffRoster roster;
  final String query;
  final StaffFilters filters;

  /// The one row showing its facts. 6a opens one at a time.
  final String? expandedId;

  final bool isSelectMode;
  final Set<String> selectedIds;

  bool get isLoading => status == StaffRosterStatus.loading;
  bool get isFailed => status == StaffRosterStatus.failed;
  bool get isDenied => status == StaffRosterStatus.denied;

  /// The team on screen is what was last reached rather than what is there
  /// now, and the banner says when.
  bool get isCached => status == StaffRosterStatus.cached;

  /// A staff member gets 6e: their own record, and the colleagues they share
  /// a classroom with. No search, no filters, nothing to change.
  bool get isViewOnly => !lens.canWrite;

  bool get isSearching => query.trim().isNotEmpty;

  /// Nobody on the books at all, which is a different screen from a filter
  /// that matched nothing.
  bool get hasNoStaff => status != StaffRosterStatus.loading && roster.isEmpty;

  /// The viewer's own record, lifted out of the list for 6e's navy card.
  StaffMember? get ownRecord {
    for (final member in roster.members) {
      if (lens.isSelf(member.id)) return member;
    }
    return null;
  }

  /// The colleagues a staff member may see: everybody active who shares one
  /// of their classrooms, themselves excluded. Fails closed: with no
  /// classroom on the session, a staff member sees nobody but themselves.
  List<StaffMember> get team {
    final mine = roster.members
        .where(
          (member) =>
              member.isActive &&
              !lens.isSelf(member.id) &&
              member.sharesClassroomWith(lens.viewerClassroom),
        )
        .toList();
    mine.sort((a, b) => a.name.compareTo(b.name));
    return mine;
  }

  /// The rows the search box and the filter sheet leave, in the order 6b's
  /// "Order" group asks for.
  List<StaffMember> get visible {
    if (isViewOnly) return team;

    final needle = query.trim().toLowerCase();
    final matched = roster.members.where((member) {
      if (member.status != filters.status) return false;
      if (filters.designations.isNotEmpty &&
          !filters.designations.contains(member.designation)) {
        return false;
      }
      if (filters.primaryClassrooms.isNotEmpty &&
          !filters.primaryClassrooms.contains(
            member.hasClassroom ? member.primaryClassroom : _noClassroom,
          )) {
        return false;
      }
      if (filters.allowedIn.isNotEmpty &&
          !filters.allowedIn.any(member.classroomScope.contains)) {
        return false;
      }
      if (filters.attendance.isNotEmpty &&
          !filters.attendance.contains(member.attendance)) {
        return false;
      }
      if (needle.isEmpty) return true;
      return member.name.toLowerCase().contains(needle) ||
          member.designation.toLowerCase().contains(needle);
    }).toList();

    matched.sort(
      (a, b) => filters.order == StaffOrder.aToZ
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name),
    );
    return matched;
  }

  /// There are staff, and this search or these filters left none of them.
  bool get hasNoMatches => !roster.isEmpty && visible.isEmpty;

  /// The hires whose start date has not arrived, shown under the active list
  /// rather than mixed into it (6a's dashed row). Empty while the roster is
  /// already showing upcoming staff, so nobody is listed twice.
  List<StaffMember> get startingSoon {
    if (isViewOnly || filters.status != StaffStatus.active) {
      return const <StaffMember>[];
    }
    final soon = roster.members.where((member) => member.isUpcoming).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return soon;
  }

  /// The row of chips over the roster. Status and order always carry a value,
  /// so they read as statements and have no cross.
  List<StaffChip> get chips => <StaffChip>[
    StaffChip(
      label: StaffStrings.statusLabel(filters.status),
      group: StaffChipGroup.status,
    ),
    if (filters.designations.isEmpty)
      const StaffChip(
        label: StaffStrings.allDesignations,
        group: StaffChipGroup.designation,
      )
    else
      for (final designation in filters.designations)
        StaffChip(
          label: designation,
          group: StaffChipGroup.designation,
          value: designation,
        ),
    for (final classroom in filters.primaryClassrooms)
      StaffChip(
        label: classroom,
        group: StaffChipGroup.primaryClassroom,
        value: classroom,
      ),
    for (final classroom in filters.allowedIn)
      StaffChip(
        label: StaffStrings.allowedInChip(classroom),
        group: StaffChipGroup.allowedIn,
        value: classroom,
      ),
    for (final status in filters.attendance)
      StaffChip(
        label: StaffStrings.attendanceLabel(status),
        group: StaffChipGroup.attendance,
        value: status,
      ),
    StaffChip(
      label: StaffStrings.orderLabel(filters.order),
      group: StaffChipGroup.order,
    ),
  ];

  /// Every designation the sheet may offer: what the school holds, and what
  /// the filter is already set to even if nobody holds it any more.
  List<String> get designationOptions {
    final all = <String>{
      ...roster.designations,
      ...filters.designations,
    }.toList()..sort();
    return all;
  }

  /// The classroom options, with "No classroom" at the end because a Floater,
  /// a cook and a director are all legitimately without one.
  List<String> get classroomOptions => <String>[
    ...roster.classrooms,
    _noClassroom,
  ];

  int countOfDesignation(String designation) => roster.members
      .where(
        (member) =>
            member.status == filters.status &&
            member.designation == designation,
      )
      .length;

  int countOfAttendance(AttendanceStatus status) => roster.members
      .where(
        (member) =>
            member.status == filters.status && member.attendance == status,
      )
      .length;

  static const String _noClassroom = StaffStrings.noClassroom;

  StaffRosterState copyWith({
    StaffLens? lens,
    StaffRosterStatus? status,
    StaffRoster? roster,
    String? query,
    StaffFilters? filters,
    String? expandedId,
    bool? isSelectMode,
    Set<String>? selectedIds,
    bool clearExpanded = false,
  }) => StaffRosterState(
    lens: lens ?? this.lens,
    status: status ?? this.status,
    roster: roster ?? this.roster,
    query: query ?? this.query,
    filters: filters ?? this.filters,
    expandedId: clearExpanded ? null : expandedId ?? this.expandedId,
    isSelectMode: isSelectMode ?? this.isSelectMode,
    selectedIds: selectedIds ?? this.selectedIds,
  );

  @override
  List<Object?> get props => [
    lens,
    status,
    roster,
    query,
    filters,
    expandedId,
    isSelectMode,
    selectedIds,
  ];
}
