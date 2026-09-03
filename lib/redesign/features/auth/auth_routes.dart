import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_scanner_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/reset_password_cubit.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/check_email_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/choose_organization_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/choose_school_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/kiosk_choice_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/kiosk_door_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/kiosk_family_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/kiosk_scanner_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/reset_password_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/pages/sign_in_page.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/forgot_password_scope.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/sign_in_scope.dart';

/// M01 Authentication and Kiosk routes.
///
/// Top-level routes, outside the shell: no tab bar anywhere in this module,
/// and the kiosk is a lockdown that the router's own redirect enforces.
/// Absolute paths for navigation live in `AppRoutes`.
///
/// The two `ShellRoute`s are not screens. They hold a wizard's cubit above the
/// steps it spans, which is the one thing a page-level provider cannot do: a
/// cubit created in 1c's page would arrive with 1a's answers already gone.
/// Cubits for single screens are still created in the page.
final List<RouteBase> authRoutes = <RouteBase>[
  ShellRoute(
    builder: (context, state, child) => SignInScope(child: child),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'organization',
            builder: (context, state) => const ChooseOrganizationPage(),
          ),
          GoRoute(
            path: 'school',
            builder: (context, state) => const ChooseSchoolPage(),
          ),
        ],
      ),
    ],
  ),
  ShellRoute(
    builder: (context, state, child) => ForgotPasswordScope(child: child),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'sent',
            builder: (context, state) => const CheckEmailPage(),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.resetPassword,
    builder: (context, state) => BlocProvider<ResetPasswordCubit>(
      create: (_) => redesignLocator<ResetPasswordCubit>(),
      child: const ResetPasswordPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.kiosk,
    builder: (context, state) => BlocProvider<KioskCubit>(
      create: (_) => redesignLocator<KioskCubit>(),
      child: const KioskDoorPage(),
    ),
    routes: <RouteBase>[
      GoRoute(
        path: 'scan',
        builder: (context, state) => BlocProvider<KioskScannerCubit>(
          create: (_) => redesignLocator<KioskScannerCubit>(),
          child: const KioskScannerPage(),
        ),
      ),
      GoRoute(
        path: 'choice',
        builder: (context, state) =>
            KioskChoicePage(result: state.extra! as KioskPinResult),
      ),
      GoRoute(
        path: 'family',
        builder: (context, state) =>
            KioskFamilyPage(args: state.extra! as KioskFamilyArgs),
      ),
    ],
  ),
];
