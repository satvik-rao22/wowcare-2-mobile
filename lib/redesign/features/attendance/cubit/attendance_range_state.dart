part of 'attendance_range_cubit.dart';

/// What 4f can be. There is no offline state here: a range is a report, and
/// nothing about it is written, so a failed fetch is simply failed.
enum RangeStatus { loading, ready, failed }

@immutable
class AttendanceRangeState extends Equatable {
  const AttendanceRangeState({
    required this.range,
    this.status = RangeStatus.loading,
    this.audience = AttendanceAudience.students,
    this.classrooms = const <String>{},
    this.classroomOptions = const <String>[],
    this.query = '',
    this.isSearching = false,
    this.entries = const <RangeEntry>[],
    this.page = 0,
    this.totalElements = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.expandedId,
  });

  final DateRange range;
  final RangeStatus status;
  final AttendanceAudience audience;

  /// The classrooms the multi-select left standing. Empty means all of them.
  final Set<String> classrooms;
  final List<String> classroomOptions;

  final String query;
  final bool isSearching;

  final List<RangeEntry> entries;
  final int page;
  final int totalElements;
  final bool hasMore;
  final bool isLoadingMore;

  /// The one row showing its two totals.
  final String? expandedId;

  bool get isLoading => status == RangeStatus.loading;
  bool get isFailed => status == RangeStatus.failed;
  bool get isEmpty => status == RangeStatus.ready && entries.isEmpty;

  bool get isNarrowed => classrooms.isNotEmpty || query.trim().isNotEmpty;

  AttendanceRangeState copyWith({
    DateRange? range,
    RangeStatus? status,
    AttendanceAudience? audience,
    Set<String>? classrooms,
    List<String>? classroomOptions,
    String? query,
    bool? isSearching,
    List<RangeEntry>? entries,
    int? page,
    int? totalElements,
    bool? hasMore,
    bool? isLoadingMore,
    String? expandedId,
    bool clearExpanded = false,
  }) => AttendanceRangeState(
    range: range ?? this.range,
    status: status ?? this.status,
    audience: audience ?? this.audience,
    classrooms: classrooms ?? this.classrooms,
    classroomOptions: classroomOptions ?? this.classroomOptions,
    query: query ?? this.query,
    isSearching: isSearching ?? this.isSearching,
    entries: entries ?? this.entries,
    page: page ?? this.page,
    totalElements: totalElements ?? this.totalElements,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    expandedId: clearExpanded ? null : expandedId ?? this.expandedId,
  );

  @override
  List<Object?> get props => <Object?>[
    range,
    status,
    audience,
    classrooms,
    classroomOptions,
    query,
    isSearching,
    entries,
    page,
    totalElements,
    hasMore,
    isLoadingMore,
    expandedId,
  ];
}
