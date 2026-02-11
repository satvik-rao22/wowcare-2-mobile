import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/onboarding/view/onboarding_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/view/role_selection_screen.dart';

import '../presentation/features/activities/view/activity_feed_screen.dart';
import '../presentation/features/students/view/student_screen.dart';
import '../app/di/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/features/staff/cubit/staff_cubit.dart';
import '../presentation/features/classroom/cubit/classroom_cubit.dart';
import '../presentation/features/student/cubit/student_cubit.dart';

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
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<StaffCubit>(
              create: (_) => serviceLocator<StaffCubit>()..loadInitial(),
            ),
            BlocProvider<ClassroomCubit>(
              create: (_) => serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
            ),
          ],
          child: const StaffScreen(),
        ),
        settings: settings,
      );
    case EditImportantDatesScreen.routeName:
      // Get staffCode from route arguments
      final args = settings.arguments as Map<String, dynamic>?;
      final staffCode = args?['staffCode'] as String? ?? '';
      return MaterialPageRoute(
        builder: (_) => EditImportantDatesScreen(
          staffCode: staffCode,
        ),
        settings: settings,
      );
    case EditProfileDetailsScreen.routeName:
      // Optional navigation via named route; expects a staffCode in arguments.
      final args = settings.arguments as Map<String, dynamic>?;
      final staffCode = args?['staffCode'] as String? ?? '';
      return MaterialPageRoute(
        builder: (_) => EditProfileDetailsScreen(
          staffCode: staffCode,
        ),
        settings: settings,
      );
    case BillingScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const BillingScreen(),
        settings: settings,
      );
    case ParentBillingScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const ParentBillingScreen(),
        settings: settings,
      );
    case ActivityFeedScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const ActivityFeedScreen(),
        settings: settings,
      );
    case StudentScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<StudentCubit>(
              create: (_) => serviceLocator<StudentCubit>()..loadInitial(),
            ),
            BlocProvider<ClassroomCubit>(
              create: (_) =>
                  serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
            ),
          ],
          child: const StudentScreen(),
        ),
        settings: settings,
      );
    case SignInScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const SignInScreen(),
        settings: settings,
      );
    case SignOutScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const SignOutScreen(),
        settings: settings,
      );
    case ForgotPasswordScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
        settings: settings,
      );
    case RoleSelectionScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const RoleSelectionScreen(),
        settings: settings,
      );
    default:
      return MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
        settings: settings,
      );
  }
}


