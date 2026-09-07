import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';

/// In-memory [StorageService]. The cubit persists the selected child through
/// this, so the same instance shared across two cubits models a cold start.
class _FakeStorage implements StorageService {
  final Map<String, Object?> values = <String, Object?>{};

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> saveString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<void> saveBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<int?> getInt(String key) async => values[key] as int?;

  @override
  Future<void> saveInt(String key, int value) async {
    values[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      values[key] as Map<String, dynamic>?;

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    values[key] = value;
  }

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<Set<String>> getKeys() async => values.keys.toSet();
}

/// `StudentRemoteDataSource` declares ~100 members; `noSuchMethod` lets the
/// fake implement only the one the cubit calls.
class _FakeStudentRemote implements StudentRemoteDataSource {
  _FakeStudentRemote(this.children);

  /// `{code, firstName, lastName}` rows, exactly as the guardian-children API
  /// returns them.
  List<Map<String, dynamic>> children;

  int callCount = 0;

  @override
  Future<List<Map<String, dynamic>>> getGuardianChildren({
    required String guardianCode,
    required String schoolCode,
    required String userCode,
  }) async {
    callCount++;
    // A real network hop yields to the event loop; without this the "two
    // concurrent ensureLoaded calls share one load" test would not exercise
    // any interleaving.
    await Future<void>.delayed(Duration.zero);
    return children;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

class _UnusedStudentRepository implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// The student-page enrichment step. Returning an empty page is the same path
/// the production code takes when enrichment fails: the guardian-children rows
/// stay the source of truth.
class _EmptyStudentPageUseCase extends GetStudentPageUseCase {
  _EmptyStudentPageUseCase() : super(_UnusedStudentRepository());

  @override
  Future<StudentPage> call({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? attendanceStatuses,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? allowedClassroomCodes,
  }) async => const StudentPage(
    items: <Student>[],
    page: 0,
    size: 0,
    totalPages: 0,
    totalElements: 0,
    hasMore: false,
  );
}

const String _guardianRoles = '[{"role":"GUARDIAN"}]';
const String _staffRoles = '[{"role":"SCHOOL_ADMIN"}]';

Map<String, dynamic> _child(String code, String first, String last) =>
    <String, dynamic>{'code': code, 'firstName': first, 'lastName': last};

void main() {
  late _FakeStorage storage;
  late _FakeStudentRemote remote;

  /// Populates storage with a signed-in session. Keeping org/school/user
  /// configurable is what lets the session-isolation tests change scope.
  void signIn({
    String userCode = 'USR_1',
    String orgCode = 'ORG_1',
    String schoolCode = 'SCH_1',
    String roles = _guardianRoles,
  }) {
    storage.values[StorageKeys.userCode] = userCode;
    storage.values[StorageKeys.organizationCode] = orgCode;
    storage.values[StorageKeys.schoolCode] = schoolCode;
    storage.values[StorageKeys.roles] = roles;
    // Pre-set so the cubit never reaches the network-backed guardian-code
    // resolver.
    storage.values[StorageKeys.guardianCode] = 'GRD_1';
  }

  setUp(() async {
    storage = _FakeStorage();
    remote = _FakeStudentRemote(<Map<String, dynamic>>[
      _child('STD_A', 'Ava', 'Stone'),
      _child('STD_B', 'Ben', 'Stone'),
    ]);

    await serviceLocator.reset();
    serviceLocator.registerSingleton<StorageService>(storage);
    serviceLocator.registerSingleton<StudentRemoteDataSource>(remote);
    serviceLocator.registerSingleton<GetStudentPageUseCase>(
      _EmptyStudentPageUseCase(),
    );
    signIn();
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  group('loading', () {
    test(
      'loads both children and selects the first when nothing is stored',
      () async {
        final cubit = ParentChildCubit();
        await cubit.ensureLoaded();

        expect(cubit.children.map((c) => c.code), <String>['STD_A', 'STD_B']);
        expect(cubit.selectedChild?.code, 'STD_A');
        expect(cubit.isLoaded, isTrue);
        await cubit.close();
      },
    );

    test('a parent with one child selects that child', () async {
      remote.children = <Map<String, dynamic>>[_child('STD_A', 'Ava', 'Stone')];
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.children, hasLength(1));
      expect(cubit.selectedChild?.code, 'STD_A');
      await cubit.close();
    });

    test('a parent with no linked children has a null selection', () async {
      remote.children = <Map<String, dynamic>>[];
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.children, isEmpty);
      expect(cubit.selectedChild, isNull);
      expect(cubit.isLoaded, isTrue);
      await cubit.close();
    });

    test('concurrent ensureLoaded calls share one load', () async {
      final cubit = ParentChildCubit();

      await Future.wait(<Future<void>>[
        cubit.ensureLoaded(),
        cubit.ensureLoaded(),
        cubit.ensureLoaded(),
      ]);

      // The old `if (state.isLoading) return;` guard let callers 2 and 3
      // return a COMPLETED future mid-load, so they read an empty selection.
      expect(remote.callCount, 1);
      expect(cubit.selectedChild?.code, 'STD_A');
      await cubit.close();
    });
  });

  group('switching', () {
    test('selectByCode moves the selection to an owned child', () async {
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.selectByCode('STD_B'), isTrue);
      expect(cubit.selectedChild?.code, 'STD_B');
      await cubit.close();
    });

    test('a switch survives a forced reload of the same context', () async {
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();
      cubit.selectByCode('STD_B');

      await cubit.ensureLoaded(force: true);

      expect(cubit.selectedChild?.code, 'STD_B');
      await cubit.close();
    });

    test(
      'selectByCode rejects a student not linked to this guardian',
      () async {
        final cubit = ParentChildCubit();
        await cubit.ensureLoaded();

        expect(cubit.selectByCode('STD_SOMEONE_ELSE'), isFalse);
        expect(cubit.selectedChild?.code, 'STD_A');
        await cubit.close();
      },
    );

    test('selectByCode ignores an empty code', () async {
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.selectByCode('   '), isFalse);
      expect(cubit.selectedChild?.code, 'STD_A');
      await cubit.close();
    });

    test(
      'a selection requested BEFORE the list loads is applied afterwards',
      () async {
        // The notification/deep-link race: the tap resolves child B while the
        // guardian-children fetch is still in flight. This used to be dropped
        // silently, leaving the global selection on child A while the pushed
        // screen showed child B.
        final cubit = ParentChildCubit();

        expect(cubit.selectByCode('STD_B'), isFalse);
        await cubit.ensureLoaded();
        // The deferred apply lands on the microtask that follows the load.
        await Future<void>.delayed(Duration.zero);

        expect(cubit.selectedChild?.code, 'STD_B');
        await cubit.close();
      },
    );

    test(
      'a pre-load request for an unlinked student never becomes the selection',
      () async {
        final cubit = ParentChildCubit();

        cubit.selectByCode('STD_SOMEONE_ELSE');
        await cubit.ensureLoaded();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.selectedChild?.code, 'STD_A');
        await cubit.close();
      },
    );

    test('a dropped pending request does not leak into a later load', () async {
      final cubit = ParentChildCubit();
      cubit.selectByCode('STD_C');
      await cubit.ensureLoaded();
      await Future<void>.delayed(Duration.zero);

      // STD_C only becomes real in the NEXT school/context. It must not be
      // retro-applied there.
      remote.children = <Map<String, dynamic>>[
        _child('STD_C', 'Cara', 'Stone'),
        _child('STD_D', 'Dev', 'Stone'),
      ];
      signIn(schoolCode: 'SCH_2');
      await cubit.ensureLoaded();

      expect(cubit.selectedChild?.code, 'STD_C');
      // ...selected because it is now genuinely the FIRST child, not because
      // the stale request was replayed:
      expect(cubit.children.first.code, 'STD_C');
      await cubit.close();
    });
  });

  group('display labels', () {
    test('unique names are shown unchanged', () async {
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.displayLabels, <String>['Ava Stone', 'Ben Stone']);
      await cubit.close();
    });

    test('duplicate names are disambiguated and stay switchable', () async {
      // Two siblings recorded under the same name collapsed into one dropdown
      // entry that always resolved to the first of them.
      remote.children = <Map<String, dynamic>>[
        _child('STD_A', 'Sam', 'Stone'),
        _child('STD_B', 'Sam', 'Stone'),
      ];
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.displayLabels, <String>[
        'Sam Stone (STD_A)',
        'Sam Stone (STD_B)',
      ]);
      expect(cubit.selectByLabel('Sam Stone (STD_B)'), isTrue);
      expect(cubit.selectedChild?.code, 'STD_B');
      expect(cubit.labelForCode('STD_B'), 'Sam Stone (STD_B)');
      await cubit.close();
    });

    test('selectByLabel ignores a label that is not on the list', () async {
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.selectByLabel('Nobody'), isFalse);
      expect(cubit.selectedChild?.code, 'STD_A');
      await cubit.close();
    });
  });

  group('persistence across app restarts', () {
    test('a cold start restores the child the parent last selected', () async {
      final first = ParentChildCubit();
      await first.ensureLoaded();
      first.selectByCode('STD_B');
      await Future<void>.delayed(Duration.zero);
      await first.close();

      // New process, same storage.
      final second = ParentChildCubit();
      await second.ensureLoaded();

      expect(second.selectedChild?.code, 'STD_B');
      await second.close();
    });

    test(
      'a persisted child that is no longer linked falls back to the first',
      () async {
        storage.values[StorageKeys.selectedStudentCode] = 'STD_GONE';
        storage.values[StorageKeys.selectedStudentContext] =
            'usr_1|org_1|sch_1';

        final cubit = ParentChildCubit();
        await cubit.ensureLoaded();

        expect(cubit.selectedChild?.code, 'STD_A');
        await cubit.close();
      },
    );

    test(
      'a selection persisted for another session scope is not restored',
      () async {
        // Written by a DIFFERENT user/org/school.
        storage.values[StorageKeys.selectedStudentCode] = 'STD_B';
        storage.values[StorageKeys.selectedStudentContext] =
            'other_user|org_9|sch_9';

        final cubit = ParentChildCubit();
        await cubit.ensureLoaded();

        expect(cubit.selectedChild?.code, 'STD_A');
        await cubit.close();
      },
    );
  });

  group('session reset and persona isolation', () {
    test(
      'resetForLogout clears the selection and its persisted record',
      () async {
        final cubit = ParentChildCubit();
        await cubit.ensureLoaded();
        cubit.selectByCode('STD_B');
        await Future<void>.delayed(Duration.zero);
        expect(storage.values[StorageKeys.selectedStudentCode], 'STD_B');

        await cubit.resetForLogout();

        expect(cubit.selectedChild, isNull);
        expect(cubit.children, isEmpty);
        expect(cubit.isLoaded, isFalse);
        expect(
          storage.values.containsKey(StorageKeys.selectedStudentCode),
          isFalse,
        );
        expect(
          storage.values.containsKey(StorageKeys.selectedStudentContext),
          isFalse,
        );
        await cubit.close();
      },
    );

    test('a staff/admin persona holds no child selection', () async {
      signIn(roles: _staffRoles);
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.children, isEmpty);
      expect(cubit.selectedChild, isNull);
      expect(cubit.isLoaded, isTrue);
      expect(remote.callCount, 0);
      await cubit.close();
    });

    test(
      "a parent's selection does not survive into a staff session",
      () async {
        final cubit = ParentChildCubit();
        await cubit.ensureLoaded();
        cubit.selectByCode('STD_B');
        expect(cubit.selectedChild?.code, 'STD_B');

        // Same device, staff signs in.
        signIn(userCode: 'USR_STAFF', roles: _staffRoles);
        cubit.invalidate();
        await cubit.ensureLoaded(force: true);

        expect(cubit.selectedChild, isNull);
        expect(cubit.children, isEmpty);
        await cubit.close();
      },
    );

    test('a signed-out session has no children and no selection', () async {
      storage.values.remove(StorageKeys.userCode);
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.selectedChild, isNull);
      expect(cubit.isLoaded, isFalse);
      await cubit.close();
    });
  });

  group('ownership', () {
    test('isOwnedStudent answers for the loaded child list only', () async {
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.isOwnedStudent('STD_A'), isTrue);
      expect(cubit.isOwnedStudent('std_b'), isTrue, reason: 'case-insensitive');
      expect(cubit.isOwnedStudent('STD_OTHER'), isFalse);
      expect(cubit.isOwnedStudent(''), isFalse);
      expect(cubit.isOwnedStudent(null), isFalse);
      await cubit.close();
    });

    test('ownedStudentCodes is empty before the list loads', () {
      final cubit = ParentChildCubit();
      expect(cubit.ownedStudentCodes, isEmpty);
      expect(cubit.isOwnedStudent('STD_A'), isFalse);
      cubit.close();
    });
  });

  group('roles payload parsing', () {
    test('a malformed roles payload still detects a guardian', () async {
      storage.values[StorageKeys.roles] = 'GUARDIAN';
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.children, hasLength(2));
      await cubit.close();
    });

    test('an empty roles payload is treated as non-guardian', () async {
      storage.values[StorageKeys.roles] = jsonEncode(<dynamic>[]);
      final cubit = ParentChildCubit();
      await cubit.ensureLoaded();

      expect(cubit.children, isEmpty);
      expect(cubit.isLoaded, isTrue);
      await cubit.close();
    });
  });
}
