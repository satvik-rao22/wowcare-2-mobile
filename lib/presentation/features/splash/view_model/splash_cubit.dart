import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:wowcare/core/auth/session_expired_coordinator.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/login_persona_util.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/data/features/notifications/models/push_notification_model.dart';
import 'package:wowcare/domain/features/notifications/usecases/register_device_fcm_token_usecase.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/core/auth/kiosk_access_control.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/src/app_router.dart'
    show consumePendingNotificationDeepLink, consumePendingNotificationOrgSchool;

part 'splash_state.dart';

/// Decides where the app goes on launch: onboarding, sign-in, org/school
/// selection, the dashboard, or a notification deep-link.
///
/// MVVM golden rule (same as [RoleCubit]): this ViewModel has no View
/// dependency (no BuildContext, widgets, navigation) — [SplashScreenWrapper]
/// only calls [resolve] and reacts to the emitted [SplashState.route] via a
/// `BlocListener`, performing the actual `context.go(...)` itself. The one
/// exception is a killed-state notification's org/school switch
/// ([switchActiveSchoolIfNeeded]), which itself needs a BuildContext to read
/// other cubits — that single side effect stays in the widget, driven by
/// [SplashState.pendingOrgSchool]/[SplashState.deepLinkLocation].
///
/// [RoleCubit]/[ParentChildCubit]/[AuthCubit] are injected as constructor
/// dependencies rather than resolved via `serviceLocator` — those cubits are
/// app-root singletons reachable only through the widget tree's
/// `BlocProvider`s (see `app_providers.dart`/`app_bloc_providers.dart`), so
/// the caller must pass the SAME instances via `context.read<...>()` at
/// construction time; resolving a fresh one from `serviceLocator` would
/// silently operate on a throwaway instance nothing else observes.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit({
    required StorageService storage,
    required AuthLocalDataSource authLocal,
    required AuthRemoteDataSource authRemote,
    required KioskAccessControl kioskAccessControl,
    required RegisterDeviceFcmTokenUseCase registerDeviceFcmTokenUseCase,
    required RoleCubit roleCubit,
    required ParentChildCubit parentChildCubit,
    required AuthCubit authCubit,
  }) : _storage = storage,
       _authLocal = authLocal,
       _authRemote = authRemote,
       _kioskAccessControl = kioskAccessControl,
       _registerDeviceFcmTokenUseCase = registerDeviceFcmTokenUseCase,
       _roleCubit = roleCubit,
       _parentChildCubit = parentChildCubit,
       _authCubit = authCubit,
       super(const SplashState());

  final StorageService _storage;
  final AuthLocalDataSource _authLocal;
  final AuthRemoteDataSource _authRemote;
  final KioskAccessControl _kioskAccessControl;
  final RegisterDeviceFcmTokenUseCase _registerDeviceFcmTokenUseCase;
  final RoleCubit _roleCubit;
  final ParentChildCubit _parentChildCubit;
  final AuthCubit _authCubit;

  void _safeEmit(SplashState next) {
    if (!isClosed) emit(next);
  }

  /// Check if stored roles JSON contains exact KIOSK role (not STAFF_KIOSK, etc.)
  bool _isKioskFromStoredRoles(String rolesJson) {
    if (rolesJson.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(rolesJson);
      if (decoded is List) {
        final roles = decoded
            .whereType<Map<String, dynamic>>()
            .map(RoleModel.fromJson);
        return roles.any((r) => r.role.toUpperCase().trim() == 'KIOSK');
      }
    } catch (e) {
      AppLogger.d('[Splash] Error parsing roles JSON: $e');
    }
    return false;
  }

  /// Reads the notification that cold-launched the app (killed state) and maps
  /// it to a go_router location, or null if the app wasn't launched from a
  /// notification tap / the action has no in-app target. Safe to call this
  /// early: the FCM plugin is reliably attached by the time [resolve] runs
  /// (after its own 1s delay + the auth/login-context round trip).
  Future<String?> _resolveLaunchDeepLink() async {
    try {
      final launch = await FirebaseMessaging.instance.getInitialMessage();
      if (launch == null) return null;
      // Persona comes from storage, not RoleCubit: this runs before the shell
      // (and its RoleCubit) is up. Billing and newsletter destinations differ
      // per persona, so guessing here would cold-start a parent onto the
      // staff screen — e.g. a newsletter tap landing on room chat.
      final persona = await resolvePersonaFamilyFromStorage(_storage);
      final dest = NotificationRouteResolver.resolve(
        PushNotificationModel.fromRemoteMessage(launch),
        isGuardian: persona == 'parent',
        isAdminPersona: persona == 'admin',
      );
      return dest?.location;
    } catch (_) {
      return null;
    }
  }

  Future<void> resolve() async {
    await Future.delayed(const Duration(seconds: 1));
    if (isClosed) return;

    final seenOnboarding =
        await _storage.getBool(StorageKeys.onboardingSeen) ?? false;

    if (!seenOnboarding) {
      // `onboardingSeen` is a plain SharedPreferences bool: its write on
      // completing onboarding can lose the race with an abrupt task-kill
      // (Android's Editor.apply() flushes asynchronously) and read back
      // false/null on the very next cold launch even though the user is
      // genuinely logged in. Only treat this as a true first launch — and
      // only then destroy the cached session — when there is no cached
      // login to protect; otherwise persist the flag now and fall through
      // to the normal session-restore flow below instead of forcing a
      // fresh sign-in.
      final hasExistingLogin = await _authLocal.getCachedLoginResponse() != null;
      if (isClosed) return;
      if (!hasExistingLogin) {
        await _authLocal.clearCache();
        _safeEmit(state.copyWith(route: SplashRoute.firstScreen));
        return;
      }
      await _storage.saveBool(StorageKeys.onboardingSeen, true);
    }

    String? redirectUrl;
    bool hasCachedLogin = false;
    bool sessionExpired = false;
    try {
      final cachedLogin = await _authLocal.getCachedLoginResponse();
      if (cachedLogin != null) {
        hasCachedLogin = true;

        // Proactively refresh a stale access token BEFORE the first
        // authenticated call of a cold start. `/auth/login-context` is
        // deliberately exempted from SessionExpiredInterceptor's reactive
        // refresh-then-retry (see its `_shouldIgnorePath` doc — "handled by
        // splash screen"), and TokenLifecycleObserver's own proactive
        // refresh only fires on a lifecycle `resumed` transition / idle
        // timer, neither of which has necessarily run yet this early in a
        // fresh launch. Without this, a merely-STALE (not actually invalid)
        // token here fell straight through to a full logout instead of a
        // silent refresh — the exact scenario a phone left backgrounded for
        // hours hits on relaunch, and why this rarely surfaced on web (a
        // browser tab's token usually doesn't go stale within the tab's
        // lifetime).
        //
        // This is only a PRE-EMPTIVE check though: ensureFreshToken() trusts
        // the locally-recorded expiry timestamp and silently no-ops (no
        // refresh call, no log line) whenever that says the token still has
        // life left — even if the server has actually invalidated it for an
        // unrelated reason (revoked session, clock drift, a shorter real
        // TTL than what got recorded). So getLoginContext below can still
        // 401 despite this. Handle that the same way
        // SessionExpiredInterceptor handles every OTHER endpoint's 401: one
        // forced refresh (bypassing ensureFreshToken's "looks fine" guess)
        // and ONE retry, before concluding the session is genuinely dead.
        await TokenRefreshService.instance.ensureFreshToken();
        final freshAccessToken =
            await TokenRefreshService.instance.readAccessToken();

        Future<Map<String, dynamic>?> fetchContext(String token) async {
          try {
            return await _authRemote.getLoginContext(accessToken: token);
          } on DioException catch (e) {
            if (e.response?.statusCode == 401) return null;
            rethrow;
          }
        }

        var contextData = await fetchContext(
          freshAccessToken.isNotEmpty
              ? freshAccessToken
              : cachedLogin.accessToken,
        );
        if (contextData == null) {
          final renewedToken = await TokenRefreshService.instance
              .refreshSession();
          if (renewedToken != null && renewedToken.isNotEmpty) {
            contextData = await fetchContext(renewedToken);
          }
        }
        if (contextData == null) {
          // Genuinely dead even after a forced refresh + retry — not just
          // "not yet worth refreshing" per ensureFreshToken's guess.
          sessionExpired = true;
        } else {
          await _authLocal.saveLoginContext(contextData);
          await _authLocal.saveOrgAndSchoolFromContext(contextData);

          final rawRedirect = contextData['redirectUrl'];
          redirectUrl = rawRedirect is String ? rawRedirect.trim() : null;

          final orgCode =
              (contextData['LastLoginOrganizationCode'] as String?)?.trim() ??
              '';
          final schoolCode =
              (contextData['LastLoginSchoolCode'] as String?)?.trim() ?? '';

          if (orgCode.isNotEmpty) {
            final existingOrgCode =
                (await _storage.getString(StorageKeys.organizationCode) ?? '')
                    .trim();
            final existingSchoolCode =
                (await _storage.getString(StorageKeys.schoolCode) ?? '')
                    .trim();
            // Only reuse the existing school when it was selected under THIS
            // SAME org. Reusing it across a different org silently pairs the
            // new orgCode with a school that belongs to a completely
            // different organization — e.g. writing organizationCode=ORG-B
            // while schoolCode stays ORG-A's school. Every later request
            // then sends that impossible org+school combination, which the
            // backend rejects with a 403 "No active 'any' membership ..."
            // that has nothing to do with the user's actual access — it's
            // rejecting a pairing that was never valid to begin with. Seen
            // live on the org-names call the switch-organization picker
            // fires on open.
            final effectiveSchoolCode = schoolCode.isNotEmpty
                ? schoolCode
                : (existingOrgCode == orgCode ? existingSchoolCode : '');

            if (effectiveSchoolCode.isNotEmpty) {
              await _authLocal.setSelectedOrgAndSchool(
                organizationCode: orgCode,
                schoolCode: effectiveSchoolCode,
                schoolName: '',
              );
            } else {
              // Only org known (and no same-org school to carry forward):
              // save the org and clear any stale, now-mismatched school
              // selection rather than leaving it paired with a different org.
              await _storage.saveString(StorageKeys.organizationCode, orgCode);
              if (existingOrgCode != orgCode && existingSchoolCode.isNotEmpty) {
                await _storage.remove(StorageKeys.schoolCode);
              }
            }
          }
        }
      }
    } on DioException catch (e) {
      // A 401 here means the cached access token is no longer valid — the
      // session has expired. Route to sign-in with the "session expired"
      // message instead of opening a stale, still-logged-in dashboard.
      // Any other DioException (offline, timeout, 5xx) is transient: fall
      // through and let the app open with cached data so it still works offline.
      if (e.response?.statusCode == 401) {
        sessionExpired = true;
      }
    } catch (_) {
      // Non-fatal: still decide navigation below.
    }

    if (isClosed) return;

    if (sessionExpired) {
      // Full logout cascade: best-effort backend logout, clear cached session
      // (profile name, roles, tokens), reset auth cubits, show the "session
      // expired" snackbar, and navigate to sign-in. The coordinator performs
      // its own navigation (via a global navigator key), so this cubit just
      // marks the route as handled and does nothing further.
      await SessionExpiredCoordinator.instance.performLogoutDueToExpiredSession(
        fromEntryRoute: true,
      );
      _safeEmit(state.copyWith(route: SplashRoute.sessionExpired));
      return;
    }

    if (hasCachedLogin) {
      // Fast kiosk check from stored roles — no API needed.
      final storedRoles = await _storage.getString(StorageKeys.roles) ?? '';
      final isKiosk = _isKioskFromStoredRoles(storedRoles);
      AppLogger.d('[Splash] Cached login - isKiosk=$isKiosk');
      if (isKiosk) {
        AppLogger.d('[Splash] Kiosk user detected - redirecting to /kiosk');
        _safeEmit(state.copyWith(route: SplashRoute.kiosk));
        return;
      }

      // Non-kiosk cached session: clear any stale kiosk flag from storage and
      // the in-memory cache so GoRouter never sees a false positive.
      try {
        await _kioskAccessControl.deactivateKioskMode();
        AppLogger.d('[Splash] Non-kiosk cached session — kiosk state cleared');
      } catch (_) {
        _kioskAccessControl.clearCacheForNonKioskLogin();
      }

      await _roleCubit.refreshAccessFromServer(force: true);

      try {
        if (_roleCubit.isParent) {
          _parentChildCubit.invalidate();
          await _parentChildCubit.ensureLoaded(force: true);
        }
      } catch (_) {
        // Non-blocking.
      }

      if (isClosed) return;

      final orgCode =
          (await _storage.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (orgCode.isNotEmpty && schoolCode.isNotEmpty) {
        await _authCubit.prefetchStaffProfileForOrgAndSchool(
          organizationCode: orgCode,
          schoolCode: schoolCode,
        );
        // PushNotificationCubit.init() runs before splash restores org/school.
        try {
          await _registerDeviceFcmTokenUseCase();
        } catch (_) {}
      }

      if (isClosed) return;

      // Killed-state cold launch: prefer the deep-link main() stashed; if main()
      // ran before the FCM plugin was attached (so getInitialMessage() returned
      // null there), resolve the launch message here — by now (post 1s delay +
      // auth) the messaging plugin is reliably attached, so it's the safe spot.
      final pendingFromMain = consumePendingNotificationDeepLink();
      String? launchDeepLink = pendingFromMain;
      launchDeepLink ??= await _resolveLaunchDeepLink();
      // Org/school the killed-state notification targets (multi-school user).
      // Applied only on the paths that actually use launchDeepLink, below.
      final pendingOrgSchool = consumePendingNotificationOrgSchool();
      AppLogger.d(
        '[Splash] killed-state deep-link: pendingFromMain="$pendingFromMain" '
        'resolved="$launchDeepLink" redirectUrl="$redirectUrl" '
        'orgSchool=$pendingOrgSchool',
      );
      if (isClosed) return;

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        final url = redirectUrl.toLowerCase();
        if (url.contains('select-school')) {
          // Login context still needs an org/school chosen — don't override the
          // routing with a notification deep-link (it has no school scope yet).
          // Drop the deep-link and continue to school selection.
          final org = (await _storage.getString(StorageKeys.organizationCode) ?? '')
              .trim();
          if (isClosed) return;
          await _authCubit.loadCachedData();
          if (isClosed) return;
          if (org.isNotEmpty) {
            _safeEmit(
              state.copyWith(
                route: SplashRoute.schoolSelection,
                schoolSelectionOrgCode: org,
              ),
            );
          } else {
            _safeEmit(state.copyWith(route: SplashRoute.orgSelection));
          }
          return;
        }
        if (url.contains('select-organization')) {
          // Org not chosen yet — don't override routing with the deep-link.
          await _authCubit.loadCachedData();
          if (isClosed) return;
          _safeEmit(state.copyWith(route: SplashRoute.orgSelection));
          return;
        }
        if (url.contains('dashboard') || url.contains('select-app')) {
          _safeEmit(
            state.copyWith(
              route: SplashRoute.dashboardOrDeepLink,
              deepLinkLocation: launchDeepLink,
              pendingOrgSchool: pendingOrgSchool,
            ),
          );
          return;
        }
      }

      // No redirectUrl: default to dashboard — unless a notification cold-launched
      // the app, in which case route to its deep-link instead of home.
      _safeEmit(
        state.copyWith(
          route: SplashRoute.dashboardOrDeepLink,
          deepLinkLocation: launchDeepLink,
          pendingOrgSchool: pendingOrgSchool,
        ),
      );
    } else {
      // No cached login: go to sign-in. Drop any pending deep-link so it can't
      // leak into a later authenticated session.
      consumePendingNotificationDeepLink();
      _safeEmit(state.copyWith(route: SplashRoute.signIn));
    }
  }
}
