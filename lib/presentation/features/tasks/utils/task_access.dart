import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_creator_match.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

import '../../students/module_access.dart';

/// Access rules for the Tasks module (PRD §5.2 RBAC).
///
/// Two gates apply, in this order: the `TASK` module permission from
/// `/api/v1/users/details` (backend decides read vs write), then the persona
/// and ownership rules the API flags cannot express (staff manage only their
/// own tasks; parents have no Tasks at all).
///
/// Personas: admin (Org/School Admin + CWW Super Admin — full read/write),
/// staff (create tasks, manage their own, default "My Tasks") and parent
/// (NO access at all — must not see tasks, navigation, counts or actions).
///
/// Note: [RoleCubit.isAdmin] also returns true for staff, so the admin-only
/// checks here compare the raw role instead.
class TaskAccess {
  TaskAccess._();

  static bool isAdmin(RoleCubit roles) => roles.role == 'admin';

  /// The entire Tasks module is hidden from guardians/parents (PRD §5.2:
  /// "No" across every row; FR requirement that parents see no task UI).
  static bool canAccessModule(RoleCubit roles) =>
      !roles.isParent && roles.canOpenModule(AppAccessModules.task);

  /// Admin and staff can create tasks; parents never can (PRD FR-TK-01).
  static bool canCreateTasks(RoleCubit roles) =>
      !roles.isParent && roles.canWriteModule(AppAccessModules.task);

  /// Staff/Teacher default to "My Tasks"; admins default to "All Tasks"
  /// (PRD FR-TK-19).
  static bool defaultShowMineOnly(RoleCubit roles) => roles.isStaff;

  /// Whether the persona may see the whole school's tasks (PRD §5.2 "View All
  /// Tasks"): Org/School Admin and CWW Super Admin only. Staff/Teacher read is
  /// scoped to their own tasks, parents have no task read at all.
  static bool canViewAllTasks(RoleCubit roles) => isAdmin(roles);

  /// Read access to one task (PRD §5.2 "View All Tasks"). Admins see any task in
  /// the school; staff see only tasks assigned to or created by them; parents
  /// see none. Denies while the staff member's identity is still unresolved, so
  /// a deep link can never surface someone else's task.
  static bool canViewTask({
    required RoleCubit roles,
    required Task task,
    required String userCode,
    String staffCode = '',
    String userName = '',
  }) {
    if (roles.isParent) return false;
    if (!roles.canReadModule(AppAccessModules.task)) return false;
    if (isAdmin(roles)) return true;
    if (!roles.isStaff) return false;
    return _isMine(task, userCode, staffCode, userName);
  }

  /// Edit/delete a task: admins always; staff only for tasks that are theirs
  /// (PRD FR-TK-30 "assigned to themselves" reconciled with §5.2 "own
  /// created" — a staff member owns a task they created or are assigned to);
  /// parents never.
  static bool canManageTask({
    required RoleCubit roles,
    required Task task,
    required String userCode,
    String staffCode = '',
    String userName = '',
  }) {
    if (roles.isParent) return false;
    if (!roles.canWriteModule(AppAccessModules.task)) return false;
    if (isAdmin(roles)) return true;
    if (!roles.isStaff) return false;
    return _isMine(task, userCode, staffCode, userName);
  }

  /// Inline status/priority changes follow the same ownership rule as full
  /// edits (PRD §5.2 "Own tasks only" for staff).
  static bool canChangeStatus({
    required RoleCubit roles,
    required Task task,
    required String userCode,
    String staffCode = '',
    String userName = '',
  }) =>
      canManageTask(
        roles: roles,
        task: task,
        userCode: userCode,
        staffCode: staffCode,
        userName: userName,
      );

  static bool _isMine(
    Task task,
    String userCode,
    String staffCode,
    String userName,
  ) {
    final codes = <String>{userCode, staffCode}
      ..removeWhere((code) => code.isEmpty);
    // RBAC: a staff member manages only their own tasks. If we can't confirm
    // identity yet, deny rather than grant blanket write access to everyone
    // else's tasks (admins are handled earlier and are unaffected).
    if (codes.isEmpty) return false;
    if (codes.contains(task.assigneeCode)) return true;
    // Creator ownership goes through the shared matcher rather than comparing
    // codes here: the payload's creator is a display name today, and this rule
    // must not disagree with the "By Me" scope about who created a task.
    return TaskCreatorMatcher(
      identityCodes: codes,
      displayName: userName,
    ).matches(task);
  }
}
