import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/onboarding/view/onboarding_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';

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
    case StaffScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const StaffScreen(),
        settings: settings,
      );
    case EditImportantDatesScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const EditImportantDatesScreen(),
        settings: settings,
      );
    case EditProfileDetailsScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const EditProfileDetailsScreen(),
        settings: settings,
      );
    case BillingScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const BillingScreen(),
        settings: settings,
      );
    default:
      return MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
        settings: settings,
      );
  }
}


