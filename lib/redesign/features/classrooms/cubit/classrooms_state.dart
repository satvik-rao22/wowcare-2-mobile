part of 'classrooms_cubit.dart';

/// The four states 7j names for the list: still fetching, live, showing what
/// was last reached, or nothing at all.
enum ClassroomsStatus { loading, ready, cached, failed }

@immutable
class ClassroomsState extends Equatable {
  const ClassroomsState({
    this.status = ClassroomsStatus.loading,
    this.board = const ClassroomBoard(),
    this.query = '',
    this.segment = ClassroomSegment.all,
  });

  final ClassroomsStatus status;
  final ClassroomBoard board;
  final String query;
  final ClassroomSegment segment;

  bool get isLoading => status == ClassroomsStatus.loading;
  bool get isFailed => status == ClassroomsStatus.failed;

  /// The floor is what was last reached rather than what is there now.
  bool get isCached => status == ClassroomsStatus.cached;

  /// No classrooms at all: 7b, which is a different screen from a filter
  /// that matched nothing.
  bool get hasNoClassrooms =>
      status != ClassroomsStatus.loading && board.isEmpty;

  /// The classrooms the chips and the search box leave, attention first: a
  /// classroom that is short of staff outranks one that is fine.
  List<ClassroomSummary> get visible {
    final q = query.trim().toLowerCase();
    final matched = board.classrooms.where((classroom) {
      final passesSegment = switch (segment) {
        ClassroomSegment.all => true,
        ClassroomSegment.overRatio => !classroom.isInRatio,
        ClassroomSegment.empty => classroom.isEmpty,
      };
      if (!passesSegment) return false;
      return q.isEmpty || classroom.name.toLowerCase().contains(q);
    }).toList();

    matched.sort((a, b) {
      final byAttention = (a.isInRatio ? 1 : 0) - (b.isInRatio ? 1 : 0);
      return byAttention != 0 ? byAttention : a.name.compareTo(b.name);
    });
    return matched;
  }

  /// The floor has classrooms, and this chip or this search left none of
  /// them: the dashed "Every classroom is covered" panel.
  bool get hasNoMatches => !board.isEmpty && visible.isEmpty;

  bool get isSearching => query.trim().isNotEmpty;

  ClassroomsState copyWith({
    ClassroomsStatus? status,
    ClassroomBoard? board,
    String? query,
    ClassroomSegment? segment,
  }) => ClassroomsState(
    status: status ?? this.status,
    board: board ?? this.board,
    query: query ?? this.query,
    segment: segment ?? this.segment,
  );

  @override
  List<Object?> get props => [status, board, query, segment];
}
