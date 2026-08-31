import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
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

/// Bloc replacement for the old `ParentChildCubit` (a `ChangeNotifier`).
///
/// Behaviour is preserved exactly; only the state-propagation mechanism changed
/// from `notifyListeners()` to `_safeEmit()`. The previous public getters/methods
/// are kept (getters delegate to [state]) so consumers can switch from
/// `context.watch/read<ParentChildCubit>()` to the cubit with minimal churn.
class ParentChildCubit extends Cubit<ParentChildState> {
  ParentChildCubit() : super(const ParentChildState());

  /// Last session we successfully loaded for (user|org|school). Drives reload
  /// on context change.
  String _lastLoadedContextKey = '';

  ParentChildRef? get selectedChild => state.selectedChild;
  List<ParentChildRef> get children => state.children;
  bool get isLoading => state.isLoading;
  bool get isLoaded => state.isLoaded;

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
  /// (e.g. logout, manual refresh).
  void invalidate() {
    _lastLoadedContextKey = '';
    _safeEmit(const ParentChildState());
  }

  /// Reactively triggers a refresh for all listeners of the parent children state.
  void forceRefresh() {
    _safeEmit(state.copyWith(refreshNonce: state.refreshNonce + 1));
  }

  Future<void> ensureLoaded({bool force = false}) async {
    if (state.isLoading) return;

    final storage = serviceLocator<StorageService>();
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();

    if (userCode.isEmpty) {
      _lastLoadedContextKey = '';
      _safeEmit(const ParentChildState());
      return;
    }

    // Parent/guardian child scope is not applicable for staff/admin personas.
    final bool hasGuardianPersona = _hasGuardianPersona(rolesRaw);
    if (!hasGuardianPersona) {
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
        final selectedCode = state.selectedChild?.code.trim();
        ParentChildRef? matching;
        if (selectedCode != null && selectedCode.isNotEmpty) {
          for (final child in loadedChildren) {
            if (child.code.trim() == selectedCode) {
              matching = child;
              break;
            }
          }
        }
        resultSelected = matching ?? loadedChildren.first;
      }
      resultLoaded = true;
      resultContextKey = contextKey;
    } catch (_) {
      resultChildren = const <ParentChildRef>[];
      resultSelected = null;
      resultLoaded = true;
      resultContextKey = '';
    } finally {
      _lastLoadedContextKey = resultContextKey;
      _safeEmit(
        ParentChildState(
          selectedChild: resultSelected,
          children: resultChildren,
          isLoading: false,
          isLoaded: resultLoaded,
        ),
      );
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

  void selectByName(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return;
    ParentChildRef? next;
    for (final child in state.children) {
      if (child.name == trimmed) {
        next = child;
        break;
      }
    }
    if (next == null) return;
    if (state.selectedChild?.code == next.code) return;
    _safeEmit(state.copyWith(selectedChild: next));
  }

  /// Selects the child matching [code] (e.g. after parent sign-in/out for a
  /// specific student).
  void selectByCode(String? code) {
    final trimmed = (code ?? '').trim();
    if (trimmed.isEmpty) return;
    ParentChildRef? next;
    for (final child in state.children) {
      if (child.code.trim() == trimmed) {
        next = child;
        break;
      }
    }
    if (next == null) return;
    if (state.selectedChild?.code == next.code) return;
    _safeEmit(state.copyWith(selectedChild: next));
  }
}
