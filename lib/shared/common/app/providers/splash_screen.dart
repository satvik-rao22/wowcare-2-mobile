import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/data/features/notifications/models/push_notification_model.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:wowcare/shared/common/widgets/animation_slide_widgets.dart';

// Avoid silencing `forgot_password_screen.dart`/`sign_in_screen.dart` analyzer
// `unused_import` lint — they're referenced by route-path constants below
// (`DashboardScreen.routeName`, `SignInScreen.routeName`).
// ignore_for_file: unused_import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimationWrapper(
            type: AnimationType.bounce,
            duration: Duration.zero,
            curve: Curves.easeOut,
            child: Image.asset(MediaRes.backgroundImage2, fit: BoxFit.cover),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/WowCarePNG.png',
                width: 150,
                height: 150,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decides where the app goes on launch: onboarding, sign-in, org/school
/// selection, or the dashboard. Lives in the router as the "/" route — uses
/// `context.go(...)` to swap itself out once the decision is made.
class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final storage = serviceLocator<StorageService>();

    final seenOnboarding =
        await storage.getBool(StorageKeys.onboardingSeen) ?? false;

    if (!seenOnboarding) {
      // First launch: show onboarding and clear any stale auth cache.
      await serviceLocator<AuthLocalDataSource>().clearCache();
      if (!mounted) return;
      context.go('/first-screen');
      return;
    }

    String? redirectUrl;
    bool hasCachedLogin = false;
    try {
      final authLocal = serviceLocator<AuthLocalDataSource>();
      final cachedLogin = await authLocal.getCachedLoginResponse();
      if (cachedLogin != null) {
        hasCachedLogin = true;
        final authRemote = serviceLocator<AuthRemoteDataSource>();
        final contextData = await authRemote.getLoginContext(
          accessToken: cachedLogin.accessToken,
        );
        await authLocal.saveLoginContext(contextData);
        await authLocal.saveOrgAndSchoolFromContext(contextData);

        final rawRedirect = contextData['redirectUrl'];
        redirectUrl = rawRedirect is String ? rawRedirect.trim() : null;

        final orgCode =
            (contextData['LastLoginOrganizationCode'] as String?)?.trim() ?? '';
        final schoolCode =
            (contextData['LastLoginSchoolCode'] as String?)?.trim() ?? '';

        if (orgCode.isNotEmpty) {
          final existingSchoolCode =
              (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
          final effectiveSchoolCode =
              schoolCode.isNotEmpty ? schoolCode : existingSchoolCode;

          if (effectiveSchoolCode.isNotEmpty) {
            await authLocal.setSelectedOrgAndSchool(
              organizationCode: orgCode,
              schoolCode: effectiveSchoolCode,
              schoolName: '',
            );
          } else {
            // Only org known; keep any existing school selection.
            await storage.saveString(StorageKeys.organizationCode, orgCode);
          }
        }
      }
    } catch (_) {
      // Non-fatal: still decide navigation below.
    }

    if (!mounted) return;

    if (hasCachedLogin) {
      await context.read<RoleCubit>().refreshAccessFromServer(force: true);

      try {
        if (mounted && context.read<RoleCubit>().isParent) {
          context.read<ParentChildCubit>().invalidate();
          await context.read<ParentChildCubit>().ensureLoaded(force: true);
        }
      } catch (_) {
        // Non-blocking.
      }

      if (!mounted) return;

      final orgCode =
          (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (orgCode.isNotEmpty && schoolCode.isNotEmpty) {
        if (!mounted) return;
        await context.read<AuthCubit>().prefetchStaffProfileForOrgAndSchool(
              organizationCode: orgCode,
              schoolCode: schoolCode,
            );
      }

      if (!mounted) return;

      // Killed-state cold launch: prefer the deep-link main() stashed; if main()
      // ran before the FCM plugin was attached (so getInitialMessage() returned
      // null there), resolve the launch message here — by now (post 1s delay +
      // auth) the messaging plugin is reliably attached, so it's the safe spot.
      final pendingFromMain = consumePendingNotificationDeepLink();
      String? launchDeepLink = pendingFromMain;
      launchDeepLink ??= await _resolveLaunchDeepLink();
      AppLogger.d(
        '[Splash] killed-state deep-link: pendingFromMain="$pendingFromMain" '
        'resolved="$launchDeepLink" redirectUrl="$redirectUrl"',
      );
      if (!mounted) return;

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        final url = redirectUrl.toLowerCase();
        if (url.contains('select-school')) {
          // Login context still needs an org/school chosen — don't override the
          // routing with a notification deep-link (it has no school scope yet).
          // Drop the deep-link and continue to school selection.
          final org = await storage.getString(StorageKeys.organizationCode);
          if (!mounted) return;
          await context.read<AuthCubit>().loadCachedData();
          if (!mounted) return;
          if (org != null && org.isNotEmpty) {
            context.go(
              '/school-selection',
              extra: <String, dynamic>{
                'selectedOrg': org,
                'orgFromLoginContext': true,
              },
            );
          } else {
            context.go('/org-selection');
          }
          return;
        }
        if (url.contains('select-organization')) {
          // Org not chosen yet — don't override routing with the deep-link.
          await context.read<AuthCubit>().loadCachedData();
          if (!mounted) return;
          context.go('/org-selection');
          return;
        }
        if (url.contains('dashboard') || url.contains('select-app')) {
          context.go(launchDeepLink ?? DashboardScreen.routeName);
          return;
        }
      }

      // No redirectUrl: default to dashboard — unless a notification cold-launched
      // the app, in which case route to its deep-link instead of home.
      context.go(launchDeepLink ?? DashboardScreen.routeName);
    } else {
      // No cached login: go to sign-in. Drop any pending deep-link so it can't
      // leak into a later authenticated session.
      consumePendingNotificationDeepLink();
      context.go(SignInScreen.routeName);
    }
  }

  /// Reads the notification that cold-launched the app (killed state) and maps
  /// it to a go_router location, or null if the app wasn't launched from a
  /// notification tap / the action has no in-app target. Safe to call here:
  /// the FCM plugin is reliably attached by the time the splash decides routing.
  Future<String?> _resolveLaunchDeepLink() async {
    try {
      final launch = await FirebaseMessaging.instance.getInitialMessage();
      if (launch == null) return null;
      final dest = NotificationRouteResolver.resolve(
        PushNotificationModel.fromRemoteMessage(launch),
      );
      return dest?.location;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
