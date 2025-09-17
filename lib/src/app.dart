import 'package:flutter/material.dart';
import 'core/Common/app/providers/splash_screen.dart';
import 'core/common/views/page_under_construction.dart';
import 'presentation/features/auth-views/sign_in_screen.dart';
import 'presentation/features/dashboard/admin_dashboard.dart';
import 'presentation/features/on_boarding/presentation/views/onboarding_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return _pageBuilder((_) => const SplashScreen(), settings: settings);

    case '/first-screen':
      return _pageBuilder((_) => const OnboardingScreen(), settings: settings);

    case SignInScreen.routeName:
      return _pageBuilder((_) => const SignInScreen(), settings: settings);

    case AdminDashboard.routeName: // ✅ new case
      return _pageBuilder((_) => const AdminDashboard(), settings: settings);

    default:
      return _pageBuilder(
        (_) => const PageUnderConstruction(),
        settings: settings,
      );
  }
}

PageRouteBuilder<dynamic> _pageBuilder(
  Widget Function(BuildContext) page, {
  required RouteSettings settings,
}) {
  return PageRouteBuilder(
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (context, _, __) => page(context),
    settings: settings,
  );
}
