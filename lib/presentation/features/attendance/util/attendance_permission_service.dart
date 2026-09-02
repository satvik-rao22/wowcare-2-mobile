import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

class AttendancePermissionService {
  /// Tooltip shown when a STAFF persona tries to manage student attendance
  /// before completing their own self sign-in.
  static const String staffSelfSignInRequiredMessage =
      'Please sign in yourself before signing in a student.';

  /// Checks if the current context has permission to manage student attendance.
  ///
  /// - Admin, Org Admin, Director, and School Admin personas have unrestricted access.
  /// - STAFF role is allowed only once they have completed their own clock-in
  ///   (GeofenceCubit.state.isStaffSignedIn == true) — always, regardless of
  ///   the school's `allowTeacherCrossClassAttendance` setting. That flag only
  ///   controls which classrooms a signed-in teacher can act across; it must
  ///   NOT waive the self sign-in requirement itself.
  ///   Once signed in, GPS/geofence status is irrelevant — a denied location
  ///   permission or an out-of-range position must NOT block them. (Geofence
  ///   is enforced separately for the staff's own sign-in, not for student
  ///   actions.)
  static bool hasPermissionToManageStudentAttendance(BuildContext context) {
    final roleProvider = context.read<RoleCubit>();
    if (!roleProvider.isStaff) {
      return true; // Unrestricted access for admin roles
    }

    final geofenceState = context.read<GeofenceCubit>().state;
    return geofenceState.isStaffSignedIn;
  }

  /// Resolves whether the current session is a parent/guardian one.
  ///
  /// Once `RoleCubit` has resolved the ACTIVE persona, it is authoritative —
  /// trust it even when false. A dual-role account (e.g. SCHOOL_ADMIN +
  /// GUARDIAN) has 'GUARDIAN' somewhere in its full roles list regardless of
  /// which persona is currently active, so scanning that list would wrongly
  /// flip an admin who switched profiles back to a guardian session. Only
  /// falls through to the best-effort scan while `RoleCubit` is still
  /// bootstrapping (no active persona resolved yet).
  static Future<bool> resolveIsParentSession(BuildContext context) async {
    final roleCubit = context.read<RoleCubit>();
    if (roleCubit.hasResolvedAccess) return roleCubit.isParent;
    if (roleCubit.isParent) return true;

    try {
      final storage = serviceLocator<StorageService>();
      if (await resolveIsGuardianOrParentFromStorage(storage)) {
        return true;
      }

      final loginContext = await storage.getJson(StorageKeys.loginContext);
      final contextRaw = jsonEncode(
        loginContext ?? const <String, dynamic>{},
      ).toUpperCase();
      if (contextRaw.contains('PARENT') || contextRaw.contains('GUARDIAN')) {
        return true;
      }
    } catch (_) {
      // Ignore parse/storage issues and keep non-parent fallback.
    }

    return false;
  }
}
