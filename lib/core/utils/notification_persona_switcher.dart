import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/login_persona_util.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/user_profile_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/src/app_router.dart';

/// Switches the ACTIVE PERSONA (not school) when a notification/link targets
/// a different role than the one currently active at the SAME org+school —
/// e.g. a staff member who is also a guardian at their own child's school,
/// opening a guardian-facing email link while the staff persona is active.
///
/// [switchActiveSchoolIfNeeded] (active_school_switcher.dart) only switches
/// org/school; it no-ops when both already match the link, which is exactly
/// the case a same-school different-persona link hits — nothing about role
/// ever changes without this. This mirrors the exact switch sequence
/// `custom_app_bar.dart`'s manual "Switch Profile" button already runs
/// (persist → invalidate caches → refresh role → prefetch), just driven by a
/// link's `role` instead of a user tapping "cycle to next profile".
///
/// No-op (returns `false`) when: the link carries no role, the account is
/// already on that persona, or the account has no such persona available at
/// the active school — never silently grants access the account doesn't have.
Future<bool> switchActiveSchoolPersonaIfNeeded({
  required BuildContext context,
  required String? targetRole,
}) async {
  final target = (targetRole ?? '').trim();
  if (target.isEmpty) return false;

  final storage = serviceLocator<StorageService>();
  final currentRole =
      (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
  if (currentRole.isNotEmpty &&
      currentRole.toUpperCase() == target.toUpperCase()) {
    return false;
  }

  final roleCubit = context.read<RoleCubit>();
  final cubit = serviceLocator<UserProfileCubit>();
  try {
    await cubit.load(isParent: roleCubit.isParent);

    final match = cubit.state.distinctRolesForCurrentSchool
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .firstWhere(
          (e) => e.toUpperCase() == target.toUpperCase(),
          orElse: () => '',
        );
    if (match.isEmpty) {
      AppLogger.d(
        '[FCM] Link targets role "$target" but the account has no such '
        'persona at the active school — staying on the current persona.',
      );
      return false;
    }

    AppLogger.d(
      '[FCM] Switching active persona for notification: $currentRole → $match',
    );

    await cubit.persistPersonaSwitch(match);
    if (!context.mounted) return false;

    try {
      context.read<GeofenceCubit>().handleProfileSwitch();
    } catch (_) {}

    final parentChild = context.read<ParentChildCubit>();
    parentChild.invalidate();

    // Preload guardian data BEFORE RoleCubit flips to parent, same ordering
    // reason as custom_app_bar.dart's own switch: avoids a loading flash on
    // the global child dropdown once the persona actually changes.
    if (roleStringIsGuardianPersona(match)) {
      await cubit.loadGuardianProfileForParent();
      if (!context.mounted) return false;
      await parentChild.ensureLoaded(force: true);
    }
    if (!context.mounted) return false;

    await roleCubit.refreshAccessFromServer(force: true);

    final orgCode = (cubit.state.organizationCode ?? '').trim();
    final schoolCode = (cubit.state.schoolCode ?? '').trim();
    if (orgCode.isNotEmpty && schoolCode.isNotEmpty && context.mounted) {
      try {
        await context.read<AuthCubit>().prefetchStaffProfileForOrgAndSchool(
          organizationCode: orgCode,
          schoolCode: schoolCode,
        );
      } catch (_) {}
    }
    if (!context.mounted) return false;

    // The app shell's nav chrome (drawer/bottom-nav) and every kept-alive
    // branch screen are built for the OLD persona and don't reactively
    // rebuild just because RoleCubit's state changed underneath them —
    // custom_app_bar.dart's manual switch hits the exact same problem and
    // fixes it the same way: unwind any pushed screens, land on the
    // dashboard branch (which DOES branch on RoleCubit, so this is what
    // actually rebuilds the chrome for the new persona), then tell every
    // kept-alive branch to reload. The caller navigates to the REAL
    // destination right after this returns.
    popAllShellBranchNavigators(context);
    if (!context.mounted) return false;
    goToDashboardRoot(context);
    SchoolSwitchEvents.notifySwitched();

    AppLogger.d('[FCM] Active-persona switch complete → ready to redirect.');
    return true;
  } finally {
    cubit.close();
  }
}
