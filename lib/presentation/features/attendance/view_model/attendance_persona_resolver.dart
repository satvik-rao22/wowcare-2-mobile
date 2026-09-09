import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

/// `RoleCubit`'s active persona is the canonical, persona-switch-aware
/// signal — `staffType`/`roles` in storage can lag a beat after a persona
/// switch and misresolve a staff/teacher persona as admin (see
/// `staff_attendance_tabbed_view.dart`'s `_loadStaffPersonaFlags` for the
/// same fix). Falls back to the storage-only resolver when [mounted] is
/// false.
Future<bool> resolveIsStaffAdminPersonaForView(
  BuildContext context, {
  required bool mounted,
}) async {
  if (mounted) {
    return !context.read<RoleCubit>().isStaff;
  }
  return resolveIsStaffAdminPersonaFromStorage();
}
