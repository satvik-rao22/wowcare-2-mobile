import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_item.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/incident_activity.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart'
    show FilterData;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_out_selection_screen.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/availability/view/future_availability_screen.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/billing/cubit/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_info_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/newsletter/view/parent_newsletter_screen.dart';
import 'package:wowcare/presentation/features/newsletter/view/preview_newsletter_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/admin_chat_host_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/open_conversation_screen.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/notifications/cubit/notification_center_cubit.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_center_screen.dart';
import 'package:wowcare/presentation/features/onboarding/view/onboarding_screen.dart';
import 'package:wowcare/presentation/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/scheduling_screen.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/staff_scheduling_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view/staff_scheduling_screen.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/user_profile_screen.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/app/user_persona.dart';
import 'package:wowcare/shared/common/app/providers/splash_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_overview_screen.dart';
import 'package:wowcare/presentation/features/kiosk/view/kiosk_dashboard_screen.dart';
import 'package:wowcare/presentation/features/kiosk/view/logout/kiosk_logout_page.dart';
import 'package:wowcare/presentation/features/kiosk/widgets/kiosk_sign_in_and_sign_out.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';
import 'package:wowcare/core/storage/storage_service.dart';

/// Top-level paths. Kept identical to the old `Screen.routeName` constants so
/// existing call sites that read those constants keep working.
class AppRoutes {
  static const String splash = '/';
  static const String firstScreen = '/first-screen';
  static const String onboarding = '/onboarding';
  static const String signIn = SignInScreen.routeName;
  static const String signOut = SignOutScreen.routeName;
  static const String forgotPassword = ForgotPasswordScreen.routeName;
  static const String orgSelection = '/org-selection';
  static const String schoolSelection = '/school-selection';

  static const String dashboard = DashboardScreen.routeName;
  static const String classroom = ClassroomScreen.routeName;
  static const String activityFeed = ActivityFeedScreen.routeName;
  static const String messaging = MessagingScreen.routeName;
  static const String adminChat = AdminChatHostScreen.routeName;
  static const String openConversation = OpenConversationScreen.routeName;
  static const String parentBilling = ParentBillingScreen.routeName;

  // Notification deep-links for the admin persona: land straight on the
  // specific newsletter / pending-approval activity, not a generic list.
  static const String newsletterPreviewByCode = '/newsletter-preview-by-code';
  static const String activityApprovalByCode = '/activity-approval-by-code';
}

/// Path lookups by branch index — used by the bottom nav when there is no
/// shell in scope (e.g. an auth screen) and for routing fallbacks.
const List<String> branchRootPaths = <String>[
  AppRoutes.dashboard, // 0
  AppRoutes.classroom, // 1
  AppRoutes.activityFeed, // 2
  AppRoutes.messaging, // 3
  AppRoutes.parentBilling, // 4
];

/// Map a bottom-nav [BottomNavigationItem] → shell branch index. `null` means
/// the item is not a branch (Attendance is a modal popup, not a route).
int? branchIndexForItem({
  required bool isParent,
  required BottomNavigationItem item,
}) {
  if (isParent) {
    switch (item) {
      case BottomNavigationItem.dashboard:
        return 0;
      case BottomNavigationItem.attendance:
        return null; // Attendance popup
      case BottomNavigationItem.activities:
        return 2;
      case BottomNavigationItem.communication:
        return 3;
      case BottomNavigationItem.billing:
        return 4;
      case BottomNavigationItem.classrooms:
        return null; // Not a parent tab
    }
  } else {
    switch (item) {
      case BottomNavigationItem.dashboard:
        return 0;
      case BottomNavigationItem.attendance:
        return null; // Attendance popup
      case BottomNavigationItem.classrooms:
        return 1;
      case BottomNavigationItem.activities:
        return 2;
      case BottomNavigationItem.communication:
        return 3;
      case BottomNavigationItem.billing:
        return null; // Not a staff/admin tab
    }
  }
}

/// Reverse of [branchIndexForItem] for highlighting the active tab when the
/// user navigates programmatically or via a deep link.
BottomNavigationItem itemForBranchIndex({
  required bool isParent,
  required int branchIndex,
}) {
  if (isParent) {
    switch (branchIndex) {
      case 2:
        return BottomNavigationItem.activities;
      case 3:
        return BottomNavigationItem.communication;
      case 4:
        return BottomNavigationItem.billing;
      default:
        return BottomNavigationItem.dashboard;
    }
  } else {
    switch (branchIndex) {
      case 1:
        return BottomNavigationItem.classrooms;
      case 2:
        return BottomNavigationItem.activities;
      case 3:
        return BottomNavigationItem.communication;
      default:
        return BottomNavigationItem.dashboard;
    }
  }
}

/// Stable navigator keys for each shell branch.
///
/// These MUST be declared outside [appRouter] so they survive router rebuilds
/// (hot reload, GoRouter.refresh, etc.). Re-creating them inside the [routes]
/// list on every build gives each branch a new GlobalKey, which confuses
/// Flutter's element lifecycle and triggers the
/// "_elements.contains(element)" assertion.
final _dashboardBranchKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _classroomBranchKey = GlobalKey<NavigatorState>(debugLabel: 'classroom');
final _activityBranchKey = GlobalKey<NavigatorState>(debugLabel: 'activity');
final _messagingBranchKey = GlobalKey<NavigatorState>(debugLabel: 'messaging');
final _billingBranchKey = GlobalKey<NavigatorState>(debugLabel: 'billing');

/// Deep-link captured from a notification that cold-launched the app (killed
/// state). On a killed-state tap the app starts at the splash, which runs an
/// auth check and then navigates to the dashboard — clobbering the deep-link if
/// we `go()` immediately. So [PushNotificationCubit] stashes the destination
/// here (from `getInitialMessage()`) and the splash routes to it instead of the
/// dashboard. Read-once via [consumePendingNotificationDeepLink].
String? pendingNotificationDeepLink;

String? consumePendingNotificationDeepLink() {
  final value = pendingNotificationDeepLink;
  pendingNotificationDeepLink = null;
  return value;
}

/// Org/school of the killed-state notification (when it targets a school other
/// than the last-used one). Captured alongside [pendingNotificationDeepLink] in
/// main() and consumed by the splash, which switches the active school before
/// routing to the deep-link. `{organizationCode, schoolCode}` or null.
Map<String, String>? pendingNotificationOrgSchool;

Map<String, String>? consumePendingNotificationOrgSchool() {
  final value = pendingNotificationOrgSchool;
  pendingNotificationOrgSchool = null;
  return value;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: CoreUtils.rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) async {
    // Log navigation events for debugging
    debugPrint(
      '[GoRouter] Navigating to: ${state.uri.path} (name: ${state.name})',
    );

    // CRITICAL SECURITY: Check if user is in kiosk mode and block non-kiosk routes
    // Use synchronous cache check to avoid race conditions from multiple redirect() calls
    bool isKioskMode = KioskAccessControl.isKioskModeActiveDirect();

    // Fallback: If cache is empty, try async storage check (app startup cold load)
    if (!isKioskMode) {
      try {
        isKioskMode = await serviceLocator<KioskAccessControl>()
            .isKioskModeActive();
      } catch (e) {
        // If KioskAccessControl is not registered, try to create it on demand
        try {
          AppLogger.w(
            '[KioskAccess] KioskAccessControl not in DI, creating on demand',
          );
          final kioskAccess = KioskAccessControl(
            serviceLocator<StorageService>(),
          );
          isKioskMode = await kioskAccess.isKioskModeActive();
        } catch (e2) {
          AppLogger.e('[KioskAccess] Error checking kiosk mode: $e2');
        }
      }
    }

    if (isKioskMode) {
      final currentRoute = state.uri.path;
      final allowed = KioskAccessControl.isRouteAllowedForKiosk(currentRoute);

      AppLogger.d(
        '[KioskAccess] Route check: path=$currentRoute, allowed=$allowed',
      );

      // Allow kiosk routes only
      if (!allowed) {
        AppLogger.d(
          '[KioskAccess] Blocking access to $currentRoute - kiosk user, redirecting to /kiosk',
        );
        return '/kiosk';
      }
    }

    // Billing is persona-split: the admin billing screen has no data for a
    // guardian. Anything that lands a guardian on /dashboard/billing — most
    // notably a notification deep-link resolved before the persona was known
    // (the killed-state launch path bakes its location in `main()`, long before
    // login/school-switch settle the role) — is rewritten to the parent billing
    // screen. Query params (e.g. `highlightCode`) are preserved so the target
    // invoice still flashes.
    if (state.uri.path == BillingScreen.routeName) {
      try {
        if (context.read<RoleCubit>().isParent) {
          final q = state.uri.queryParameters;
          AppLogger.d(
            '[Billing] Guardian on ${state.uri} → redirecting to parent billing',
          );
          return Uri(
            path: AppRoutes.parentBilling,
            queryParameters: q.isEmpty ? null : q,
          ).toString();
        }
      } catch (_) {
        // RoleCubit not reachable/resolved yet — leave routing untouched.
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreenWrapper(),
    ),
    GoRoute(
      path: AppRoutes.firstScreen,
      builder: (context, state) => BlocProvider(
        create: (_) => serviceLocator<OnboardingCubit>(),
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => BlocProvider(
        create: (_) => serviceLocator<OnboardingCubit>(),
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signOut,
      builder: (context, state) => const SignOutScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.orgSelection,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final isSwitchFlow = args?['isSwitchFlow'] as bool? ?? false;
        return OrganizationSelectionScreen(isSwitchFlow: isSwitchFlow);
      },
    ),
    GoRoute(
      path: AppRoutes.schoolSelection,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? const {};
        final rawSchools = args['schoolsForOrg'];
        return SchoolSelectionScreen(
          selectedOrg: args['selectedOrg'] as String? ?? '',
          isSwitchFlow: args['isSwitchFlow'] as bool? ?? false,
          schoolsForOrg: rawSchools is List
              ? rawSchools
                    .whereType<Map>()
                    .map(
                      (m) => m.map(
                        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                      ),
                    )
                    .toList()
              : null,
          orgFromLoginContext: args['orgFromLoginContext'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: ClassroomOverviewScreen.routeName,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final filter = args?['filter'] as String?;
        return ClassroomOverviewScreen(initialStudentFilter: filter);
      },
    ),
    // Notification center (bell-icon inbox). Top-level so it can be pushed as
    // an overlay from any screen's app bar, preserving the back stack. Uses
    // `_fastPage` so the page's route name is the matched location
    // (`/notifications`) — the app bar reads that to avoid pushing a duplicate.
    GoRoute(
      path: NotificationCenterScreen.routeName,
      pageBuilder: (context, state) => _fastPage(
        state,
        // This screen renders outside the nav shell with a plain Scaffold.
        // UnreadBadgeCubit is now provided at the app root (main.dart) so it
        // is always in scope — no per-route instance needed here.
        BlocProvider<NotificationCenterCubit>(
          create: (_) =>
              serviceLocator<NotificationCenterCubit>()..loadInitial(),
          child: const NotificationCenterScreen(),
        ),
      ),
    ),

    // Kiosk dashboard — full-screen tablet UI for school entrance kiosk.
    // Top-level route (outside StatefulShellRoute) so it bypasses the nav shell.
    // REFACTORED: Cubits provided at app root level in main.dart
    // Problem: GoRouter's nested route builders receive context from NavigatorWidget.
    // Solution: Provide cubits at app root (main.dart) instead of route level.
    //           All screens (including nested routes) now have access to shared cubits.
    GoRoute(
      path: KioskDashboardScreen.routeName,
      builder: (context, state) {
        AppLogger.d('[Kiosk] Building kiosk dashboard');
        return const KioskDashboardScreen();
      },
      routes: [
        // Kiosk staff sign-in/out screen (pure kiosk flow)
        // Uses KioskStaffSignScreenV2 which is built specifically for kiosk
        // Does NOT call resolveStaffCodeForLoggedInUser() - uses staffCode from PIN verification

        // Student attendance routes
        GoRoute(
          path: 'student-sign-in',
          builder: (context, state) {
            AppLogger.d('[Kiosk] Building student-sign-in screen');
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final pinValue = extra['pin'] as String?;
            AppLogger.d(
              '[Kiosk] Router received pin=$pinValue (type=${extra['pin'].runtimeType})',
            );
            return StudentSelectionSignInForm(
              allowedStudentCodes: (extra['students'] as List?)
                  ?.map((s) => (s as Map)['studentCode'] as String)
                  .toList(),
              isKiosk: extra['isKiosk'] as bool? ?? false,
              guardianCode: extra['guardianCode'] as String?,
              pin: pinValue,
            );
          },
        ),
        GoRoute(
          path: 'student-sign-out',
          builder: (context, state) {
            AppLogger.d('[Kiosk] Building student-sign-out screen');
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return StudentSelectionSignOutForm(
              allowedStudentCodes: (extra['students'] as List?)
                  ?.map((s) => (s as Map)['studentCode'] as String)
                  .toList(),
              isKiosk: extra['isKiosk'] as bool? ?? false,
              guardianCode: extra['guardianCode'] as String?,
              pin: extra['pin'] as String?,
            );
          },
        ),
        GoRoute(
          path: 'student-sign-in-out',
          builder: (context, state) {
            AppLogger.d('[Kiosk] Building student-sign-in-out screen');
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final signedInCodes =
                (extra['signedInStudents'] as List?)
                    ?.map((s) => (s as Map)['studentCode'] as String)
                    .toList() ??
                [];
            final signedOutCodes =
                (extra['signedOutStudents'] as List?)
                    ?.map((s) => (s as Map)['studentCode'] as String)
                    .toList() ??
                [];
            final guardianCode = extra['guardianCode'] as String?;
            final pin = extra['pin'] as String?;
            return StudentSignInOutSelectionScreen(
              signedInCodes: signedInCodes,
              signedOutCodes: signedOutCodes,
              guardianCode: guardianCode,
              pin: pin,
            );
          },
        ),

        // UNIFIED KIOSK SIGN-IN/SIGN-OUT PAGE
        // Consolidates student selection, sign-in, and sign-out flows
        // Stays within /kiosk context (no navigation to /dashboard)
        GoRoute(
          path: 'student-sign-in-and-sign-out',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final signedInCodes =
                (extra['signedInCodes'] as List?)?.cast<String>() ?? [];
            final signedOutCodes =
                (extra['signedOutCodes'] as List?)?.cast<String>() ?? [];
            final guardianCode = extra['guardianCode'] as String?;
            final pin = extra['pin'] as String?;
            final action = extra['action'] as String? ?? 'selection';

            AppLogger.d(
              '[Kiosk] Routing to unified student-sign-in-and-sign-out: '
              'action=$action, signedIn=${signedInCodes.length}, '
              'signedOut=${signedOutCodes.length}',
            );

            return _fastPage(
              state,
              KioskStudentSignInAndSignOutPage(
                signedInCodes: signedInCodes,
                signedOutCodes: signedOutCodes,
                guardianCode: guardianCode ?? '',
                pin: pin ?? '',
                action: action,
              ),
            );
          },
        ),
        // KIOSK STAFF SIGN-IN FORM
        GoRoute(
          path: 'staff-sign-in',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final isKiosk = extra['isKiosk'] as bool? ?? false;
            final staffCode = extra['staffCode'] as String?;
            final staffName = extra['staffName'] as String?;
            final pin = extra['pin'] as String?;
            AppLogger.d(
              '[Kiosk] Routing to staff-sign-in: isKiosk=$isKiosk, staffCode=$staffCode, staffName=$staffName, pin=${pin?.isNotEmpty ?? false}',
            );
            return _fastPage(
              state,
              StaffSignInForm(
                isKiosk: isKiosk,
                staffCode: staffCode,
                staffName: staffName,
                pin: pin,
              ),
            );
          },
        ),
        // KIOSK STAFF SIGN-OUT FORM
        GoRoute(
          path: 'staff-sign-out',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final isKiosk = extra['isKiosk'] as bool? ?? false;
            final staffCode = extra['staffCode'] as String?;
            final staffName = extra['staffName'] as String?;
            final pin = extra['pin'] as String?;
            AppLogger.d(
              '[Kiosk] Routing to staff-sign-out: isKiosk=$isKiosk, staffCode=$staffCode, staffName=$staffName, pin=${pin?.isNotEmpty ?? false}',
            );
            return _fastPage(
              state,
              StaffSignOutForm(
                isKiosk: isKiosk,
                staffCode: staffCode,
                staffName: staffName,
                pin: pin,
              ),
            );
          },
        ),

        // Kiosk logout confirmation page
        GoRoute(
          path: 'logout',
          pageBuilder: (context, state) {
            AppLogger.d('[Kiosk] Building logout page');
            return _fastPage(state, const KioskLogoutPage());
          },
        ),
      ],
    ),

    // Top-level staff attendance forms (accessible from kiosk context)
    GoRoute(
      path: '/dashboard/staff-sign-in-form',
      pageBuilder: (context, state) {
        final isGps = state.uri.queryParameters['gps'] == '1';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final isKiosk = extra['isKiosk'] as bool? ?? false;
        final staffCode = extra['staffCode'] as String?;
        final staffName = extra['staffName'] as String?;
        final pin = extra['pin'] as String?;
        AppLogger.d(
          '[Router] StaffSignInForm: isKiosk=$isKiosk, staffCode=$staffCode, staffName=$staffName, pin=${pin?.isNotEmpty ?? false}',
        );
        return _fastPage(
          state,
          StaffSignInForm(
            forceSelf: isGps,
            isKiosk: isKiosk,
            staffCode: staffCode,
            staffName: staffName,
            pin: pin,
          ),
        );
      },
    ),
    GoRoute(
      path: '/dashboard/staff-sign-out-form',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final isKiosk = extra['isKiosk'] as bool? ?? false;
        final staffCode = extra['staffCode'] as String?;
        final staffName = extra['staffName'] as String?;
        final pin = extra['pin'] as String?;
        return _fastPage(
          state,
          StaffSignOutForm(
            isKiosk: isKiosk,
            staffCode: staffCode,
            staffName: staffName,
            pin: pin,
          ),
        );
      },
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Expose the shell to descendants. CustomNavigationBar reads it and
        // switches tabs via goBranch — preserving each branch's widget tree
        // and navigation stack instead of rebuilding screens on every tap.
        //
        // _ShellScopeContent is a plain StatelessWidget that renders
        // navigationShell as its child. Wrapping it here (rather than passing
        // navigationShell directly as the InheritedWidget's child) gives the
        // InheritedElement a stable element type to update, avoiding the
        // "_elements.contains(element)" assertion that occurs when a
        // LayoutBuilder inside the shell subtree triggers a layout-phase
        // rebuild and both go_router and _ShellScope try to operate on the
        // same StatefulNavigationShell element in the same frame.
        // System back (Android gesture/button) should behave like the in-app
        // back button, never abruptly close the app from a non-home tab.
        // go_router pops any nested route within the active branch first; only a
        // branch *root* reaches this PopScope. From the dashboard (branch 0)
        // root we let the app exit as usual; from any other tab's root we return
        // to the dashboard instead of closing the app.
        return PopScope(
          canPop: navigationShell.currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            navigationShell.goBranch(0);
          },
          child: _ShellScope(
            shell: navigationShell,
            child: _ShellScopeContent(navigationShell: navigationShell),
          ),
        );
      },
      branches: [
        // Branch 0 — Dashboard with every non-tab destination nested
        // underneath it. Because they're children of /dashboard, calling
        // `context.go('/dashboard/staff')` from `/dashboard/students` REPLACES
        // /students with /staff while keeping /dashboard underneath — the
        // stack stays [Dashboard, drill-down] no matter how many drawer items
        // the user taps in a row. Back from any drill-down always lands on
        // Dashboard. (Sub-drill-downs that need to stack on top of a parent
        // drill-down — e.g. Staff → Edit Profile — still use
        // `context.push(...)` and live as siblings here.)
        StatefulShellBranch(
          navigatorKey: _dashboardBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'staff',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<StaffCubit>(
                          create: (_) =>
                              serviceLocator<StaffCubit>()..loadInitial(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(onlyTypeClassroom: false),
                        ),
                      ],
                      child: StaffScreen(
                        incomingHighlightCode:
                            state.uri.queryParameters['highlightCode'],
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'students',
                  pageBuilder: (context, state) {
                    final args = state.extra as Map<String, dynamic>?;
                    final filter = args?['filter'] as String?;
                    final classrooms = args?['classrooms'] as List<String>?;
                    // Notification deep-link: highlight + scroll to a student.
                    final highlightCode =
                        state.uri.queryParameters['highlightCode'];
                    return _fastPage(
                      state,
                      MultiBlocProvider(
                        providers: [
                          BlocProvider<StudentCubit>(
                            create: (_) =>
                                serviceLocator<StudentCubit>()..loadInitial(),
                          ),
                          BlocProvider<ClassroomCubit>(
                            create: (_) =>
                                serviceLocator<ClassroomCubit>()
                                  ..loadActiveClassrooms(),
                          ),
                        ],
                        child: StudentScreen(
                          incomingStatusFilter: filter,
                          incomingClassroomSelections: classrooms,
                          incomingHighlightCode: highlightCode,
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'billing',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const BillingScreen()),
                ),
                GoRoute(
                  path: 'parent-newsletter',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    BlocProvider<StudentNewslettersCubit>(
                      create: (_) => serviceLocator<StudentNewslettersCubit>(),
                      child: const ParentNewsletterScreen(),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'reports',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const ReportsScreen()),
                ),
                GoRoute(
                  path: 'scheduling',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        // No-pagination staff fetch for the scheduling
                        // feature (status=ACTIVE&status=UPCOMING). Singleton
                        // so AddShift shares the same cached list.
                        BlocProvider<SchedulingStaffListCubit>.value(
                          value: serviceLocator<SchedulingStaffListCubit>()
                            ..load(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(onlyTypeClassroom: false),
                        ),
                      ],
                      child: SchedulingScreen(
                        // `highlightCode` may be a shiftCode (shift deep-link) or
                        // a classroomCode (SHIFT_UNDER_RATIO) — pass to both;
                        // only the matching card flashes. `view=day` forces the
                        // day view; `date=yyyy-MM-dd` jumps to the block's day.
                        highlightShiftCode:
                            state.uri.queryParameters['highlightCode'],
                        highlightClassroomCode:
                            state.uri.queryParameters['highlightCode'],
                        initialDate: _parseYmd(
                          state.uri.queryParameters['date'],
                        ),
                        forceDayView:
                            state.uri.queryParameters['view'] == 'day',
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'staff-scheduling',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        // Singleton scheduling staff list (no pagination).
                        // Provided here so AddShift can read it from context
                        // without triggering another API call.
                        BlocProvider<SchedulingStaffListCubit>.value(
                          value: serviceLocator<SchedulingStaffListCubit>(),
                        ),
                        // `.value` because the cubit is a lazy singleton —
                        // we don't want BlocProvider to close it when the
                        // route is popped. `loadIfNeeded()` runs the visible
                        // load on first entry and a silent background
                        // refresh on subsequent entries (no shimmer flash).
                        BlocProvider<StaffSchedulingCubit>.value(
                          value: serviceLocator<StaffSchedulingCubit>()
                            ..loadIfNeeded(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(onlyTypeClassroom: false),
                        ),
                      ],
                      child: StaffSchedulingScreen(
                        // Shift deep-links (PUBLISH/UPCOMING/EDIT/DELETE_SHIFT):
                        // jump to the shift's day, select its staff, and flash
                        // the shift block (`highlightCode` = shiftCode).
                        initialDate: _parseYmd(
                          state.uri.queryParameters['date'],
                        ),
                        initialStaffCode:
                            state.uri.queryParameters['staffCode'],
                        highlightShiftCode:
                            state.uri.queryParameters['highlightCode'],
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'future-availability',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const FutureAvailabilityScreen()),
                ),
                GoRoute(
                  path: 'individual-movement',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    IndividualMovementScreen(
                      highlightCode: state.uri.queryParameters['highlightCode'],
                      studentCode: state.uri.queryParameters['studentCode'],
                    ),
                  ),
                ),
                GoRoute(
                  path: 'edit-important-dates-screen',
                  pageBuilder: (context, state) {
                    final args = state.extra as Map<String, dynamic>?;
                    final staffCode = args?['staffCode'] as String? ?? '';
                    return _fastPage(
                      state,
                      EditImportantDatesScreen(staffCode: staffCode),
                    );
                  },
                ),
                GoRoute(
                  path: 'edit-profile-details-screen',
                  pageBuilder: (context, state) =>
                      _fastPage(state, _editProfileDetailsScreen(state.extra)),
                ),
                GoRoute(
                  path: 'student-attendance-tabbed-view',
                  pageBuilder: (context, state) {
                    final args = state.extra as Map<String, dynamic>?;
                    final filter = args?['filter'] as String?;
                    final classroomFilter =
                        args?['classroomFilter'] as FilterData?;
                    final initialTabIndex =
                        (args?['initialTabIndex'] as int?) ?? 0;
                    final hasBackButton =
                        args?['hasBackButton'] as bool? ?? false;
                    return _fastPage(
                      state,
                      StudentAttendanceTabbedView(
                        dailyIncomingFilter: filter,
                        classroomFilter: classroomFilter,
                        initialTabIndex: initialTabIndex,
                        highlightCode:
                            state.uri.queryParameters['highlightCode'],
                        hasBackButton: hasBackButton,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'staff-attendance-tabbed-view',
                  pageBuilder: (context, state) {
                    final args = state.extra as Map<String, dynamic>?;
                    final filter = args?['filter'] as String?;
                    final classroomFilter =
                        args?['classroomFilter'] as FilterData?;
                    final initialTabIndex =
                        (args?['initialTabIndex'] as int?) ?? 0;
                    final hasBackButton =
                        args?['hasBackButton'] as bool? ?? false;
                    return _fastPage(
                      state,
                      StaffAttendanceTabbedView(
                        dailyIncomingFilter: filter,
                        classroomFilter: classroomFilter,
                        initialTabIndex: initialTabIndex,
                        hasBackButton: hasBackButton,
                      ),
                    );
                  },
                ),
                // Notification deep-link: open the Classroom Info screen with a
                // classroom pre-selected by code (e.g. RATIO_BREACHED).
                GoRoute(
                  path: 'classroom-info-screen',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    ClassroomInfoScreen(
                      initialClassroomCode:
                          state.uri.queryParameters['classroomCode'],
                    ),
                  ),
                ),
                GoRoute(
                  path: 'userProfile',
                  pageBuilder: (context, state) {
                    final args =
                        state.extra as Map<String, dynamic>? ?? const {};
                    return _fastPage(
                      state,
                      UserProfileScreen(
                        userName: args['userName'] as String? ?? '',
                        userEmail: args['userEmail'] as String? ?? '',
                        userPersona: args['userPersona'] as String? ?? '',
                        staffCode: args['staffCode'] as String?,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'notificationSettings',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const NotificationSettingsScreen()),
                ),
                GoRoute(
                  path: 'student-profile',
                  pageBuilder: (context, state) =>
                      _fastPage(state, _studentProfileScreen(state.extra)),
                ),
                // Notification deep-link: open a student's profile from just a
                // code. The tabs self-load by studentCode, so header fields can
                // start empty and fill in once the profile loads.
                GoRoute(
                  path: 'student-profile-by-code',
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    return _fastPage(
                      state,
                      BlocProvider<ClassroomCubit>(
                        create: (_) =>
                            serviceLocator<ClassroomCubit>()
                              ..loadActiveClassrooms(),
                        child: StudentProfileScreen(
                          studentCode: q['code'],
                          name: '',
                          classroom: '',
                          tags: const <String>[],
                          schedule: const <String>[],
                          sibling: const <String, dynamic>{
                            'name': <dynamic>[],
                            'relation': <dynamic>[],
                            'status': <dynamic>[],
                          },
                          initialTabIndex: int.tryParse(q['tab'] ?? '') ?? 0,
                          initialProfileSubTabIndex:
                              int.tryParse(q['profileTab'] ?? '') ?? 0,
                          initialHealthSubTabIndex:
                              int.tryParse(q['healthTab'] ?? '') ?? 0,
                          highlightCode: q['highlightCode'],
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'staff-profile',
                  pageBuilder: (context, state) =>
                      _fastPage(state, _staffProfileScreen(state.extra)),
                ),
                // Notification deep-link: open a staff profile from just a code.
                GoRoute(
                  path: 'staff-profile-by-code',
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    return _fastPage(
                      state,
                      StaffProfileScreen(
                        staffCode: q['code'] ?? '',
                        name: '',
                        classroom: '',
                        designation: '',
                        phoneNumber: '',
                        initialTabIndex: int.tryParse(q['tab'] ?? '') ?? 0,
                        highlightCode: q['highlightCode'],
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-attendance-profile',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    _studentAttendanceProfileScreen(state.extra),
                  ),
                ),
                GoRoute(
                  path: 'staff-attendance-profile',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    _staffAttendanceProfileScreen(state.extra),
                  ),
                ),
                // Notification deep-link: open a student's attendance profile
                // from just a code (e.g. ATTENDANCE_NOT_MARKED). The screen
                // self-loads its data by studentCode.
                GoRoute(
                  path: 'student-attendance-profile-by-code',
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    return _fastPage(
                      state,
                      StudentAttendanceProfile(
                        studentCode: q['code'] ?? '',
                        studentId: 0,
                        studentName: q['name'] ?? '',
                        roomName: '—',
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'staff-attendance-profile-by-code',
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    return _fastPage(
                      state,
                      StaffAttendanceProfile(
                        staffCode: q['code'] ?? '',
                        staffId: 0,
                        staffName: q['name'] ?? '-',
                        roomName: '-',
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-selection-sign-in-form',
                  pageBuilder: (context, state) {
                    final code =
                        state.uri.queryParameters['studentCode']?.trim() ?? '';
                    final extra = state.extra as Map<String, dynamic>?;
                    final allowed =
                        extra?['allowedStudentCodes'] as List<String>?;
                    final isKiosk = extra?['isKiosk'] as bool? ?? false;
                    final guardianCode = extra?['guardianCode'] as String?;
                    final pin = extra?['pin'] as String?;
                    final isQrScan = extra?['isQrScan'] as bool? ?? false;
                    final qrToken = extra?['qrToken'] as String? ?? '';
                    return _fastPage(
                      state,
                      StudentSelectionSignInForm(
                        preSelectedStudentCode: code.isNotEmpty ? code : null,
                        allowedStudentCodes: allowed,
                        isKiosk: isKiosk,
                        guardianCode: guardianCode,
                        pin: pin,
                        isQrScan: isQrScan,
                        qrToken: qrToken,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-selection-sign-out-form',
                  pageBuilder: (context, state) {
                    final code =
                        state.uri.queryParameters['studentCode']?.trim() ?? '';
                    final extra = state.extra as Map<String, dynamic>?;
                    final allowed =
                        extra?['allowedStudentCodes'] as List<String>?;
                    final isKiosk = extra?['isKiosk'] as bool? ?? false;
                    final guardianCode = extra?['guardianCode'] as String?;
                    final pin = extra?['pin'] as String?;
                    final isQrScan = extra?['isQrScan'] as bool? ?? false;
                    final qrToken = extra?['qrToken'] as String? ?? '';
                    return _fastPage(
                      state,
                      StudentSelectionSignOutForm(
                        preSelectedStudentCode: code.isNotEmpty ? code : null,
                        allowedStudentCodes: allowed,
                        isKiosk: isKiosk,
                        guardianCode: guardianCode,
                        pin: pin,
                        isQrScan: isQrScan,
                        qrToken: qrToken,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-sign-in-out-selection',
                  pageBuilder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final signedInCodes =
                        extra?['signedInCodes'] as List<String>? ?? [];
                    final signedOutCodes =
                        extra?['signedOutCodes'] as List<String>? ?? [];
                    final guardianCode = extra?['guardianCode'] as String?;
                    final pin = extra?['pin'] as String?;
                    final isQrScan = extra?['isQrScan'] as bool? ?? false;
                    final qrToken = extra?['qrToken'] as String? ?? '';
                    return _fastPage(
                      state,
                      StudentSignInOutSelectionScreen(
                        signedInCodes: signedInCodes,
                        signedOutCodes: signedOutCodes,
                        guardianCode: guardianCode,
                        pin: pin,
                        isQrScan: isQrScan,
                        qrToken: qrToken,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 1 — Classrooms (staff/admin only).
        StatefulShellBranch(
          navigatorKey: _classroomBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.classroom,
              builder: (context, state) => ClassroomScreen(
                initialClassroomCode:
                    state.uri.queryParameters['classroomCode'],
                // Assign-to-classroom notifications highlight a row inside a
                // specific tab (0 students, 1 staff, 2 notes).
                initialTabIndex:
                    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
                initialHighlightCode:
                    state.uri.queryParameters['highlightCode'],
              ),
            ),
          ],
        ),

        // Branch 2 — Activities.
        StatefulShellBranch(
          navigatorKey: _activityBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.activityFeed,
              builder: (context, state) {
                final q = state.uri.queryParameters;
                final highlight = (q['highlightCode'] ?? '').trim();
                final date = q['date'] ?? '';
                final room = q['classroomCode'] ?? '';
                final extra = state.extra as Map<String, dynamic>?;
                return ActivityFeedScreen(
                  // The Activities tab lives in an indexed-stack branch and its
                  // Daily tab is keep-alive, so a notification tap into an
                  // already-visited tab reuses the old State — leaving the feed
                  // on the previously selected DAY/room. Keying a deep-link by
                  // its target forces a remount, so initState re-runs and
                  // applies the notification's date, classroom and highlight.
                  // Normal tab navigation carries no highlightCode and keeps a
                  // null key, so ordinary browsing state is preserved.
                  key: highlight.isNotEmpty
                      ? ValueKey('activityFeed-$highlight-$date-$room')
                      : null,
                  highlightCode: q['highlightCode'],
                  highlightDate: DateTime.tryParse(date),
                  // The deep-linked activity's classroom, so the feed opens on
                  // the room that actually contains the card to highlight.
                  highlightClassroomCode: q['classroomCode'],
                  initialTab: q['tab'] == 'custom' ? 1 : 0,
                  initialActivityTypes: q['activityType'] != null ? [q['activityType']!] : null,
                  initialClassrooms: q['classroom'] != null ? [q['classroom']!] : null,
                  resetKey: extra?['timestamp']?.toString(),
                );
              },
            ),
          ],
        ),

        // Branch 3 — Messaging. Persona is derived from RoleCubit so the
        // same branch serves both parent and staff/admin without having to
        // pass arguments through the URL.
        StatefulShellBranch(
          navigatorKey: _messagingBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.messaging,
              builder: (context, state) {
                final isParent = context.read<RoleCubit>().isParent;
                final tab = state.uri.queryParameters['tab']
                    ?.trim()
                    .toLowerCase();
                final initialTabIndex = tab == 'newsletter' ? 1 : 0;
                return MessagingScreen(
                  userPersona: isParent
                      ? UserPersona.parent
                      : UserPersona.admin,
                  initialTabIndex: initialTabIndex,
                );
              },
            ),
          ],
        ),

        // Branch 4 — Parent billing (parent only).
        StatefulShellBranch(
          navigatorKey: _billingBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.parentBilling,
              builder: (context, state) => BlocProvider(
                create: (_) => serviceLocator<ParentBillingCubit>(),
                // Billing notification deep-link: the invoice's card is revealed
                // (page window grown), scrolled to and flashed.
                child: ParentBillingScreen(
                  highlightCode: state.uri.queryParameters['highlightCode'],
                ),
              ),
            ),
          ],
        ),
      ],
    ),

    // Overlay screens pushed over the shell via context.push. Placing them
    // outside StatefulShellRoute means the root navigator owns the page —
    // no bottom nav bar is shown, and there is no duplicate-GlobalKey risk
    // from having multiple sibling roots inside the same ShellBranch.
    GoRoute(
      path: AppRoutes.adminChat,
      builder: (context, state) => const AdminChatHostScreen(),
    ),
    // Deep-link target for a tapped chat push notification: fetches the
    // conversation by code and shows the correct thread.
    GoRoute(
      path: AppRoutes.openConversation,
      builder: (context, state) => OpenConversationScreen(
        conversationCode: state.uri.queryParameters['conversationCode'] ?? '',
        conversationType: state.uri.queryParameters['conversationType'],
      ),
    ),
    // Notification deep-link (admin persona, NEWSLETTER_SENT): open the
    // specific newsletter's preview screen. Self-loads by code.
    GoRoute(
      path: AppRoutes.newsletterPreviewByCode,
      pageBuilder: (context, state) => _fastPage(
        state,
        PreviewNewsletterScreen(
          newsletterCode: state.uri.queryParameters['code'] ?? '',
        ),
      ),
    ),
    // Notification deep-link (admin persona, INCIDENT_APPROVAL_PENDING /
    // INCIDENT_ACKNOWLEDGEMENT_PENDING): open that specific incident directly
    // in the admin approve/reject view. Only `activityCode` is real here — the
    // rest of the placeholder is overwritten once the screen self-loads full
    // detail via GET /api/v2/activities/{code} (same prefetch every edit-mode
    // open already relies on).
    GoRoute(
      path: AppRoutes.activityApprovalByCode,
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fastPage(
          state,
          IncidentActivityScreen(
            isEdit: true,
            activityData: ActivityItem(
              time: '',
              date: '',
              name: '',
              studentList: const <String>[],
              createdBy: '',
              activityCode: q['code'],
              studentCode: q['studentCode'],
            ),
          ),
        );
      },
    ),
  ],
);

Widget _editProfileDetailsScreen(Object? extra) {
  final args = extra as Map<String, dynamic>?;
  List<String>? listArg(String key) {
    final raw = args?[key];
    if (raw is List) return List<String>.from(raw);
    return null;
  }

  Map<String, String>? mapArg(String key) {
    final raw = args?[key];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return null;
  }

  final staffCode =
      args?['staffCode'] as String? ?? args?['userCode'] as String? ?? '';
  return EditProfileDetailsScreen(
    staffCode: staffCode,
    initialFirstName: args?['initialFirstName'] as String?,
    initialLastName: args?['initialLastName'] as String?,
    initialEmail: args?['initialEmail'] as String?,
    initialStatus: args?['initialStatus'] as String?,
    initialDesignation: args?['initialDesignation'] as String?,
    initialAllowedClassrooms: listArg('initialAllowedClassrooms'),
    initialPrimaryClassroom: args?['initialPrimaryClassroom'] as String?,
    initialPhoneNumber: args?['initialPhoneNumber'] as String?,
    initialClassroomNames: listArg('initialClassroomNames'),
    initialClassroomCodeByName: mapArg('initialClassroomCodeByName'),
  );
}

Widget _studentProfileScreen(Object? extra) {
  final args = extra as Map<String, dynamic>? ?? const {};
  return StudentProfileScreen(
    name: args['name'] as String? ?? '',
    classroom: args['classroom'] as String? ?? '',
    tags: args['tags'] ?? const <String, dynamic>{},
    schedule: args['schedule'] ?? const <String, dynamic>{},
    sibling:
        args['sibling'] ??
        const <String, dynamic>{
          'name': <dynamic>[],
          'relation': <dynamic>[],
          'status': <dynamic>[],
        },
    studentCode: args['studentCode'] as String?,
    syncWithParentChildSelection:
        args['syncWithParentChildSelection'] as bool? ?? false,
  );
}

Widget _staffProfileScreen(Object? extra) {
  final args = extra as Map<String, dynamic>? ?? const {};
  return StaffProfileScreen(
    staffCode: args['staffCode'] as String? ?? '',
    name: args['name'] as String? ?? '-',
    classroom: args['classroom'] as String? ?? '-',
    designation: args['designation'] as String? ?? '',
    phoneNumber: args['phoneNumber'] as String? ?? '',
    employmentStatus: args['employmentStatus'] as String?,
  );
}

Widget _studentAttendanceProfileScreen(Object? extra) {
  final args = extra as Map<String, dynamic>? ?? const {};
  return StudentAttendanceProfile(
    studentCode: args['studentCode'] as String? ?? '',
    studentId: args['studentId'] as int? ?? 0,
    studentName: args['studentName'] as String? ?? '',
    studentPhotoUuid: args['studentPhotoUuid'] as String?,
    roomName: args['roomName'] as String? ?? '—',
    isSignedIn: args['isSignedIn'] as bool? ?? false,
    syncWithParentChildSelection:
        args['syncWithParentChildSelection'] as bool? ?? false,
  );
}

Widget _staffAttendanceProfileScreen(Object? extra) {
  final args = extra as Map<String, dynamic>? ?? const {};
  return StaffAttendanceProfile(
    staffCode: args['staffCode'] as String? ?? '',
    staffId: args['staffId'] as int? ?? 0,
    staffName: args['staffName'] as String? ?? '-',
    staffPhotoUuid: args['staffPhotoUuid'] as String?,
    designationName: args['designationName'] as String? ?? '',
    roomName: args['roomName'] as String? ?? '-',
  );
}

/// Snappier page builder for drill-down routes — the default Material
/// transition is ~300 ms which feels sluggish on back; we use a 180 ms slide
/// so push *and* pop animations stay smooth and tight.
Page<dynamic> _fastPage(GoRouterState state, Widget child) {
  // Notification deep-links carry their target in the query string
  // (e.g. `?code=…&highlightCode=…`). go_router's default `state.pageKey` is
  // derived from the route PATH only, so navigating to the same route with a
  // DIFFERENT query reuses the cached screen's State (Navigator calls
  // `didUpdateWidget`, not `initState`) — and screens that load their data in
  // `initState` silently keep showing the first target, ignoring the new
  // deep-link. Key query-carrying pages by their full location so a different
  // query builds a fresh page and re-inits with the notified record. Query-less
  // routes keep the stable per-path key so tab/scroll state survives re-entry.
  final key = state.uri.hasQuery
      ? ValueKey<String>('${state.matchedLocation}?${state.uri.query}')
      : state.pageKey;
  return CustomTransitionPage<dynamic>(
    key: key,
    name: state.matchedLocation,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.04, 0);
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    child: child,
  );
}

/// Parses a `yyyy-MM-dd` (or ISO) query param into a local date, or null.
/// Used by notification deep-links that jump the schedule to a specific day.
DateTime? _parseYmd(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Thin wrapper that renders the [StatefulNavigationShell] as its content.
///
/// Caches the shell widget in state so that layout-phase rebuilds always
/// return the **same** Dart object from [build]. Flutter's [Element.updateChild]
/// fast-paths `child.widget == returnedWidget` → no-op when the reference is
/// identical, which prevents the "[_InactiveElements.remove] element not in
/// inactive set" assertion that fires when a layout-phase [BuildOwner.buildScope]
/// tries to retake a GlobalKey element that is still active.
///
/// When the shell reference genuinely changes (router recreated), we defer the
/// swap to a post-frame callback so it never happens inside a layout pass.
class _ShellScopeContent extends StatefulWidget {
  const _ShellScopeContent({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<_ShellScopeContent> createState() => _ShellScopeContentState();
}

class _ShellScopeContentState extends State<_ShellScopeContent> {
  late StatefulNavigationShell _cachedShell;

  @override
  void initState() {
    super.initState();
    _cachedShell = widget.navigationShell;
  }

  @override
  void didUpdateWidget(covariant _ShellScopeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell != oldWidget.navigationShell) {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _cachedShell = widget.navigationShell;
            });
          }
        });
      } else {
        _cachedShell = widget.navigationShell;
      }
    }
  }

  @override
  Widget build(BuildContext context) => _cachedShell;
}

/// InheritedWidget so CustomNavigationBar can find the
/// StatefulNavigationShell without tab screens having to pass it through.
class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.shell, required super.child});

  final StatefulNavigationShell shell;

  static StatefulNavigationShell? maybeOf(BuildContext context) {
    // Look up the InheritedWidget statically via its Element to avoid
    // registering a reactive dependency. This prevents layout-phase rebuild
    // conflicts when CustomNavigationBar reads the active shell.
    final element = context
        .getElementForInheritedWidgetOfExactType<_ShellScope>();
    if (element == null) return null;
    return (element.widget as _ShellScope).shell;
  }

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      shell.currentIndex != oldWidget.shell.currentIndex;
}

/// Public accessor used by the bottom-nav widget.
StatefulNavigationShell? appNavigationShell(BuildContext context) =>
    _ShellScope.maybeOf(context);
