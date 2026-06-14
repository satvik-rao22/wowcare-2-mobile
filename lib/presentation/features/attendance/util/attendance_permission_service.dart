import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

class AttendancePermissionService {
  /// Tooltip shown when a STAFF persona tries to manage student attendance
  /// before completing their own self sign-in.
  static const String staffSelfSignInRequiredMessage =
      'Please sign in yourself before signing in a student.';

  /// Checks if the current context has permission to manage student attendance.
  ///
  /// Under Clean Architecture:
  /// - Admin, Org Admin, Director, and School Admin personas have unrestricted access.
  /// - STAFF role requires:
  ///   1. Being inside geofence (GeofenceCubit.state.isWithinGeofence == true)
  ///   2. Completed self clock-in (GeofenceCubit.state.isStaffSignedIn == true)
  static bool hasPermissionToManageStudentAttendance(BuildContext context) {
    final roleProvider = context.read<RoleCubit>();
    if (!roleProvider.isStaff) {
      return true; // Unrestricted access for admin roles
    }
    

    final geofenceState = context.read<GeofenceCubit>().state;
    return geofenceState.isWithinGeofence && geofenceState.isStaffSignedIn;
  }
}
