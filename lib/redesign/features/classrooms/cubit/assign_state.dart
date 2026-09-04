part of 'assign_cubit.dart';

enum AssignStatus { loading, ready, failed, submitting, done }

/// The two steps on the rail: pick, then review and submit.
enum AssignStep { pick, review }

@immutable
class AssignState extends Equatable {
  const AssignState({
    required this.classroomId,
    required this.kind,
    this.status = AssignStatus.loading,
    this.classroom,
    this.candidates = const <AssignCandidate>[],
    this.pickedIds = const <String>{},
    this.step = AssignStep.pick,
    this.query = '',
    this.group,
  });

  final String classroomId;
  final AssignKind kind;

  final AssignStatus status;

  /// The classroom being assigned into, for the review step's arithmetic.
  final ClassroomSummary? classroom;

  final List<AssignCandidate> candidates;
  final Set<String> pickedIds;

  final AssignStep step;
  final String query;

  /// The chip over step one: Unassigned, or another classroom.
  final String? group;

  bool get isLoading => status == AssignStatus.loading;
  bool get isFailed => status == AssignStatus.failed;
  bool get isSubmitting => status == AssignStatus.submitting;
  bool get isDone => status == AssignStatus.done;

  bool get isStudents => kind == AssignKind.students;
  bool get isReview => step == AssignStep.review;

  String get classroomName => classroom?.name ?? '';

  /// The groups the chips offer, in the order they were first seen, each with
  /// how many candidates it holds.
  Map<String, int> get groups {
    final counts = <String, int>{};
    for (final candidate in candidates) {
      counts[candidate.group] = (counts[candidate.group] ?? 0) + 1;
    }
    return counts;
  }

  List<AssignCandidate> get visible => candidates
      .where((c) => c.matches(query) && (group == null || c.group == group))
      .toList();

  List<AssignCandidate> get picked =>
      candidates.where((c) => pickedIds.contains(c.id)).toList();

  List<AssignCandidate> get pickedOutsideAgeRange =>
      picked.where((c) => c.isOutsideAgeRange).toList();

  bool get hasNoCandidates =>
      status != AssignStatus.loading && candidates.isEmpty;

  bool get hasNoMatches => candidates.isNotEmpty && visible.isEmpty;

  /// What the classroom's roll becomes if this is submitted.
  int get enrolledAfter => (classroom?.enrolled ?? 0) + pickedIds.length;

  /// What the classroom's staff count becomes if this is submitted.
  int get staffAfter => (classroom?.staffPresent ?? 0) + pickedIds.length;

  AssignState copyWith({
    AssignStatus? status,
    ClassroomSummary? classroom,
    List<AssignCandidate>? candidates,
    Set<String>? pickedIds,
    AssignStep? step,
    String? query,
    String? group,
    bool clearGroup = false,
  }) => AssignState(
    classroomId: classroomId,
    kind: kind,
    status: status ?? this.status,
    classroom: classroom ?? this.classroom,
    candidates: candidates ?? this.candidates,
    pickedIds: pickedIds ?? this.pickedIds,
    step: step ?? this.step,
    query: query ?? this.query,
    group: clearGroup ? null : (group ?? this.group),
  );

  @override
  List<Object?> get props => [
    classroomId,
    kind,
    status,
    classroom,
    candidates,
    pickedIds,
    step,
    query,
    group,
  ];
}
