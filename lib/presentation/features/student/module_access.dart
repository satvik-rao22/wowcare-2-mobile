import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Canonical `module` strings from `/api/v1/users/details` `permissions[]`.
///
/// Use these with [RoleCubit.canReadModule], [canWriteModule], [canOpenModule],
/// and [ModuleAccess] helpers so UI matches backend ACLs.
abstract final class AppAccessModules {
  static const String classroom = 'CLASSROOM';
  static const String staff = 'STAFF';
  static const String student = 'STUDENT';
  static const String dailyActivity = 'DAILY_ACTIVITY';
  static const String studentAttendance = 'STUDENT_ATTENDANCE';
  static const String staffAttendance = 'STAFF_ATTENDANCE';
  static const String transaction = 'TRANSACTION';
  static const String recurringPlans = 'RECURRINGPLANS';
  static const String invoices = 'INVOICES';
  static const String billingSettings = 'BILLING_SETTINGS';
  static const String parentMessaging = 'PARENT_MESSAGING';
  static const String staffMessaging = 'STAFF_MESSAGING';
  static const String settings = 'SETTINGS';
  static const String staffScheduling = 'STAFF_SCHEDULING';
  static const String studentTags = 'STUDENT_TAGS';
  static const String movementRules = 'MOVEMENT_RULES';
  static const String reports = 'REPORTS';
  static const String futureAvailability = 'FUTURE_AVAILABILITY';
  static const String dashboard = 'DASHBOARD';
  static const String newsletter = 'NEWSLETTER';
  static const String classroomSchedule = 'CLASSROOM_SCHEDULE';
  /// Backend spelling per API contract (not "INDIVIDUAL").
  static const String individualMovements = 'INDIVISUAL_MOVEMENTS';
  static const String tasks = 'TASKS';
  static const String assessments = 'ASSESSMENTS';
}

/// Read/write UI gates backed by [RoleCubit] for **every** persona.
final class ModuleAccess {
  ModuleAccess._();

  static const String writeRestrictedMessage =
      'You only have view access here. Contact your school if you need permission to add or change information.';

  static const String featureRestrictedMessage =
      'You do not have access to this area for your selected school.';

  static bool mayWrite(RoleCubit role, String module) {
    return role.canWriteModule(module);
  }

  static bool mayReadOrWrite(RoleCubit role, String module) {
    return role.canReadModule(module);
  }

  static bool mayOpenFeature(RoleCubit role, String module) {
    return role.canOpenModule(module);
  }

  static void showWriteRestricted(BuildContext context) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: writeRestrictedMessage,
      isError: true,
    );
  }

  static void showFeatureRestricted(BuildContext context) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: featureRestrictedMessage,
      isError: true,
    );
  }

  static void runIfWriteAllowed(
    BuildContext context,
    RoleCubit role,
    String module,
    VoidCallback action,
  ) {
    if (mayWrite(role, module)) {
      action();
    } else {
      showWriteRestricted(context);
    }
  }

  static void runIfFeatureAllowed(
    BuildContext context,
    RoleCubit role,
    String module,
    VoidCallback action,
  ) {
    if (mayOpenFeature(role, module)) {
      action();
    } else {
      showFeatureRestricted(context);
    }
  }
}
