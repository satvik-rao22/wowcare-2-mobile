import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/active_school_switcher.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/splash/view_model/splash_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/animation_slide_widgets.dart';

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
                MediaRes.appLogo,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decides where the app goes on launch: sign-in, org/school
/// selection, or the dashboard. Lives in the router as the "/" route.
///
/// Pure View: all the decision logic (session/kiosk/deep-link
/// resolution) lives in [SplashCubit] — this widget only reacts to the
/// emitted [SplashState.route] and performs the actual `context.go(...)`.
/// The one exception is [_switchSchoolForLaunch]: a killed-state
/// notification's org/school switch needs a BuildContext to read other
/// cubits ([switchActiveSchoolIfNeeded]), so that single side effect stays
/// here rather than in the (BuildContext-free) cubit.
class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  Future<void> _onRouteChanged(BuildContext context, SplashState state) async {
    switch (state.route) {
      case SplashRoute.pending:
        return;
      case SplashRoute.sessionExpired:
        // SessionExpiredCoordinator already performed its own navigation.
        return;
      case SplashRoute.kiosk:
        context.go('/kiosk');
        return;
      case SplashRoute.signIn:
        context.go(SignInScreen.routeName);
        return;
      case SplashRoute.orgSelection:
        context.go('/org-selection');
        return;
      case SplashRoute.schoolSelection:
        context.go(
          '/school-selection',
          extra: <String, dynamic>{
            'selectedOrg': state.schoolSelectionOrgCode,
            'orgFromLoginContext': true,
          },
        );
        return;
      case SplashRoute.dashboardOrDeepLink:
        final deepLink = state.deepLinkLocation;
        if (deepLink != null) {
          await _switchSchoolForLaunch(state.pendingOrgSchool);
          if (!mounted) return;
          _selectDeepLinkChild(deepLink);
        }
        context.go(deepLink ?? DashboardScreen.routeName);
        return;
    }
  }

  /// Points the global child selector at the child a killed-state notification
  /// is about, before routing to its destination.
  ///
  /// The warm paths ([NotificationNavigator] for an FCM tap, the notification
  /// centre for an in-app tap) both already do this; the cold-launch path
  /// routed straight from here and did not, so a guardian with more than one
  /// child who tapped child B's notification from a killed app landed on
  /// whichever child was persisted — the destination URL's `studentCode` was
  /// read only as a remount key and could not correct it.
  ///
  /// The code is read back off the resolved URL rather than the payload:
  /// `NotificationRouteResolver` has already made the decision and written it
  /// there, and by this point the launch message is no longer in hand.
  ///
  /// Guardian persona only, and best-effort — [ParentChildCubit.selectByCode]
  /// filters the code against the authenticated guardian's own children (a
  /// request made before that list is ready is applied once it resolves), so a
  /// stale or forged payload cannot select someone else's child.
  void _selectDeepLinkChild(String deepLink) {
    try {
      if (!context.read<RoleCubit>().isParent) return;
      final code = Uri.parse(deepLink).queryParameters['studentCode']?.trim();
      if (code == null || code.isEmpty) return;
      context.read<ParentChildCubit>().selectByCode(code);
    } catch (e) {
      AppLogger.d('[Splash] launch child-selection skipped (non-fatal): $e');
    }
  }

  /// Switches the active org/school to the killed-state notification's target
  /// (multi-school user) before routing to its deep-link, so the destination
  /// loads the notified school's data. No-op when [orgSchool] is null/empty or
  /// already current.
  Future<void> _switchSchoolForLaunch(Map<String, String>? orgSchool) async {
    if (orgSchool == null) return;
    if (!mounted) return;
    try {
      await switchActiveSchoolIfNeeded(
        context: context,
        organizationCode: orgSchool['organizationCode'],
        schoolCode: orgSchool['schoolCode'],
      );
    } catch (e) {
      AppLogger.d('[Splash] launch school-switch failed (non-fatal): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listenWhen: (previous, current) =>
          current.route != SplashRoute.pending &&
          previous.route != current.route,
      listener: _onRouteChanged,
      child: const SplashScreen(),
    );
  }
}
