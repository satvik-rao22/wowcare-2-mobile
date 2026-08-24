import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/context_switch_cache_cleaner.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_switch_events.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Switches the app's active organisation/school when a push notification
/// targets a school other than the one currently selected.
///
/// A user can be connected to more than one school (same org, different school,
/// or a different org entirely). The FCM payload carries `organizationCode` /
/// `schoolCode`; when those differ from the active selection we must switch the
/// whole app context (storage selection, persona/role, caches) BEFORE performing
/// the deep-link redirect — otherwise the target screen would load the *current*
/// school's data under the notified school's codes.
///
/// This mirrors the canonical school-switch sequence in [custom_drawer]'s
/// `_onSchoolSelected`: persist selection → update login-context → wipe caches →
/// prefetch staff profile → refresh role → reload parent/child. It is a no-op
/// (returns `false`) when the codes are missing, already current, or the user
/// does not actually have access to the notified school.
///
/// Capture cubit references happen up-front so the later `await`s never touch a
/// possibly-unmounted [context].
Future<bool> switchActiveSchoolIfNeeded({
  required BuildContext context,
  required String? organizationCode,
  required String? schoolCode,
}) async {
  final org = (organizationCode ?? '').trim();
  final school = (schoolCode ?? '').trim();
  if (org.isEmpty || school.isEmpty) return false;

  // Capture cubits up-front, before any await touches `context` — the caller's
  // widget (splash) may unmount while the storage/network awaits below run.
  final authCubit = context.read<AuthCubit>();
  final roleCubit = context.read<RoleCubit>();
  final parentChild = context.read<ParentChildCubit>();

  final storage = serviceLocator<StorageService>();
  final currentOrg =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
  final currentSchool = (await storage.getString(StorageKeys.schoolCode) ?? '')
      .trim();

  if (org == currentOrg && school == currentSchool) {
    // Already in the right school — nothing to do.
    return false;
  }

  final authLocal = serviceLocator<AuthLocalDataSource>();

  // Only switch to a school the user is actually a member of. Accept an exact
  // (org, school) match, or an org-level admin entry (empty schoolCode) for the
  // notified org — org admins can open any school under their org.
  final access = await authLocal.getOrganizationsAndSchools();
  Map<String, String>? match;
  for (final e in access) {
    final o = (e['organizationCode'] ?? '').trim();
    final s = (e['schoolCode'] ?? '').trim();
    if (o != org) continue;
    if (s == school || s.isEmpty) {
      match = e;
      if (s == school) break; // prefer the exact-school entry
    }
  }
  if (match == null) {
    AppLogger.d(
      '[FCM] Notification targets org/school the user cannot access '
      '($org / $school) — staying in current school.',
    );
    return false;
  }

  final String? schoolName = (match['schoolName'] ?? '').trim().isNotEmpty
      ? match['schoolName']!.trim()
      : null;

  // Verify from the backend that the notified school is still ACTIVE before
  // switching into it — a notification can be stale (e.g. sent before the
  // school's approval was revoked, or the school is still PENDING).
  final blockMessage = await authCubit.verifySchoolActiveOrBlockMessage(
    organizationCode: org,
    schoolCode: school,
  );
  if (blockMessage != null) {
    AppLogger.d(
      '[FCM] Notification targets a non-active school ($org / $school) — '
      'staying in current school. Reason: $blockMessage',
    );
    final ctx = CoreUtils.rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      CoreUtils.showTopSnackBar(
        context: ctx,
        message: blockMessage,
        isError: true,
      );
    }
    return false;
  }

  AppLogger.d(
    '[FCM] Switching active school for notification: '
    '$currentOrg/$currentSchool → $org/$school ($schoolName)',
  );

  // 1. Persist the new selection (clears stale timezone + activeSchoolRole).
  await authLocal.setSelectedOrgAndSchool(
    organizationCode: org,
    schoolCode: school,
    schoolName: schoolName,
  );

  // 2. Tell the backend this is now the active login-context (non-blocking).
  try {
    await authCubit.updateLoginContext(
      lastLoginOrganizationCode: org,
      lastLoginSchoolCode: school,
    );
  } catch (e) {
    AppLogger.d('[FCM] updateLoginContext failed (non-fatal): $e');
  }

  // 3. Wipe every cached artifact so the new school loads fresh, not from the
  //    previous school's cache.
  await clearAllCachesForContextSwitch(storage);

  // 4. Re-resolve persona-specific data (staffCode/PIN/profile) for the new school.
  try {
    await authCubit.prefetchStaffProfileForOrgAndSchool(
      organizationCode: org,
      schoolCode: school,
    );
  } catch (e) {
    AppLogger.d('[FCM] prefetchStaffProfile failed (non-fatal): $e');
  }

  // 5. Refresh role/access so module visibility matches the new school.
  try {
    await roleCubit.refreshAccessFromServer(force: true);
  } catch (e) {
    AppLogger.d('[FCM] role refresh failed (non-fatal): $e');
  }

  // 6. Reload parent/child selection for the new school.
  try {
    parentChild.invalidate();
    await parentChild.ensureLoaded(force: true);
  } catch (e) {
    AppLogger.d('[FCM] parent/child reload failed (non-fatal): $e');
  }

  // Tell every kept-alive branch screen to reload fresh for the new school.
  SchoolSwitchEvents.notifySwitched();

  AppLogger.d('[FCM] Active-school switch complete → ready to redirect.');
  return true;
}
