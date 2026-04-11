import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';

/// Backend `module` values from `/api/v1/users/details` `permissions[]`.
///
/// Used by student-profile flows; add more IDs here as other features adopt the
/// same [RoleProvider] module checks app-wide.
abstract final class StudentAccessModules {
  static const String student = 'STUDENT';
  static const String studentAttendance = 'STUDENT_ATTENDANCE';
  static const String dailyActivity = 'DAILY_ACTIVITY';
  static const String parentMessaging = 'PARENT_MESSAGING';
  static const String transaction = 'TRANSACTION';
  static const String newsletter = 'NEWSLETTER';
  static const String dashboard = 'DASHBOARD';
}

/// Read/write UI gates backed by [RoleProvider] for **every** persona.
///
/// When the school context has no granular `permissions` list yet, staff/admin
/// keep full access; guardians stay restricted until details load. When the API
/// sends a `permissions` list (even empty), the same rules apply to all roles.
final class ModuleAccess {
  ModuleAccess._();

  static const String writeRestrictedMessage =
      'You only have view access here. Contact your school if you need permission to add or change information.';

  static const String featureRestrictedMessage =
      'You do not have access to this area for your selected school.';

  static bool mayWrite(RoleProvider role, String module) {
    return role.canWriteModule(module);
  }

  static bool mayReadOrWrite(RoleProvider role, String module) {
    return role.canReadModule(module);
  }

  static bool mayOpenFeature(RoleProvider role, String module) {
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
    RoleProvider role,
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
    RoleProvider role,
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
