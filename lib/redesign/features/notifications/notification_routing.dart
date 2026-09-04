import 'package:wowcare/domain/features/notifications/entities/notification_action.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';

/// 12c. Where a tapped notification lands.
///
/// The redesign's half of the shipped `NotificationRouteResolver`: same
/// vocabulary, same shape, one row per action, and the same two-step fallback
/// (an unknown action lands on its module's home rather than nowhere). The
/// action constants are imported from the domain entity rather than retyped,
/// so the two tables cannot drift apart and Phase 5 is a binding rather than a
/// rewrite.
///
/// What is different is honesty about what exists. Six modules are built, so
/// only those produce a [NotificationRoute]; everything else answers
/// [NotificationNotBuilt] and the screen says the module is being rebuilt. A
/// placeholder would be worse: it looks like the tap worked.
///
/// Persona is passed in because the same action lands differently: a
/// guardian's list-level notification goes to the dashboard, where their
/// child's day is, rather than to a school-side roster that would refuse them.
abstract final class NotificationRouting {
  static NotificationDestination destinationOf(
    NotificationItem item, {
    required Persona persona,
  }) {
    final action = NotificationAction.canonical(item.action);
    final code = item.targetCode;
    final isGuardian = persona == Persona.guardian;

    // --- Classrooms ---------------------------------------------------------

    if (_classroomActions.contains(action)) {
      if (isGuardian) return const NotificationRoute(AppRoutes.dashboard);
      return code == null
          ? const NotificationRoute(AppRoutes.classrooms)
          : NotificationRoute(AppRoutes.classroom(code));
    }

    // --- Students -----------------------------------------------------------

    if (_studentActions.contains(action)) return _student(code, isGuardian);

    // --- Staff --------------------------------------------------------------

    if (_staffActions.contains(action)) return _staff(code, isGuardian);

    // --- Attendance ---------------------------------------------------------
    //
    // A notification about one student opens that student, not the day's
    // list: the notification is about one child. The same for one staff
    // member, and a ratio or capacity alert opens the classroom it names.

    if (_studentAttendanceActions.contains(action)) {
      return _student(code, isGuardian, listRoute: AppRoutes.attendance);
    }
    if (_staffAttendanceActions.contains(action)) {
      return _staff(code, isGuardian, listRoute: AppRoutes.attendance);
    }
    if (_classroomAttendanceActions.contains(action)) {
      if (isGuardian) return const NotificationRoute(AppRoutes.dashboard);
      return code == null
          ? const NotificationRoute(AppRoutes.attendance)
          : NotificationRoute(AppRoutes.classroom(code));
    }
    if (action == NotificationAction.attendanceNotMarked) {
      return isGuardian
          ? const NotificationRoute(AppRoutes.dashboard)
          : const NotificationRoute(AppRoutes.attendance);
    }

    // --- Settings, and the device's own geofence ----------------------------
    //
    // The shipped table sends a settings change to `/notifications`, which is
    // the screen the tap started on. Here it lands on the preferences that
    // decide what the bell carries, which is the only settings screen built.

    if (action == NotificationAction.schoolSettingsChanged) {
      return const NotificationRoute(AppRoutes.notificationSettings);
    }
    if (action == NotificationAction.geofenceEnter) {
      return const NotificationRoute(AppRoutes.dashboard);
    }

    return _moduleFallback(item, isGuardian: isGuardian);
  }

  /// No action matched, so land on the module's own home. This is what keeps
  /// every row tappable while the action vocabulary keeps growing.
  static NotificationDestination _moduleFallback(
    NotificationItem item, {
    required bool isGuardian,
  }) {
    final code = item.targetCode;

    return switch (item.module) {
      NotificationModule.attendance ||
      NotificationModule.studentAttendance ||
      NotificationModule.student => _student(
        code,
        isGuardian,
        listRoute: item.module == NotificationModule.student
            ? AppRoutes.students
            : AppRoutes.attendance,
      ),
      NotificationModule.staffAttendance => _staff(
        code,
        isGuardian,
        listRoute: AppRoutes.attendance,
      ),
      NotificationModule.staff => _staff(code, isGuardian),
      NotificationModule.classroom =>
        isGuardian
            ? const NotificationRoute(AppRoutes.dashboard)
            : code == null
            ? const NotificationRoute(AppRoutes.classrooms)
            : NotificationRoute(AppRoutes.classroom(code)),

      // M08, M09, M10, M11, M14 and M15 are not rebuilt yet.
      NotificationModule.billing ||
      NotificationModule.scheduling ||
      NotificationModule.availability ||
      NotificationModule.activity ||
      NotificationModule.messaging ||
      NotificationModule.newsletter => const NotificationNotBuilt(),

      NotificationModule.other => const NotificationRoute(AppRoutes.dashboard),
    };
  }

  /// One student, or the list they are on. A guardian never reaches the
  /// roster: it refuses them, and their own dashboard is where their
  /// children are.
  static NotificationDestination _student(
    String? code,
    bool isGuardian, {
    String listRoute = AppRoutes.students,
  }) {
    if (code != null) return NotificationRoute(AppRoutes.student(code));
    return isGuardian
        ? const NotificationRoute(AppRoutes.dashboard)
        : NotificationRoute(listRoute);
  }

  static NotificationDestination _staff(
    String? code,
    bool isGuardian, {
    String listRoute = AppRoutes.staff,
  }) {
    if (isGuardian) return const NotificationRoute(AppRoutes.dashboard);
    return code == null
        ? NotificationRoute(listRoute)
        : NotificationRoute(AppRoutes.staffMember(code));
  }

  // --- The action groups, straight off `NotificationAction` -----------------

  static const Set<String> _classroomActions = <String>{
    NotificationAction.addClassroom,
    NotificationAction.editClassroom,
    NotificationAction.deleteClassroom,
    NotificationAction.assignStudentToClassroom,
    NotificationAction.assignStaffToClassroom,
    NotificationAction.addClassroomNote,
  };

  static const Set<String> _studentActions = <String>{
    NotificationAction.addStudent,
    NotificationAction.deleteStudent,
    NotificationAction.studentParentNotAdded,
    NotificationAction.studentPhysicalNotAdded,
    NotificationAction.studentBirthdateNotAdded,
    NotificationAction.studentDocumentChanged,
    NotificationAction.studentPhysicalDue,
    NotificationAction.studentPhysicalOverdue,
    NotificationAction.studentImmunizationDueOverdue,
    NotificationAction.studentScheduleNotAdded,
    NotificationAction.birthday,
  };

  static const Set<String> _staffActions = <String>{
    NotificationAction.deleteStaff,
    NotificationAction.staffPhysicalNotAdded,
    NotificationAction.staffDocumentExpiry,
    NotificationAction.staffScheduleNotAdded,
  };

  static const Set<String> _studentAttendanceActions = <String>{
    NotificationAction.studentSignInOut,
    NotificationAction.studentMarkedAbsent,
  };

  static const Set<String> _staffAttendanceActions = <String>{
    NotificationAction.staffSignInOut,
    NotificationAction.staffMarkedAbsent,
  };

  static const Set<String> _classroomAttendanceActions = <String>{
    NotificationAction.ratioBreached,
    NotificationAction.capacityExceeded,
  };
}
