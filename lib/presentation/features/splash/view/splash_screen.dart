import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/active_school_switcher.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/splash/cubit/splash_cubit.dart';
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
/// selection, or the dashboard. Lives in the router as the "/" route.
///
/// Pure View: all the decision logic (onboarding/session/kiosk/deep-link
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
      case SplashRoute.firstScreen:
        context.go('/first-screen');
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
        }
        context.go(deepLink ?? DashboardScreen.routeName);
        return;
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
