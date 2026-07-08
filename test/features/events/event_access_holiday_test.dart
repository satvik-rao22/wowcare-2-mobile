import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

import 'helpers/event_test_fakes.dart';

/// Holiday RBAC (PRD §5.3 / FR-HL-12): managing holidays — creating, editing
/// and deleting school holidays plus approving/rejecting federal ones — is
/// admin-only. Staff and parents get the list read-only.
///
/// The critical trap under test: [RoleCubit.isAdmin] also returns true for
/// staff, so [EventAccess] must gate on the raw role instead. A regression
/// there would silently hand staff full holiday management.
void main() {
  setUpAll(() {
    // RoleCubit's constructor bootstrap resolves StorageService from the
    // service locator; an empty fake keeps it inert (no token → no network).
    if (!serviceLocator.isRegistered<StorageService>()) {
      serviceLocator.registerLazySingleton<StorageService>(
        FakeStorageService.new,
      );
    }
  });

  Future<RoleCubit> roleCubitWith(String role) async {
    final cubit = RoleCubit();
    // Let the constructor's async bootstrap settle before overriding the
    // role, so its fallback emit cannot clobber the value set here.
    await Future<void>.delayed(Duration.zero);
    await cubit.setRole(role);
    return cubit;
  }

  test('admin can manage holidays', () async {
    final roles = await roleCubitWith('admin');
    addTearDown(roles.close);

    expect(EventAccess.isAdmin(roles), isTrue);
    expect(EventAccess.canManageHolidays(roles), isTrue);
  });

  test('staff cannot manage holidays even though RoleCubit.isAdmin '
      'includes staff', () async {
    final roles = await roleCubitWith('staff');
    addTearDown(roles.close);

    // Documents the trap: the generic admin check is true for staff...
    expect(roles.isAdmin, isTrue);
    // ...but the holiday rules must not be.
    expect(EventAccess.isAdmin(roles), isFalse);
    expect(EventAccess.canManageHolidays(roles), isFalse);
  });

  test('parent cannot manage holidays', () async {
    final roles = await roleCubitWith('parent');
    addTearDown(roles.close);

    expect(EventAccess.isAdmin(roles), isFalse);
    expect(EventAccess.canManageHolidays(roles), isFalse);
  });
}
