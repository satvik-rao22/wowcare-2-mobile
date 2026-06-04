import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart' show FilterData;
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
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_newsletter_screen.dart';
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
import 'package:wowcare/shared/common/app/providers/splash_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_overview_screen.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/view/kiosk_dashboard_screen.dart';
import 'package:wowcare/presentation/features/kiosk/view/kiosk_staff_sign_form.dart';

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
  static const String parentBilling = ParentBillingScreen.routeName;
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

/// Map a visual nav-bar tab index → shell branch index. `null` means the tab
/// is not a branch (e.g. staff/parent index 1 just opens the Attendance popup).
int? navBranchIndexForTab({required bool isParent, required int tabIndex}) {
  if (isParent) {
    switch (tabIndex) {
      case 0:
        return 0; // Dashboard
      case 1:
        return null; // Attendance popup
      case 2:
        return 2; // Activities
      case 3:
        return 3; // Messages
      case 4:
        return 4; // Billing
    }
  } else {
    switch (tabIndex) {
      case 0:
        return 0; // Dashboard
      case 1:
        return null; // Attendance popup
      case 2:
        return 1; // Classrooms
      case 3:
        return 2; // Activities
      case 4:
        return 3; // Messages
    }
  }
  return null;
}

/// Reverse of [navBranchIndexForTab] for highlighting the active tab when
/// the user navigates programmatically or via a deep link.
int tabIndexForBranchIndex({required bool isParent, required int branchIndex}) {
  if (isParent) {
    switch (branchIndex) {
      case 0:
        return 0;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 4;
    }
  } else {
    switch (branchIndex) {
      case 0:
        return 0;
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
    }
  }
  return 0;
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
final _activityBranchKey  = GlobalKey<NavigatorState>(debugLabel: 'activity');
final _messagingBranchKey = GlobalKey<NavigatorState>(debugLabel: 'messaging');
final _billingBranchKey   = GlobalKey<NavigatorState>(debugLabel: 'billing');

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

final GoRouter appRouter = GoRouter(
  navigatorKey: CoreUtils.rootNavigatorKey,
  initialLocation: AppRoutes.splash,
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
        BlocProvider<NotificationCenterCubit>(
          create: (_) =>
              serviceLocator<NotificationCenterCubit>()..loadInitial(),
          child: const NotificationCenterScreen(),
        ),
      ),
    ),

    // Kiosk dashboard — full-screen tablet UI for school entrance kiosk.
    // Top-level route (outside StatefulShellRoute) so it bypasses the nav shell.
    // BlocProvider wraps the screen so KioskDashboardCubit is available before build().
    GoRoute(
      path: KioskDashboardScreen.routeName,
      builder: (context, state) => BlocProvider<KioskDashboardCubit>(
        create: (_) => serviceLocator<KioskDashboardCubit>(),
        child: const KioskDashboardScreen(),
      ),
      routes: [
        // Kiosk staff sign-in/out form
        GoRoute(
          path: 'staff-sign',
          pageBuilder: (context, state) => _fastPage(
            state,
            const KioskStaffSignForm(),
          ),
        ),

        // Student attendance routes
        GoRoute(
          path: 'student-sign-in',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return _fastPage(
              state,
              StudentSelectionSignInForm(
                allowedStudentCodes: (extra['students'] as List?)
                    ?.map((s) => (s as Map)['studentCode'] as String)
                    .toList(),
              ),
            );
          },
        ),
        GoRoute(
          path: 'student-sign-out',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return _fastPage(
              state,
              StudentSelectionSignOutForm(
                allowedStudentCodes: (extra['students'] as List?)
                    ?.map((s) => (s as Map)['studentCode'] as String)
                    .toList(),
              ),
            );
          },
        ),
        GoRoute(
          path: 'student-sign-in-out',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final signedInCodes = (extra['signedInStudents'] as List?)
                ?.map((s) => (s as Map)['studentCode'] as String)
                .toList() ?? [];
            final signedOutCodes = (extra['signedOutStudents'] as List?)
                ?.map((s) => (s as Map)['studentCode'] as String)
                .toList() ?? [];
            return _fastPage(
              state,
              StudentSignInOutSelectionScreen(
                signedInCodes: signedInCodes,
                signedOutCodes: signedOutCodes,
              ),
            );
          },
        ),
      ],
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
        return _ShellScope(
          shell: navigationShell,
          child: _ShellScopeContent(navigationShell: navigationShell),
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
                            state.uri.queryParameters['date']),
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
                            state.uri.queryParameters['date']),
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
                      highlightCode:
                          state.uri.queryParameters['highlightCode'],
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
                    final hasBackButton = args?['hasBackButton'] as bool? ?? false;
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
                    final hasBackButton = args?['hasBackButton'] as bool? ?? false;
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
                        create: (_) => serviceLocator<ClassroomCubit>()
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
                          initialTabIndex:
                              int.tryParse(q['tab'] ?? '') ?? 0,
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
                    final code = state.uri.queryParameters['studentCode']?.trim() ?? '';
                    final extra = state.extra as Map<String, dynamic>?;
                    final allowed = extra?['allowedStudentCodes'] as List<String>?;
                    return _fastPage(
                      state,
                      StudentSelectionSignInForm(
                        preSelectedStudentCode: code.isNotEmpty ? code : null,
                        allowedStudentCodes: allowed,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-selection-sign-out-form',
                  pageBuilder: (context, state) {
                    final code = state.uri.queryParameters['studentCode']?.trim() ?? '';
                    final extra = state.extra as Map<String, dynamic>?;
                    final allowed = extra?['allowedStudentCodes'] as List<String>?;
                    return _fastPage(
                      state,
                      StudentSelectionSignOutForm(
                        preSelectedStudentCode: code.isNotEmpty ? code : null,
                        allowedStudentCodes: allowed,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-sign-in-out-selection',
                  pageBuilder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final signedInCodes = extra?['signedInCodes'] as List<String>? ?? [];
                    final signedOutCodes = extra?['signedOutCodes'] as List<String>? ?? [];
                    return _fastPage(
                      state,
                      StudentSignInOutSelectionScreen(
                        signedInCodes: signedInCodes,
                        signedOutCodes: signedOutCodes,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'staff-sign-in-form',
                  pageBuilder: (context, state) {
                    final isGps = state.uri.queryParameters['gps'] == '1';
                    return _fastPage(
                      state,
                      StaffSignInForm(forceSelf: isGps),
                    );
                  },
                ),
                GoRoute(
                  path: 'staff-sign-out-form',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const StaffSignOutForm()),
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
              builder: (context, state) => ActivityFeedScreen(
                highlightCode: state.uri.queryParameters['highlightCode'],
                highlightDate: DateTime.tryParse(
                  state.uri.queryParameters['date'] ?? '',
                ),
              ),
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
                final tab = state.uri.queryParameters['tab']?.trim().toLowerCase();
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
                child: const ParentBillingScreen(),
              ),
            ),
          ],
        ),
      ],
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
  return CustomTransitionPage<dynamic>(
    key: state.pageKey,
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
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
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
    final element = context.getElementForInheritedWidgetOfExactType<_ShellScope>();
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
