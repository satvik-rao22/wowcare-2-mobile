import 'package:wowcare/domain/features/tasks/entities/task.dart';

/// Which value on a [Task] is treated as the creator's *identity* — i.e. what
/// "was this task created by me?" actually compares.
///
/// This exists because the events-todo assignment payload reports the creator
/// as a **display name** (`"createdBy": "Suhas Biwalkar"`), which is not an
/// identity: two staff members can share a name, and nothing on the payload
/// tells them apart. The comparison is therefore isolated behind one switch so
/// it can be moved onto a stable code the day the backend sends one, without
/// touching the read boundary, the RBAC rules or the scope tabs.
enum TaskCreatorIdentity {
  /// Compare display names ([Task.createdByLabel]) — what today's payload
  /// supports. Best-effort: correct for distinct names, ambiguous for
  /// duplicates. See [TaskCreatorMatcher.isAmbiguousAmong].
  displayName,

  /// Compare stable staff/user codes ([Task.createdByCode], falling back to
  /// [Task.createdBy] in case the backend repurposes that key rather than
  /// adding a new one). Exact, and the target state — flip
  /// [TaskCreatorMatcher.identity] here once the API sends a creator code.
  staffCode,
}

/// Decides whether a task was created by the signed-in user.
///
/// One rule, one place: the staff read boundary (`TasksState.visibleTasks`), the
/// "By Me" scope tab and `TaskAccess`'s manage/view checks all ask this object,
/// so they cannot drift apart or disagree about who created what.
///
/// Fails closed. When the signals this [identity] needs are missing (no display
/// name resolved yet, or no identity codes), [matches] returns false for every
/// task rather than defaulting to "mine" — a task list must never widen to
/// other people's work because identity resolution was still in flight.
class TaskCreatorMatcher {
  const TaskCreatorMatcher({
    this.identityCodes = const <String>{},
    this.displayName = '',
    this.identity = defaultIdentity,
  });

  /// **The swap point.** Change this one constant when the payload's creator
  /// field changes shape; every call site follows.
  static const TaskCreatorIdentity defaultIdentity =
      TaskCreatorIdentity.displayName;

  /// The signed-in user's stable codes (staff code and user code). Used by
  /// [TaskCreatorIdentity.staffCode].
  final Set<String> identityCodes;

  /// The signed-in user's display name. Used by
  /// [TaskCreatorIdentity.displayName].
  final String displayName;

  final TaskCreatorIdentity identity;

  /// Whether this matcher has what it needs to answer at all. False makes
  /// [matches] deny everything (see the class doc on failing closed).
  bool get isResolved {
    switch (identity) {
      case TaskCreatorIdentity.displayName:
        return normalizeName(displayName).isNotEmpty;
      case TaskCreatorIdentity.staffCode:
        return _codes.isNotEmpty;
    }
  }

  /// Whether [task] was created by the signed-in user.
  bool matches(Task task) {
    if (!isResolved) return false;
    switch (identity) {
      case TaskCreatorIdentity.displayName:
        final creator = normalizeName(task.createdByLabel);
        return creator.isNotEmpty && creator == normalizeName(displayName);
      case TaskCreatorIdentity.staffCode:
        // Both keys are checked so this mode works whether the backend adds a
        // `createdByCode` alongside the name or simply starts putting a code in
        // `createdBy`. A display name in either field matches no code, so the
        // wrong shape denies rather than mismatches.
        for (final candidate in <String>[task.createdByCode, task.createdBy]) {
          final trimmed = candidate.trim();
          if (trimmed.isNotEmpty && _codes.contains(trimmed)) return true;
        }
        return false;
    }
  }

  /// Whether name matching can't be trusted: two or more people in
  /// [directoryNames] share the signed-in user's name, so "created by me" would
  /// silently include a namesake's tasks.
  ///
  /// Feed this a **roster of people** (the active staff list) — not the creators
  /// seen on tasks. Task payloads carry only the name, so two staff called
  /// "Priya Nair" are the same string there and their tasks are already
  /// indistinguishable; the duplicate is only visible in a directory that keys
  /// people by code. Detecting it lets the UI warn or withhold the filter rather
  /// than report a wrong result confidently — it cannot *resolve* the ambiguity.
  /// Only the backend sending a creator code can do that.
  ///
  /// Always false under [TaskCreatorIdentity.staffCode], where identity is
  /// exact.
  bool isAmbiguousAmong(Iterable<String> directoryNames) {
    if (identity != TaskCreatorIdentity.displayName) return false;
    final me = normalizeName(displayName);
    if (me.isEmpty) return false;
    return directoryNames.where((name) => normalizeName(name) == me).length > 1;
  }

  Set<String> get _codes =>
      identityCodes.map((code) => code.trim()).where((c) => c.isNotEmpty).toSet();

  /// Canonical form for name comparison: trimmed, case-folded and with runs of
  /// whitespace collapsed, so `"  Suhas   Biwalkar "` matches
  /// `"suhas biwalkar"`. Deliberately does nothing cleverer — stripping
  /// punctuation or initials would start merging genuinely different people.
  static String normalizeName(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
