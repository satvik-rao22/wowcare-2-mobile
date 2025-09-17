import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/onboarding/view/onboarding_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';

class AppRoutes {
  static const String firstScreen = '/first-screen';
  static const String onboarding = '/onboarding';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.firstScreen:
    case AppRoutes.onboarding:
      return MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
        settings: settings,
      );
    case DashboardScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
        settings: settings,
      );
    default:
      return MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
        settings: settings,
      );
  }
}


