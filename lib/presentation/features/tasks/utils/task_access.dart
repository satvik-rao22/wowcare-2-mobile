import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Role-based access rules for the Tasks module (PRD §5.2 RBAC).
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
  static bool canAccessModule(RoleCubit roles) => !roles.isParent;

  /// Admin and staff can create tasks; parents never can (PRD FR-TK-01).
  static bool canCreateTasks(RoleCubit roles) => !roles.isParent;

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
  }) {
    if (roles.isParent) return false;
    if (isAdmin(roles)) return true;
    if (!roles.isStaff) return false;
    return _isMine(task, userCode, staffCode);
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
  }) {
    if (roles.isParent) return false;
    if (isAdmin(roles)) return true;
    if (!roles.isStaff) return false;
    return _isMine(task, userCode, staffCode);
  }

  /// Inline status/priority changes follow the same ownership rule as full
  /// edits (PRD §5.2 "Own tasks only" for staff).
  static bool canChangeStatus({
    required RoleCubit roles,
    required Task task,
    required String userCode,
    String staffCode = '',
  }) =>
      canManageTask(
        roles: roles,
        task: task,
        userCode: userCode,
        staffCode: staffCode,
      );

  static bool _isMine(Task task, String userCode, String staffCode) {
    final codes = <String>{userCode, staffCode}
      ..removeWhere((code) => code.isEmpty);
    // RBAC: a staff member manages only their own tasks. If we can't confirm
    // identity yet, deny rather than grant blanket write access to everyone
    // else's tasks (admins are handled earlier and are unaffected).
    if (codes.isEmpty) return false;
    return codes.contains(task.assigneeCode) || codes.contains(task.createdBy);
  }
}
