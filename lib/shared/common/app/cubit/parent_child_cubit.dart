import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';

class ParentChildRef {
  const ParentChildRef({
    required this.code,
    required this.name,
    required this.classroom,
    this.classroomCode = '',
    this.status = 'Active',
    this.tags = const <String>[],
    this.schedule = const <String>[],
    Map<String, String>? scheduleByDay,
    this.primaryClassroomName,
  }) : _scheduleByDay = scheduleByDay;

  final String code;
  final String name;
  final String classroom;

  /// The classroom's actual CODE — see [Student.classroomCode]. Empty until
  /// enriched from the student-page fetch below (the raw guardian-children
  /// API response this class is first built from doesn't carry it).
  final String classroomCode;
  final String status;
  final List<String> tags;
  final List<String> schedule;
  final Map<String, String>? _scheduleByDay;
  final String? primaryClassroomName;

  Map<String, String> get scheduleByDay =>
      _scheduleByDay ?? const <String, String>{};

  factory ParentChildRef.fromStudent(Student student) {
    return ParentChildRef(
      code: student.code,
      name: student.fullName.trim().isNotEmpty
          ? student.fullName.trim()
          : student.code,
      classroom: student.classroom,
      classroomCode: student.classroomCode,
      status: student.status.trim().isNotEmpty
          ? student.status.trim()
          : 'Active',
      tags: student.tags,
      schedule: student.schedule,
      scheduleByDay: student.scheduleByDay,
      primaryClassroomName: student.primaryClassroomName,
    );
  }
}

class ParentChildState extends Equatable {
  const ParentChildState({
    this.selectedChild,
    this.children = const <ParentChildRef>[],
    this.isLoading = false,
    this.isLoaded = false,
    this.refreshNonce = 0,
  });

  final ParentChildRef? selectedChild;
  final List<ParentChildRef> children;
  final bool isLoading;
  final bool isLoaded;
  final int refreshNonce;

  ParentChildState copyWith({
    ParentChildRef? selectedChild,
    bool clearSelectedChild = false,
    List<ParentChildRef>? children,
    bool? isLoading,
    bool? isLoaded,
    int? refreshNonce,
  }) {
    return ParentChildState(
      selectedChild: clearSelectedChild
          ? null
          : (selectedChild ?? this.selectedChild),
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      refreshNonce: refreshNonce ?? this.refreshNonce,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedChild?.code,
    children.map((c) => c.code).toList(),
    isLoading,
    isLoaded,
    refreshNonce,
  ];
}

/// The app's **single source of truth** for which of a guardian's children is
/// currently selected, and for the set of children that guardian is allowed to
/// see at all.
///
/// Everything student-scoped on the parent side reads from here — the app-bar
/// switcher, the dashboard coordinator, the activity feed, the newsletter list,
/// the student/attendance profiles, the parent messaging thread, and (via
/// [isOwnedStudent]) the router's guardian scope guard. No screen keeps its own
/// copy of "the selected child"; screens that need to react cache the *code*
/// and re-fetch when this cubit emits a different one.
///
/// ## Selection contract
///
/// Selection is **deterministic** and resolved in exactly one place
/// ([_resolveSelection]), with this precedence:
///
///   1. an explicit pending request ([selectByCode] made before the list was
///      ready — e.g. a notification deep-link about child B),
///   2. the child already selected in memory (a switch survives a refresh),
///   3. the child persisted for THIS session scope (survives a cold start),
///   4. the first child in the list.
///
/// Every step is filtered through the loaded child list, so a code that is not
/// linked to the authenticated guardian can never become the selection — from a
/// deep link, a notification payload, a QR scan or a stale persisted value.
///
/// ## Session isolation
///
/// The persisted selection is stamped with a `userCode|orgCode|schoolCode`
/// scope key ([StorageKeys.selectedStudentContext]) and only restored when that
/// key matches the session being loaded, so it cannot leak across users,
/// organisations, schools or personas. [resetForLogout] erases it outright.
/// Staff/admin personas short-circuit to an empty, loaded state and never hold
/// a selection at all.
class ParentChildCubit extends Cubit<ParentChildState> {
  ParentChildCubit() : super(const ParentChildState());

  /// Last session we successfully loaded for (user|org|school). Drives reload
  /// on context change.
  String _lastLoadedContextKey = '';

  /// A selection requested before the child list could satisfy it — see
  /// [selectByCode]. Applied by [_resolveSelection] the moment the list
  /// resolves, and only if the code turns out to be one of this guardian's
  /// children. Cleared on every completed load, so it can never carry over
  /// into a different school's or user's list.
  String? _pendingSelectionCode;

  /// The in-flight [ensureLoaded], shared by concurrent callers.
  ///
  /// The previous `if (state.isLoading) return;` guard made a second caller
  /// return an ALREADY-COMPLETED future while the first load was still running,
  /// so `await ensureLoaded(); final child = selectedChild;` could read null /
  /// the previous school's child. Every caller now awaits the same load.
  Future<void>? _inFlight;

  ParentChildRef? get selectedChild => state.selectedChild;
  List<ParentChildRef> get children => state.children;
  bool get isLoading => state.isLoading;
  bool get isLoaded => state.isLoaded;

  /// Uppercased codes of every child linked to the authenticated guardian.
  /// The authorization set the router's guardian scope guard checks against.
  Set<String> get ownedStudentCodes => <String>{
    for (final child in state.children)
      if (child.code.trim().isNotEmpty) child.code.trim().toUpperCase(),
  };

  /// Whether [code] belongs to the authenticated guardian.
  ///
  /// **Not an authorization decision on its own** — it is a UI-side guard that
  /// complements the backend's own checks, and it answers `false` for a
  /// guardian whose list has not loaded yet. Callers that must fail safe
  /// should gate on [isLoaded] first (the router guard does).
  bool isOwnedStudent(String? code) {
    final trimmed = (code ?? '').trim();
    if (trimmed.isEmpty) return false;
    return ownedStudentCodes.contains(trimmed.toUpperCase());
  }

  /// Labels for the app-bar switcher, **guaranteed unique and index-aligned
  /// with [children]**.
  ///
  /// The switcher is a label-based dropdown, so two siblings whose names
  /// resolve identically (same first+last on file, or both falling back to
  /// their code) used to collapse into one entry that always resolved to the
  /// first of them — a multi-child parent simply could not switch to the
  /// second. Colliding names are disambiguated with their code; unique names
  /// are left exactly as they were.
  List<String> get displayLabels {
    final counts = <String, int>{};
    for (final child in state.children) {
      final name = child.name.trim();
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return <String>[
      for (final child in state.children)
        (counts[child.name.trim()] ?? 0) > 1
            ? '${child.name.trim()} (${child.code.trim()})'
            : child.name.trim(),
    ];
  }

  /// The [displayLabels] entry for [code], or null when it is not one of this
  /// guardian's children. Used to drive the switcher's current value.
  String? labelForCode(String? code) {
    final trimmed = (code ?? '').trim();
    if (trimmed.isEmpty) return null;
    final labels = displayLabels;
    for (var i = 0; i < state.children.length; i++) {
      if (state.children[i].code.trim() == trimmed) return labels[i];
    }
    return null;
  }

  List<String> get childNames =>
      state.children.map((e) => e.name).toList(growable: false);

  /// Emits only while open — so an emit after `close()` (e.g. an in-flight
  /// [ensureLoaded] resolving after teardown) never throws "emit after close".
  void _safeEmit(ParentChildState state) {
    if (!isClosed) emit(state);
  }

  static String _contextKey(
    String userCode,
    String orgCode,
    String schoolCode,
  ) =>
      '${userCode.toLowerCase()}|${orgCode.toLowerCase()}|${schoolCode.toLowerCase()}';

  /// Clears cached children so the next [ensureLoaded] runs a full fetch
  /// (e.g. manual refresh, school switch, re-login as the same user).
  ///
  /// Deliberately leaves the PERSISTED selection alone: a refresh or a
  /// re-login must land the parent back on the child they were looking at.
  /// Use [resetForLogout] to erase it.
  void invalidate() {
    _lastLoadedContextKey = '';
    _pendingSelectionCode = null;
    _safeEmit(const ParentChildState());
  }

  /// [invalidate] plus erasure of the persisted selection.
  ///
  /// Call this on logout / session expiry, so the next account to sign in on
  /// this device starts from its own child list with nothing inherited. The
  /// scope key on the persisted record already prevents another user from
  /// *restoring* this one, but a logout should not leave a child's code on
  /// disk at all.
  Future<void> resetForLogout() async {
    invalidate();
    await _clearPersistedSelection();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> _persistSelection(String? code) async {
    final contextKey = _lastLoadedContextKey;
    final trimmed = (code ?? '').trim();
    if (contextKey.isEmpty || trimmed.isEmpty) return;
    try {
      final storage = serviceLocator<StorageService>();
      await storage.saveString(StorageKeys.selectedStudentCode, trimmed);
      await storage.saveString(StorageKeys.selectedStudentContext, contextKey);
    } catch (_) {
      // Persistence is a convenience, never a correctness requirement: the
      // in-memory selection stays authoritative for this session.
    }
  }

  Future<void> _clearPersistedSelection() async {
    try {
      final storage = serviceLocator<StorageService>();
      await storage.remove(StorageKeys.selectedStudentCode);
      await storage.remove(StorageKeys.selectedStudentContext);
    } catch (_) {}
  }

  /// The child code persisted for [contextKey], or null when nothing was
  /// stored for THIS user/org/school scope.
  Future<String?> _readPersistedSelection(String contextKey) async {
    try {
      final storage = serviceLocator<StorageService>();
      final storedContext =
          (await storage.getString(StorageKeys.selectedStudentContext) ?? '')
              .trim();
      if (storedContext != contextKey) return null;
      final code =
          (await storage.getString(StorageKeys.selectedStudentCode) ?? '')
              .trim();
      return code.isEmpty ? null : code;
    } catch (_) {
      return null;
    }
  }

  // ── Selection resolution ─────────────────────────────────────────────────

  static ParentChildRef? _findByCode(
    List<ParentChildRef> children,
    String? code,
  ) {
    final trimmed = (code ?? '').trim();
    if (trimmed.isEmpty) return null;
    for (final child in children) {
      if (child.code.trim() == trimmed) return child;
    }
    return null;
  }

  /// The one place a selection is decided. See the class doc for the
  /// precedence and why each step is filtered through [children].
  ///
  /// [children] is never empty here — the caller handles that case by
  /// clearing the selection.
  ParentChildRef _resolveSelection(
    List<ParentChildRef> children,
    String? persistedCode,
  ) {
    final requested = _pendingSelectionCode;
    if (requested != null) {
      final match = _findByCode(children, requested);
      if (match != null) return match;
      AppLogger.w(
        '[ParentChild] Pending selection "$requested" is not linked to this '
        'guardian in the loaded context — falling back.',
      );
    }
    return _findByCode(children, state.selectedChild?.code) ??
        _findByCode(children, persistedCode) ??
        children.first;
  }

  /// Reactively triggers a refresh for all listeners of the parent children state.
  void forceRefresh() {
    _safeEmit(state.copyWith(refreshNonce: state.refreshNonce + 1));
  }

  /// Loads (or reloads) this guardian's children and resolves the selection.
  ///
  /// Concurrent callers share one load — see [_inFlight] for the stale-read
  /// bug the previous `isLoading` early-return caused.
  Future<void> ensureLoaded({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _load(force: force);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  Future<void> _load({required bool force}) async {
    final storage = serviceLocator<StorageService>();
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();

    if (userCode.isEmpty) {
      _pendingSelectionCode = null;
      _lastLoadedContextKey = '';
      _safeEmit(const ParentChildState());
      return;
    }

    // Parent/guardian child scope is not applicable for staff/admin personas.
    // Emitting an empty LOADED state (rather than leaving the previous
    // persona's) is what keeps a parent's child selection from surviving into
    // a staff/admin session on the same device.
    final bool hasGuardianPersona = _hasGuardianPersona(rolesRaw);
    if (!hasGuardianPersona) {
      _pendingSelectionCode = null;
      _lastLoadedContextKey = '';
      _safeEmit(const ParentChildState(isLoaded: true));
      return;
    }

    final contextKey = _contextKey(userCode, orgCode, schoolCode);
    final contextChanged = contextKey != _lastLoadedContextKey;

    if (hasGuardianPersona &&
        schoolCode.isNotEmpty &&
        orgCode.isNotEmpty &&
        userCode.isNotEmpty) {
      try {
        await refreshGuardianProfileSnapshotForLoggedInUser();
      } catch (_) {}
    }

    if (state.isLoaded && !force && !contextChanged) {
      return;
    }

    _safeEmit(state.copyWith(isLoading: true));

    // Local accumulators mirror the old mutable fields; emitted once at the end.
    List<ParentChildRef> resultChildren = state.children;
    ParentChildRef? resultSelected = state.selectedChild;
    bool resultLoaded = state.isLoaded;
    String resultContextKey = _lastLoadedContextKey;

    try {
      final remote = serviceLocator<StudentRemoteDataSource>();
      final studentPage = serviceLocator<GetStudentPageUseCase>();
      var guardianCode =
          (await storage.getString(StorageKeys.guardianCode) ?? '').trim();
      if (guardianCode.isEmpty) {
        guardianCode = (await resolveGuardianCodeForLoggedInUser()).trim();
      }

      if (guardianCode.isEmpty ||
          schoolCode.isEmpty ||
          orgCode.isEmpty ||
          userCode.isEmpty) {
        resultChildren = const <ParentChildRef>[];
        resultSelected = null;
        resultLoaded = true;
        resultContextKey = '';
        return;
      }

      final rawChildren = await remote.getGuardianChildren(
        guardianCode: guardianCode,
        schoolCode: schoolCode,
        userCode: userCode,
      );
      final byCode = <String, ParentChildRef>{};
      for (final row in rawChildren) {
        final code = (row['code'] ?? row['studentCode'] ?? '')
            .toString()
            .trim();
        if (code.isEmpty) continue;
        final firstName = (row['firstName'] ?? '').toString().trim();
        final lastName = (row['lastName'] ?? '').toString().trim();
        final fullName = '$firstName $lastName'.trim();
        byCode[code] = ParentChildRef(
          code: code,
          name: fullName.isNotEmpty ? fullName : code,
          classroom: '',
        );
      }

      if (byCode.isNotEmpty) {
        try {
          final page = await studentPage(
            schoolCode: schoolCode,
            guardianCodes: <String>[guardianCode],
            page: 0,
            size: 500,
          );

          for (final student in page.items) {
            final code = student.code.trim();
            if (!byCode.containsKey(code)) continue;
            byCode[code] = ParentChildRef.fromStudent(student);
          }
        } catch (_) {
          // Keep API children as source-of-truth even if enrichment fails.
        }
      }

      final loadedChildren = byCode.values.toList(growable: false);

      resultChildren = loadedChildren;
      if (loadedChildren.isEmpty) {
        resultSelected = null;
      } else {
        resultSelected = _resolveSelection(
          loadedChildren,
          await _readPersistedSelection(contextKey),
        );
      }
      resultLoaded = true;
      resultContextKey = contextKey;
    } catch (_) {
      resultChildren = const <ParentChildRef>[];
      resultSelected = null;
      resultLoaded = true;
      resultContextKey = '';
    } finally {
      // Consumed either way: a pending request that the loaded list could not
      // satisfy is not this guardian's child, and must not be carried into a
      // later load of a different school's or user's list.
      _pendingSelectionCode = null;
      _lastLoadedContextKey = resultContextKey;
      _safeEmit(
        ParentChildState(
          selectedChild: resultSelected,
          children: resultChildren,
          isLoading: false,
          isLoaded: resultLoaded,
        ),
      );
      unawaited(_persistSelection(resultSelected?.code));
    }
  }

  bool _hasGuardianPersona(String rolesRaw) {
    final raw = rolesRaw.trim();
    if (raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.any((r) {
          if (r is! Map) return false;
          final role = (r['role'] ?? '').toString();
          return roleStringIsGuardianPersona(role);
        });
      }
    } catch (_) {
      final u = raw.toUpperCase();
      return u.contains('GUARDIAN') || u.contains('PARENT');
    }
    return false;
  }

  /// Selects by the label the app-bar switcher renders — see [displayLabels]
  /// for why the switcher cannot select by bare name.
  bool selectByLabel(String? label) {
    final trimmed = (label ?? '').trim();
    if (trimmed.isEmpty) return false;
    final labels = displayLabels;
    final index = labels.indexOf(trimmed);
    if (index < 0) return false;
    return selectByCode(state.children[index].code);
  }

  /// Selects the child whose display name is [name].
  ///
  /// Retained for callers that only have a name. Prefer [selectByLabel] (the
  /// switcher) or [selectByCode] (everything else): a name is not a stable
  /// identity, and this resolves an ambiguous name to the first match.
  bool selectByName(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return false;
    for (final child in state.children) {
      if (child.name == trimmed) return selectByCode(child.code);
    }
    return false;
  }

  /// Selects the child matching [code] — the ONE way the selection changes.
  ///
  /// Returns whether [code] is now the selection. Three outcomes, all
  /// deliberate:
  ///
  ///   * **Owned and loaded** → selected and persisted; `true`.
  ///   * **Loaded but not owned** → *rejected*, logged, selection untouched;
  ///     `false`. A student code arriving from a notification payload, a QR
  ///     scan or a deep link is untrusted input, and must never move the
  ///     guardian's context onto a child that is not theirs.
  ///   * **Not loaded yet** → recorded as pending and applied the moment the
  ///     list resolves (still subject to the ownership check); `false` for
  ///     now. Silently dropping it — the previous behaviour — is what let a
  ///     notification about child B navigate to B's screen while the list
  ///     finished loading and defaulted the global selection to child A, so
  ///     the app bar and every other student-scoped screen disagreed with the
  ///     screen the user was looking at.
  bool selectByCode(String? code) {
    final trimmed = (code ?? '').trim();
    if (trimmed.isEmpty) return false;

    if (!state.isLoaded) {
      _pendingSelectionCode = trimmed;
      unawaited(ensureLoaded().then((_) => _applyRequestedSelection(trimmed)));
      return false;
    }

    final next = _findByCode(state.children, trimmed);
    if (next == null) {
      AppLogger.w(
        '[ParentChild] Rejected selection of "$trimmed" — not linked to the '
        'authenticated guardian (${state.children.length} child(ren) loaded).',
      );
      return false;
    }
    if (state.selectedChild?.code == next.code) return true;
    _safeEmit(state.copyWith(selectedChild: next));
    unawaited(_persistSelection(next.code));
    return true;
  }

  /// Re-applies a pending [selectByCode] once the list has loaded.
  ///
  /// [_resolveSelection] normally handles this inside the load itself; this
  /// covers the case where the request arrived while a load was ALREADY past
  /// its selection step, which would otherwise drop it on the `finally`.
  void _applyRequestedSelection(String code) {
    if (isClosed || !state.isLoaded) return;
    if (state.selectedChild?.code.trim() == code) return;
    final match = _findByCode(state.children, code);
    if (match == null) {
      AppLogger.w(
        '[ParentChild] Deferred selection of "$code" rejected — not linked to '
        'the authenticated guardian.',
      );
      return;
    }
    _safeEmit(state.copyWith(selectedChild: match));
    unawaited(_persistSelection(match.code));
  }
}
