import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

/// Walks the PRD §5.2 "Tasks RBAC" matrix row by row, for every persona, so a
/// regression in any single cell fails a named test.
///
/// Persona mapping (PRD → app role): Org Admin, School Admin and CWW Super
/// Admin all resolve to `admin` (the app has no separate super-admin persona —
/// impersonation lands as the impersonated school's admin); Staff/Teacher →
/// `staff`; Guardian/Parent → `parent`.

class _NullStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

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

Task _task({
  String code = 'TSA_1',
  String assigneeCode = 'STF_OTHER',
  // The API reports the creator as a display name, not a code — so ownership by
  // authorship is matched against the signed-in user's name (see
  // TaskCreatorMatcher), while assignment stays a code match.
  String createdBy = _otherName,
}) =>
    Task(
      code: code,
      taskCode: 'TSK_1',
      title: 'T',
      assigneeCode: assigneeCode,
      createdBy: createdBy,
      startDate: DateTime.utc(2026, 7, 15),
      dueDate: DateTime.utc(2026, 7, 17),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

/// Display names of the signed-in staff member and of everyone else.
const String _myName = 'Me Myself';
const String _otherName = 'Other Person';

/// A board holding one task per ownership shape, as the API returns it (the
/// list endpoint is not persona-filtered, so the client is the boundary).
final _board = <Task>[
  _task(code: 'MINE', assigneeCode: 'STF_ME', createdBy: _otherName),
  _task(code: 'BY_ME', assigneeCode: 'STF_OTHER', createdBy: _myName),
  _task(code: 'OTHERS', assigneeCode: 'STF_OTHER', createdBy: _otherName),
];

TasksState _boardState({
  required TaskPersona persona,
  TaskScope scope = TaskScope.all,
  String staffCode = 'STF_ME',
}) =>
    TasksState(
      tasks: _board,
      isLoading: false,
      isSaving: false,
      scope: scope,
      searchQuery: '',
      assigneeFilter: const {},
      createdByFilter: const {},
      priorityFilter: const {},
      statusFilter: const {},
      overdueOnly: false,
      currentUserCode: 'USR_ME',
      currentUserName: _myName,
      currentStaffCode: staffCode,
      persona: persona,
    );

void main() {
  if (!GetIt.I.isRegistered<StorageService>()) {
    GetIt.I.registerSingleton<StorageService>(_NullStorage());
  }

  final admin = _Roles('admin');
  final staff = _Roles('staff');
  final parent = _Roles('parent');

  const me = 'STF_ME';
  const myUser = 'USR_ME';

  group('Row: View All Tasks', () {
    test('Org/School/CWW admin — Yes (all tasks, "All" by default)', () {
      expect(TaskAccess.canAccessModule(admin), isTrue);
      expect(TaskAccess.canViewAllTasks(admin), isTrue);
      expect(TaskAccess.defaultShowMineOnly(admin), isFalse);
      expect(
        _boardState(persona: TaskPersona.admin).filteredTasks.map((t) => t.code),
        containsAll(<String>['MINE', 'BY_ME', 'OTHERS']),
      );
    });

    test('Staff/Teacher — Yes, but only their own tasks ("My" by default)', () {
      expect(TaskAccess.canAccessModule(staff), isTrue);
      expect(TaskAccess.canViewAllTasks(staff), isFalse);
      expect(TaskAccess.defaultShowMineOnly(staff), isTrue);
      // Even with the scope forced to "all", a staff persona never sees a task
      // that is neither assigned to nor created by them.
      expect(
        _boardState(persona: TaskPersona.staff).filteredTasks.map((t) => t.code),
        <String>['MINE', 'BY_ME'],
      );
    });

    test('Guardian/Parent — No (module, navigation and data all hidden)', () {
      expect(TaskAccess.canAccessModule(parent), isFalse);
      expect(TaskAccess.canViewAllTasks(parent), isFalse);
      for (final task in _board) {
        expect(
          TaskAccess.canViewTask(
            roles: parent,
            task: task,
            userCode: myUser,
            staffCode: me,
          ),
          isFalse,
        );
      }
    });
  });

  group('Row: Create Task', () {
    test('admin — Yes; staff — Yes; parent — No', () {
      expect(TaskAccess.canCreateTasks(admin), isTrue);
      expect(TaskAccess.canCreateTasks(staff), isTrue);
      expect(TaskAccess.canCreateTasks(parent), isFalse);
    });
  });

  group('Rows: Edit Task / Delete Task', () {
    test('admin — Yes for any task', () {
      for (final task in _board) {
        expect(
          TaskAccess.canManageTask(
            roles: admin,
            task: task,
            userCode: 'USR_ADMIN',
          ),
          isTrue,
        );
      }
    });

    test('staff — own tasks only', () {
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _board[0],
          userCode: myUser,
          staffCode: me,
        ),
        isTrue,
      );
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _board[1],
          userCode: myUser,
          staffCode: me,
          // Authorship is matched by name, so this row needs it.
          userName: _myName,
        ),
        isTrue,
      );
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _board[2],
          userCode: myUser,
          staffCode: me,
        ),
        isFalse,
      );
    });

    test('parent — No, for every task', () {
      for (final task in _board) {
        expect(
          TaskAccess.canManageTask(
            roles: parent,
            task: task,
            userCode: myUser,
            staffCode: me,
          ),
          isFalse,
        );
      }
    });
  });

  group('Rows: Change Task Status / Priority (inline + drag)', () {
    test('admin — Yes for any task; staff — own only; parent — No', () {
      final others = _board[2];
      expect(
        TaskAccess.canChangeStatus(
          roles: admin,
          task: others,
          userCode: 'USR_ADMIN',
        ),
        isTrue,
      );
      expect(
        TaskAccess.canChangeStatus(
          roles: staff,
          task: others,
          userCode: myUser,
          staffCode: me,
        ),
        isFalse,
      );
      expect(
        TaskAccess.canChangeStatus(
          roles: staff,
          task: _board[0],
          userCode: myUser,
          staffCode: me,
        ),
        isTrue,
      );
      expect(
        TaskAccess.canChangeStatus(
          roles: parent,
          task: _board[0],
          userCode: myUser,
          staffCode: me,
        ),
        isFalse,
      );
    });
  });

  group('Row: View All / My toggle', () {
    test('admin toggles All ↔ My; both scopes stay unrestricted', () {
      expect(
        _boardState(persona: TaskPersona.admin, scope: TaskScope.all)
            .filteredTasks
            .map((t) => t.code),
        <String>['MINE', 'BY_ME', 'OTHERS'],
      );
      expect(
        _boardState(persona: TaskPersona.admin, scope: TaskScope.mine)
            .filteredTasks
            .map((t) => t.code),
        <String>['MINE'],
      );
    });

    test('staff toggles For-me ↔ By-me, never anyone else\'s tasks', () {
      expect(
        _boardState(persona: TaskPersona.staff, scope: TaskScope.mine)
            .filteredTasks
            .map((t) => t.code),
        <String>['MINE'],
      );
      expect(
        _boardState(persona: TaskPersona.staff, scope: TaskScope.byMe)
            .filteredTasks
            .map((t) => t.code),
        <String>['BY_ME'],
      );
    });

    test('staff with an unresolved identity sees nothing (fail closed)', () {
      final state = _boardState(persona: TaskPersona.staff, staffCode: '')
          .copyWith(currentUserCode: '');
      expect(state.filteredTasks, isEmpty);
      expect(state.visibleTasks, isEmpty);
    });
  });
}
