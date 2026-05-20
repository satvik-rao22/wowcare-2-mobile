import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/availability/view/future_availability_screen.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/onboarding/view/onboarding_screen.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/scheduling_screen.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/staff_scheduling_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view/staff_scheduling_screen.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/user_profile_screen.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/app/providers/splash_screen.dart';

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
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
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
                      (k, v) =>
                          MapEntry(k.toString(), v?.toString() ?? ''),
                    ),
                  )
                  .toList()
              : null,
          orgFromLoginContext:
              args['orgFromLoginContext'] as bool? ?? false,
        );
      },
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Expose the shell to descendants. CustomNavigationBar reads it and
        // switches tabs via goBranch — preserving each branch's widget tree
        // and navigation stack instead of rebuilding screens on every tap.
        return _ShellScope(shell: navigationShell, child: navigationShell);
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
                            ..loadActiveClassrooms(
                              onlyTypeClassroom: false,
                            ),
                        ),
                      ],
                      child: const StaffScreen(),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'students',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<StudentCubit>(
                          create: (_) =>
                              serviceLocator<StudentCubit>()..loadInitial(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(),
                        ),
                      ],
                      child: const StudentScreen(),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'billing',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const BillingScreen()),
                ),
                GoRoute(
                  path: 'scheduling',
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
                            ..loadActiveClassrooms(
                              onlyTypeClassroom: false,
                            ),
                        ),
                      ],
                      child: const SchedulingScreen(),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'staff-scheduling',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<StaffSchedulingCubit>(
                          create: (_) =>
                              serviceLocator<StaffSchedulingCubit>()
                                ..loadInitial(),
                        ),
                        BlocProvider<StaffCubit>(
                          create: (_) =>
                              serviceLocator<StaffCubit>()..loadInitial(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(
                              onlyTypeClassroom: false,
                            ),
                        ),
                      ],
                      child: const StaffSchedulingScreen(),
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
                  pageBuilder: (context, state) =>
                      _fastPage(state, const IndividualMovementScreen()),
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
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    _editProfileDetailsScreen(state.extra),
                  ),
                ),
                GoRoute(
                  path: 'student-attendance-tabbed-view',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    const StudentAttendanceTabbedView(),
                  ),
                ),
                GoRoute(
                  path: 'staff-attendance-tabbed-view',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    const StaffAttendanceTabbedView(),
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
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    _studentProfileScreen(state.extra),
                  ),
                ),
                GoRoute(
                  path: 'staff-profile',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    _staffProfileScreen(state.extra),
                  ),
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
              ],
            ),
          ],
        ),

        // Branch 1 — Classrooms (staff/admin only).
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.classroom,
              builder: (context, state) => const ClassroomScreen(),
            ),
          ],
        ),

        // Branch 2 — Activities.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.activityFeed,
              builder: (context, state) => const ActivityFeedScreen(),
            ),
          ],
        ),

        // Branch 3 — Messaging. Persona is derived from RoleProvider so the
        // same branch serves both parent and staff/admin without having to
        // pass arguments through the URL.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.messaging,
              builder: (context, state) {
                final isParent = context.read<RoleProvider>().isParent;
                return MessagingScreen(
                  userPersona:
                      isParent ? UserPersona.parent : UserPersona.admin,
                );
              },
            ),
          ],
        ),

        // Branch 4 — Parent billing (parent only).
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.parentBilling,
              builder: (context, state) => const ParentBillingScreen(),
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
    sibling: args['sibling'] ?? const <String, dynamic>{
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
Page<dynamic> _fastPage(
  GoRouterState state,
  Widget child,
) {
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
        position: Tween<Offset>(begin: begin, end: Offset.zero)
            .animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    child: child,
  );
}

/// InheritedWidget so CustomNavigationBar can find the
/// StatefulNavigationShell without tab screens having to pass it through.
class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.shell, required super.child});

  final StatefulNavigationShell shell;

  static StatefulNavigationShell? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShellScope>()
        ?.shell;
  }

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      shell.currentIndex != oldWidget.shell.currentIndex;
}

/// Public accessor used by the bottom-nav widget.
StatefulNavigationShell? appNavigationShell(BuildContext context) =>
    _ShellScope.maybeOf(context);
