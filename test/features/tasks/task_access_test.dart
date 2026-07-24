import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// RoleCubit bootstraps from the service locator on construction; a storage
/// that returns null keeps that bootstrap harmless in tests.
class _NullStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// RoleCubit double with a fixed persona — the role getters are overridden so
/// the async bootstrap's default state can't influence the assertions.
class _Roles extends RoleCubit {
  _Roles(this._role);
  final String _role;

  @override
  String get role => _role;
  @override
  bool get isParent => _role == 'parent';
  @override
  bool get isAdmin => _role == 'admin' || _role == 'staff';
  @override
  bool get isStaff => _role == 'staff';
}

Task _task({String assigneeCode = 'STF_OTHER', String createdBy = ''}) => Task(
      code: 'TSA_1',
      taskCode: 'TSK_1',
      title: 'T',
      assigneeCode: assigneeCode,
      createdBy: createdBy,
      startDate: DateTime(2026, 7, 15),
      dueDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  // RoleCubit resolves StorageService from the locator during construction,
  // so register a no-op before any _Roles is built.
  if (!GetIt.I.isRegistered<StorageService>()) {
    GetIt.I.registerSingleton<StorageService>(_NullStorage());
  }

  final admin = _Roles('admin');
  final staff = _Roles('staff');
  final parent = _Roles('parent');

  group('canManageTask', () {
    test('admin manages any task', () {
      expect(
        TaskAccess.canManageTask(
          roles: admin,
          task: _task(assigneeCode: 'STF_OTHER'),
          userCode: 'USR_ADMIN',
          staffCode: '',
        ),
        isTrue,
      );
    });

    test('parent can never manage', () {
      expect(
        TaskAccess.canManageTask(
          roles: parent,
          task: _task(assigneeCode: 'STF_ME'),
          userCode: 'USR_ME',
          staffCode: 'STF_ME',
        ),
        isFalse,
      );
    });

    test('staff manages a task assigned to them', () {
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _task(assigneeCode: 'STF_ME'),
          userCode: 'USR_ME',
          staffCode: 'STF_ME',
        ),
        isTrue,
      );
    });

    test('staff manages a task they created (once backend sends createdBy)', () {
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _task(assigneeCode: 'STF_OTHER', createdBy: 'STF_ME'),
          userCode: 'USR_ME',
          staffCode: 'STF_ME',
        ),
        isTrue,
      );
    });

    test('staff CANNOT manage a task that is not theirs', () {
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _task(assigneeCode: 'STF_OTHER'),
          userCode: 'USR_ME',
          staffCode: 'STF_ME',
        ),
        isFalse,
      );
    });

    test('staff with unresolved identity is denied (no blanket write)', () {
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _task(assigneeCode: 'STF_OTHER'),
          userCode: '',
          staffCode: '',
        ),
        isFalse,
      );
    });
  });

  group('canChangeStatus follows the same ownership rule', () {
    test('staff owner may, staff non-owner may not', () {
      expect(
        TaskAccess.canChangeStatus(
          roles: staff,
          task: _task(assigneeCode: 'STF_ME'),
          userCode: 'USR_ME',
          staffCode: 'STF_ME',
        ),
        isTrue,
      );
      expect(
        TaskAccess.canChangeStatus(
          roles: staff,
          task: _task(assigneeCode: 'STF_OTHER'),
          userCode: 'USR_ME',
          staffCode: 'STF_ME',
        ),
        isFalse,
      );
    });
  });

  group('module & create gates', () {
    test('parents are excluded from the module and creation', () {
      expect(TaskAccess.canAccessModule(parent), isFalse);
      expect(TaskAccess.canCreateTasks(parent), isFalse);
    });

    test('staff and admin can access and create', () {
      for (final roles in [admin, staff]) {
        expect(TaskAccess.canAccessModule(roles), isTrue);
        expect(TaskAccess.canCreateTasks(roles), isTrue);
      }
    });
  });

  group('isAdmin compares the raw role (staff is not admin here)', () {
    test('true only for the admin role', () {
      expect(TaskAccess.isAdmin(admin), isTrue);
      expect(TaskAccess.isAdmin(staff), isFalse);
      expect(TaskAccess.isAdmin(parent), isFalse);
    });
  });

  group('defaultShowMineOnly', () {
    test('staff default to "My Tasks"; admins default to "All Tasks"', () {
      expect(TaskAccess.defaultShowMineOnly(staff), isTrue);
      expect(TaskAccess.defaultShowMineOnly(admin), isFalse);
      expect(TaskAccess.defaultShowMineOnly(parent), isFalse);
    });
  });
}
