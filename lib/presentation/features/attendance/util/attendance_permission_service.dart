import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';

class AttendancePermissionService {
  /// Tooltip shown when a STAFF persona tries to manage student attendance
  /// before completing their own self sign-in.
  static const String staffSelfSignInRequiredMessage =
      'Please sign in yourself before signing in a student.';

  /// Checks if the current context has permission to manage student attendance.
  ///
  /// - Admin, Org Admin, Director, and School Admin personas have unrestricted access.
  /// - STAFF role is allowed when EITHER:
  ///   1. The school enables `allowTeacherCrossClassAttendance` — the teacher
  ///      then manages student attendance exactly like an admin (no self
  ///      sign-in / geofence gate at all); OR
  ///   2. They have completed their own clock-in
  ///      (GeofenceCubit.state.isStaffSignedIn == true). Once signed in,
  ///      GPS/geofence status is irrelevant — a denied location permission or
  ///      an out-of-range position must NOT block them. (Geofence is enforced
  ///      separately for the staff's own sign-in, not for student actions.)
  ///
  /// The cross-class flag is read synchronously from
  /// [AttendanceCrossClassResolver.lastKnownEnabled]; callers must trigger
  /// [AttendanceCrossClassResolver.isEnabledForCurrentSchool] when the screen
  /// opens so it reflects the active school (the attendance popup does this).
  static bool hasPermissionToManageStudentAttendance(BuildContext context) {
    final roleProvider = context.read<RoleCubit>();
    if (!roleProvider.isStaff) {
      return true; // Unrestricted access for admin roles
    }

    // Cross-class attendance enabled → treat the teacher like an admin.
    if (AttendanceCrossClassResolver.lastKnownEnabled) {
      return true;
    }

    final geofenceState = context.read<GeofenceCubit>().state;
    return geofenceState.isStaffSignedIn;
  }
}
