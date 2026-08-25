import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Minimal in-memory [StorageService] fake. Only the string operations this
/// resolver touches are backed by real state; anything else falls through to
/// [noSuchMethod], mirroring the Mockito `Mock` pattern.
class _FakeStorageService implements StorageService {
  final Map<String, String> _strings = {};

  @override
  Future<void> saveString(String key, String value) async {
    _strings[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> remove(String key) async {
    _strings.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

typedef _StaffCodeLookup =
    Future<String?> Function({
      required String userCode,
      required String organizationCode,
      required String schoolCode,
    });

/// Fake [StaffRepository] whose `getStaffCodeForUser` is scripted per test via
/// [lookup], and records every call in [calls] for assertions.
class _FakeStaffRepository implements StaffRepository {
  _FakeStaffRepository(this.lookup);

  final _StaffCodeLookup lookup;
  final List<Map<String, String>> calls = [];

  @override
  Future<String?> getStaffCodeForUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) {
    calls.add({
      'userCode': userCode,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
    });
    return lookup(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeStorageService storage;

  setUp(() {
    storage = _FakeStorageService();
    if (serviceLocator.isRegistered<StorageService>()) {
      serviceLocator.unregister<StorageService>();
    }
    serviceLocator.registerSingleton<StorageService>(storage);
  });

  tearDown(() {
    if (serviceLocator.isRegistered<StorageService>()) {
      serviceLocator.unregister<StorageService>();
    }
    if (serviceLocator.isRegistered<StaffRepository>()) {
      serviceLocator.unregister<StaffRepository>();
    }
  });

  void registerStaffRepo(_StaffCodeLookup lookup) {
    if (serviceLocator.isRegistered<StaffRepository>()) {
      serviceLocator.unregister<StaffRepository>();
    }
    serviceLocator.registerSingleton<StaffRepository>(
      _FakeStaffRepository(lookup),
    );
  }

  String staffRoleJson({required String org, required String school}) =>
      jsonEncode([
        {'role': 'STAFF', 'organizationCode': org, 'schoolCode': school},
      ]);

  String orgAdminRoleJson({required String org}) => jsonEncode([
    {'role': 'ORGANIZATION_ADMIN', 'organizationCode': org, 'schoolCode': ''},
  ]);

  group('single-school staff user', () {
    test('resolves fresh staffCode and caches candidateSchoolCode', () async {
      await storage.saveString(StorageKeys.userCode, 'USR-1');
      await storage.saveString(StorageKeys.organizationCode, 'ORG-1');
      await storage.saveString(StorageKeys.schoolCode, 'SCH-1');
      await storage.saveString(
        StorageKeys.roles,
        staffRoleJson(org: 'ORG-1', school: 'SCH-1'),
      );

      registerStaffRepo(({
        required userCode,
        required organizationCode,
        required schoolCode,
      }) async {
        expect(schoolCode, 'SCH-1');
        return 'STF-1';
      });

      final result = await resolveStaffCodeForLoggedInUser();

      expect(result, 'STF-1');
      expect(await storage.getString(StorageKeys.staffCode), 'STF-1');
      // Non-org-admin: candidateSchoolCode == the real schoolCode.
      expect(await storage.getString(StorageKeys.staffCodeSchool), 'SCH-1');
    });
  });

  group('organization admin', () {
    test('looks up with "-" and caches "-" as staffCodeSchool (regression for '
        'the schoolCode vs candidateSchoolCode bug)', () async {
      await storage.saveString(StorageKeys.userCode, 'USR-2');
      await storage.saveString(StorageKeys.organizationCode, 'ORG-2');
      await storage.saveString(StorageKeys.schoolCode, 'SCH-REAL');
      await storage.saveString(
        StorageKeys.roles,
        orgAdminRoleJson(org: 'ORG-2'),
      );

      registerStaffRepo(({
        required userCode,
        required organizationCode,
        required schoolCode,
      }) async {
        // Org admins are mapped org-level: the backend expects '-'.
        expect(schoolCode, '-');
        return 'STF-ADMIN';
      });

      final result = await resolveStaffCodeForLoggedInUser();

      expect(result, 'STF-ADMIN');
      // Regression guard: must store the school code ACTUALLY USED to
      // resolve ('-'), not the raw selected schoolCode ('SCH-REAL') — the
      // latter silently defeated the ownership check on subsequent reads.
      expect(await storage.getString(StorageKeys.staffCodeSchool), '-');
      expect(
        await storage.getString(StorageKeys.staffCodeSchool),
        isNot('SCH-REAL'),
      );
    });
  });

  group('multi-school switching', () {
    test(
      'stale cache from a previous school is not reused for the new school',
      () async {
        await storage.saveString(StorageKeys.userCode, 'USR-3');
        await storage.saveString(StorageKeys.organizationCode, 'ORG-3');
        await storage.saveString(
          StorageKeys.roles,
          staffRoleJson(org: 'ORG-3', school: 'SCH-NEW'),
        );

        // Cache from the PREVIOUS school selection.
        await storage.saveString(StorageKeys.staffCode, 'STF-OLD');
        await storage.saveString(StorageKeys.staffCodeUser, 'USR-3');
        await storage.saveString(StorageKeys.staffCodeOrganization, 'ORG-3');
        await storage.saveString(StorageKeys.staffCodeSchool, 'SCH-OLD');

        // App has since switched to a new school.
        await storage.saveString(StorageKeys.schoolCode, 'SCH-NEW');

        registerStaffRepo(({
          required userCode,
          required organizationCode,
          required schoolCode,
        }) async {
          expect(schoolCode, 'SCH-NEW');
          return 'STF-NEW';
        });

        final result = await resolveStaffCodeForLoggedInUser();

        expect(result, 'STF-NEW');
        expect(await storage.getString(StorageKeys.staffCode), 'STF-NEW');
        expect(await storage.getString(StorageKeys.staffCodeSchool), 'SCH-NEW');
      },
    );
  });

  group('invalid cache scenarios', () {
    test('matching cache is re-verified against the backend and corrected when '
        'the backend now returns a different staffCode', () async {
      await storage.saveString(StorageKeys.userCode, 'USR-4');
      await storage.saveString(StorageKeys.organizationCode, 'ORG-4');
      await storage.saveString(StorageKeys.schoolCode, 'SCH-4');
      await storage.saveString(
        StorageKeys.roles,
        staffRoleJson(org: 'ORG-4', school: 'SCH-4'),
      );

      await storage.saveString(StorageKeys.staffCode, 'STF-STALE');
      await storage.saveString(StorageKeys.staffCodeUser, 'USR-4');
      await storage.saveString(StorageKeys.staffCodeOrganization, 'ORG-4');
      await storage.saveString(StorageKeys.staffCodeSchool, 'SCH-4');

      registerStaffRepo(
        ({
          required userCode,
          required organizationCode,
          required schoolCode,
        }) async => 'STF-CORRECTED',
      );

      final result = await resolveStaffCodeForLoggedInUser();

      expect(result, 'STF-CORRECTED');
      expect(await storage.getString(StorageKeys.staffCode), 'STF-CORRECTED');
    });

    test(
      'clears cached staffCode when the backend rejects the cached mapping',
      () async {
        await storage.saveString(StorageKeys.userCode, 'USR-5');
        await storage.saveString(StorageKeys.organizationCode, 'ORG-5');
        await storage.saveString(StorageKeys.schoolCode, 'SCH-5');
        await storage.saveString(
          StorageKeys.roles,
          staffRoleJson(org: 'ORG-5', school: 'SCH-5'),
        );

        await storage.saveString(StorageKeys.staffCode, 'STF-STALE');
        await storage.saveString(StorageKeys.staffCodeUser, 'USR-5');
        await storage.saveString(StorageKeys.staffCodeOrganization, 'ORG-5');
        await storage.saveString(StorageKeys.staffCodeSchool, 'SCH-5');

        registerStaffRepo(({
          required userCode,
          required organizationCode,
          required schoolCode,
        }) async {
          throw Exception('403 staff code mismatch');
        });

        final result = await resolveStaffCodeForLoggedInUser();

        // Every candidate throws too, so resolution ultimately fails and the
        // stale cache must not linger.
        expect(result, '');
        expect(await storage.getString(StorageKeys.staffCode), isNull);
      },
    );

    test(
      'kiosk/guardian-only context skips resolution and clears cache',
      () async {
        await storage.saveString(StorageKeys.userCode, 'USR-6');
        await storage.saveString(StorageKeys.organizationCode, 'ORG-6');
        await storage.saveString(StorageKeys.schoolCode, 'SCH-6');
        await storage.saveString(
          StorageKeys.roles,
          jsonEncode([
            {
              'role': 'KIOSK',
              'organizationCode': 'ORG-6',
              'schoolCode': 'SCH-6',
            },
          ]),
        );

        await storage.saveString(StorageKeys.staffCode, 'STF-SHOULD-CLEAR');
        await storage.saveString(StorageKeys.staffCodeUser, 'USR-6');
        await storage.saveString(StorageKeys.staffCodeOrganization, 'ORG-6');
        await storage.saveString(StorageKeys.staffCodeSchool, 'SCH-6');

        registerStaffRepo(({
          required userCode,
          required organizationCode,
          required schoolCode,
        }) async {
          fail('Backend should not be called for a kiosk-only context');
        });

        final result = await resolveStaffCodeForLoggedInUser();

        expect(result, '');
        expect(await storage.getString(StorageKeys.staffCode), isNull);
      },
    );
  });
}
