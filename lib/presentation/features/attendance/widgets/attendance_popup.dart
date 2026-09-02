import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/src/app_router.dart' show dashboardBranchKey;
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/cubit/student_attendance_profile_fetch_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_profile_fetch_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/core/util/server_time_service.dart';

/// Resolves the parent persona's selected child and builds the
/// [StudentAttendanceProfile] widget to open for them — shared by
/// [AttendancePopupManager.openParentChildAttendance] and
/// [_AttendancePopupOverlayState._openParentStudentAttendanceProfile], which
/// differ only in how they navigate to the result (a fade route into the
/// dashboard branch navigator vs. a plain `Navigator.push` — both documented
/// GoRouter holdouts, kept in each call site).
///
/// Shows the appropriate error snackbar and returns null if a profile can't
/// be built (no child linked, or resolution failed) — the caller should
/// just skip navigation when this returns null.
Future<Widget?> buildParentChildAttendanceProfile(BuildContext context) async {
  try {
    final parentChild = context.read<ParentChildCubit>();
    await parentChild.ensureLoaded();

    final selectedChild = parentChild.selectedChild;
    if (selectedChild == null || selectedChild.code.trim().isEmpty) {
      if (!context.mounted) return null;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No child linked to this parent account.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return null;
    }

    String roomName = selectedChild.classroom.trim().isNotEmpty
        ? selectedChild.classroom
        : '—';
    var isSignedIn = false;

    try {
      final fetchCubit = serviceLocator<StudentAttendanceProfileFetchCubit>();
      final now = ServerTimeService.instance.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final page = await fetchCubit.fetchSignOutFormList(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        page: 0,
        size: 200,
      );
      final match = page.items.where(
        (i) => i.studentCode.trim() == selectedChild.code.trim(),
      );
      if (match.isNotEmpty) {
        final row = match.first;
        roomName = row.classroomName.trim().isNotEmpty
            ? row.classroomName
            : roomName;
        isSignedIn = row.hasSignIn && !row.hasSignOut;
      }
    } catch (_) {
      // Parents may not have sign-out form list access — keep defaults.
    }

    return StudentAttendanceProfile(
      studentCode: selectedChild.code.trim(),
      studentId: 0,
      studentName: selectedChild.name,
      studentPhotoUuid: null,
      roomName: roomName,
      isSignedIn: isSignedIn,
      syncWithParentChildSelection: true,
    );
  } catch (_) {
    if (!context.mounted) return null;
    CoreUtils.showTopSnackBarFromSnackBar(
      context: context,
      snackBar: const SnackBar(
        content: Text('Unable to open child attendance profile.'),
        backgroundColor: AppColors.errorColor,
      ),
    );
    return null;
  }
}

class AttendancePopupManager {
  // Guards against the bottom-nav Attendance tab being tapped multiple times
  // in quick succession: without this, each tap re-enters this method before
  // the previous popup/profile push has finished, stacking duplicates.
  // Cleared once the in-flight popup/navigation settles.
  static bool _isOpening = false;

  static void showAttendancePopup(
    BuildContext context, {
    int initialTabIndex = 0,
  }) {
    if (_isOpening) return;
    _isOpening = true;

    // Parent / guardian: skip the bottom-sheet popup entirely and open the
    // child's attendance profile directly. The popup is only needed for
    // staff/admin who have both Student and Staff attendance tabs.
    final isParent = context.read<RoleCubit>().isParent;
    if (isParent) {
      unawaited(
        openParentChildAttendance(
          context,
        ).whenComplete(() => _isOpening = false),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: AppColors.attendancePopupBarrierColor,
      barrierDismissible: true,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider<RoleCubit>.value(value: context.read<RoleCubit>()),
          BlocProvider<GeofenceCubit>.value(
            value: context.read<GeofenceCubit>(),
          ),
        ],
        child: AttendancePopupOverlay(initialTabIndex: initialTabIndex),
      ),
    ).whenComplete(() => _isOpening = false);
  }

  /// Opens the selected child's attendance profile directly.
  /// Used when parent/guardian taps the Attendance nav tab — bypasses the popup.
  /// Safe to call repeatedly: if the profile is already on top of the stack,
  /// it pops back to it instead of pushing a duplicate.
  static Future<void> openParentChildAttendance(BuildContext context) async {
    // Push onto the Dashboard branch's OWN stable navigator
    // (dashboardBranchKey), never `Navigator.of(context)`. BottomNavigationCubit
    // is a single app-wide singleton, and StatefulShellRoute.indexedStack keeps
    // EVERY visited branch's screens (and their own GlobalScaffold ->
    // CustomNavigationBar -> BlocListener<BottomNavigationCubit>) alive even
    // while hidden — so a single Attendance tap can fire this method more than
    // once in the same frame, each time via a DIFFERENT branch's context. Using
    // that ambient context's Navigator meant the profile could land on
    // whichever branch's (possibly hidden) navigator happened to handle the
    // event first — an essentially arbitrary choice from the user's
    // perspective — which is what made it look like "a different screen" opened
    // (it opened on the RIGHT branch some taps and a WRONG, invisible one on
    // others). Targeting dashboardBranchKey directly makes the destination
    // deterministic regardless of which context triggered this.
    final navigatorState = dashboardBranchKey.currentState;
    if (navigatorState == null) return;

    // If the profile screen is already on the stack (possibly with a
    // sign-in/out form or other sub-screen pushed on top of it), pop back
    // down to it instead of stacking a second copy. The predicate used to
    // unconditionally `return true`, which made popUntil stop at the very
    // first route it inspected (whatever was already on top) without ever
    // popping anything — so a form pushed on top of the profile hid it from
    // this check, and every repeat tap on the Attendance nav item pushed
    // ANOTHER fresh profile on top, stacking duplicates (each re-fetching
    // isSignedIn/roomName, so they could show different values from one
    // another).
    bool alreadyOnProfile = false;
    navigatorState.popUntil((route) {
      if (route.settings.name == StudentAttendanceProfile.routeName) {
        alreadyOnProfile = true;
        return true; // found it — stop popping, leave it on top
      }
      // Not the profile: keep popping through it, but never past the
      // bottom of the stack (isFirst) if the profile isn't there at all.
      return route.isFirst;
    });
    if (alreadyOnProfile) return;

    try {
      final profile = await buildParentChildAttendanceProfile(context);
      if (profile == null) return;

      if (!context.mounted) return;
      // Reached from the bottom nav — every OTHER nav item (Dashboard,
      // Activities, Communication, Billing) switches via shell.goBranch(),
      // an instant IndexedStack swap with no page-transition animation at
      // all. Attendance can't be a real branch (it's a modal-style
      // destination, not a persistent tab), but the default MaterialPageRoute
      // slide-from-right made it visibly stand out as "a different page was
      // pushed" instead of feeling like just another tab. A quick fade reads
      // much closer to a tab swap than a slide does.
      // GoRouter holdout (documented): deliberate deterministic branch-navigator / fade / dedup flow (see app_router.dart popAllShellBranchNavigators docs) — kept imperative.
      navigatorState.push(
        _fadeRoute(
          settings: const RouteSettings(
            name: StudentAttendanceProfile.routeName,
          ),
          builder: (_) => profile,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Unable to open child attendance profile.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}

/// A quick cross-fade instead of the platform's default slide-from-right —
/// used where a pushed route conceptually stands in for a bottom-nav tab
/// (see [AttendancePopupManager.openParentChildAttendance]'s call site) so it
/// doesn't visually read as "a different page" the way a slide transition
/// does.
PageRouteBuilder<T> _fadeRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

// ── Old parent-only tab code commented out ──────────────────────────────────
// Previously AttendancePopupOverlay showed a single "Student Attendance" tab
// for parent/guardian. That tab is now unused for parents because
// showAttendancePopup() short-circuits to openParentChildAttendance() instead.
// The TabController length / tab rendering below still guards on isParent but
// the parent code-path is never reached at runtime.
// ─────────────────────────────────────────────────────────────────────────────

class AttendancePopupOverlay extends StatefulWidget {
  const AttendancePopupOverlay({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<AttendancePopupOverlay> createState() => _AttendancePopupOverlayState();
}

class _AttendancePopupOverlayState extends State<AttendancePopupOverlay>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final StaffAttendanceProfileFetchCubit _profileFetchCubit =
      serviceLocator<StaffAttendanceProfileFetchCubit>();
  bool _isParentRole = false;
  bool?
  _isTeacherStaffPersona; // When true: skip staff selection and use self forms.
  String _loggedInStaffCode = '';
  String? _lastSeenRole;

  // Today's self-attendance status for the logged-in staff persona, used
  // (alongside geofencing) to gate Sign-In/Sign-Out/Transfer/Mark-Absent in
  // the "My Attendance" tab. Not used for the admin staff-selection flow.
  String? _todayStatusRaw;
  // Starts true (rather than false) so Sign-In/Sign-Out/Transfer/Mark-Absent
  // in the "My Attendance" tab render disabled until the real today-status
  // has been fetched. Defaulting to false let the gate fall back to its
  // "not signed in" assumption (which enables Sign-In + Mark-Absent) during
  // the fetch window right after the popup opens, so an already-signed-in
  // staff member briefly saw those actions as tappable.
  bool _isTodayStatusLoading = true;

  StaffAttendanceGate get _todayGate => staffAttendanceGateFromTodayStatus(
    isActiveProfile: true,
    todayStatusRaw: _todayStatusRaw,
  );

  @override
  void initState() {
    super.initState();
    _isParentRole = context.read<RoleCubit>().isParent;
    _tabController = TabController(
      length: _isParentRole ? 1 : 2,
      vsync: this,
      initialIndex: _isParentRole ? 0 : widget.initialTabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _syncPersonaFlags();
    // The student-attendance actions are gated on the staff being signed in, so
    // refresh that status when the popup opens (the shared GeofenceCubit may be
    // stale, e.g. the user came straight here without the dashboard refreshing).
    if (!context.read<RoleCubit>().isParent) {
      unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
      _resolveCrossClassPermission();
    }
  }

  /// Resolves the school's `allowTeacherCrossClassAttendance` flag so the
  /// permission gate (which reads it synchronously) reflects the active school.
  /// Rebuilds once resolved so the student-attendance actions enable when a
  /// teacher is allowed cross-class access, exactly like an admin.
  Future<void> _resolveCrossClassPermission() async {
    try {
      await AttendanceCrossClassResolver.isEnabledForCurrentSchool(
        storage: serviceLocator<StorageService>(),
      );
      if (mounted) setState(() {});
    } catch (_) {
      // Non-critical: falls back to the signed-in gate.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = context.watch<RoleCubit>().role;
    if (_lastSeenRole != role) {
      _lastSeenRole = role;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncPersonaFlags();
      });
    }
  }

  Future<void> _syncPersonaFlags() async {
    final resolvedParentRole = await _resolveIsParentSession();
    if (!mounted) return;

    if (resolvedParentRole != _isParentRole) {
      _isParentRole = resolvedParentRole;
      _replaceTabController(length: _isParentRole ? 1 : 2, initialIndex: 0);
      setState(() {});
    }

    if (!_isParentRole) {
      await _loadStaffPersonaFlags();
    }
  }

  void _replaceTabController({required int length, required int initialIndex}) {
    final previousController = _tabController;
    final nextIndex = initialIndex.clamp(0, length - 1);
    final nextController = TabController(
      length: length,
      vsync: this,
      initialIndex: nextIndex,
    );
    nextController.addListener(_onTabChanged);
    _tabController = nextController;

    previousController.removeListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousController.dispose();
    });
  }

  Future<bool> _resolveIsParentSession() async {
    try {
      final storage = serviceLocator<StorageService>();
      // IMPORTANT:
      // For multi-role users (e.g. ADMIN + GUARDIAN), we must respect the
      // *active* persona selected via switch-profile, not just the presence of
      // any guardian role in the account.
      final activeRole =
          (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
      if (activeRole.isNotEmpty) {
        final upper = activeRole.toUpperCase();
        return upper.contains('PARENT') || upper.contains('GUARDIAN');
      }
    } catch (_) {
      // Keep default false when session metadata is unavailable.
    }

    // Fallback to provider role (already reflects active persona).
    return context.read<RoleCubit>().isParent;
  }

  Future<void> _loadStaffPersonaFlags() async {
    try {
      // "My Attendance" (self) vs "Staff Attendance" (manage all) follows the
      // ACTIVE persona: only the staff (teacher) persona sees "My Attendance";
      // the admin persona manages all staff and reaches its own record from the
      // bottom-nav Staff Attendance instead.
      //
      // staffType was unreliable here — it is only written after a later
      // profile/attendance refresh, so an admin whose staffType had not loaded
      // yet fell through to `!isStaffAdmin == true` and was wrongly shown
      // "My Attendance". RoleCubit's active persona ('staff' vs 'admin') is the
      // canonical, persona-switch-aware signal, so key off it directly.
      final isStaffPersona = context.read<RoleCubit>().isStaff;

      final storage = serviceLocator<StorageService>();
      var staffCode = (await storage.getString(StorageKeys.staffCode) ?? '')
          .trim();
      if (staffCode.isEmpty) {
        staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      }

      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = staffCode;
        _isTeacherStaffPersona = isStaffPersona && staffCode.isNotEmpty;
      });

      if (isStaffPersona && staffCode.isNotEmpty) {
        unawaited(_loadTodayStatus(staffCode));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = '';
        _isTeacherStaffPersona = false;
      });
    }
  }

  Future<void> _loadTodayStatus(String staffCode) async {
    if (!mounted) return;
    setState(() {
      _isTodayStatusLoading = true;
    });
    try {
      final status = await _profileFetchCubit.fetchTodayStatus(
        staffCode: staffCode,
      );
      if (!mounted) return;
      setState(() {
        _todayStatusRaw = status;
        _isTodayStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todayStatusRaw = null;
        _isTodayStatusLoading = false;
      });
    }
  }

  void _onTabChanged() {
    setState(() {
      // Rebuild to adjust height based on current tab
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleCubit>();
    // Watch the geofence cubit so the student-attendance buttons re-enable as
    // soon as the staff sign-in status resolves (they gate on isStaffSignedIn).
    context.watch<GeofenceCubit>();
    final isAdmin = roleProvider.isAdmin && !_isParentRole;
    final isParent = _isParentRole;
    final isTeacherPersona = _isTeacherStaffPersona == true;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = ResponsiveHelper(context).screenHeight;
    final screenWidth = ResponsiveHelper(context).screenWidth;
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final navBarHeight = CustomNavigationBar.navBarHeight;
    // Use a default height if navBarHeight hasn't been measured yet
    final effectiveNavBarHeight = navBarHeight > 0 ? navBarHeight : 80.0;
    final safeAreaBottom = mediaQuery.padding.bottom;

    // Calculate spacing between popup and navigation bar
    final spacingFromNavBar = 10.0;
    final bottomPadding =
        effectiveNavBarHeight + safeAreaBottom + spacingFromNavBar;
    final maxPopupHeight = (screenHeight * 0.45).clamp(140.0, 350.0);

    return Dialog(
      backgroundColor: AppColors.transparentColor,
      elevation: 0,
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.only(
        left: isTablet ? 24 : 12,
        right: isTablet ? 24 : 12,
        bottom: bottomPadding,
      ),
      child: Material(
        color: AppColors.cardColor,
        borderRadius: AppRadius.allLg,
        elevation: 4,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxPopupHeight,
            maxWidth: isTablet ? 600 : screenWidth - 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: isTablet ? 56 : 50,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: AppColors.themeColor,
                      width: 1.2,
                    ),
                  ),
                  indicatorPadding: EdgeInsets.only(bottom: isTablet ? 10 : 8),
                  labelPadding: EdgeInsets.zero,
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 8),
                  labelStyle: TextStyle(
                    color: AppColors.attendanceIconColor,
                    fontFamily: Fonts.manrope,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                  unselectedLabelStyle: TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                    fontFamily: Fonts.manrope,
                    fontSize: isTablet ? 18 : 16,
                  ),
                  tabs: isParent
                      ? const [Tab(text: 'Student Attendance')]
                      : [
                          const Tab(text: 'Student Attendance'),
                          Tab(
                            text: isTeacherPersona
                                ? 'My Attendance'
                                : 'Staff Attendance',
                          ),
                        ],
                ),
              ),
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: _getTabHeight(
                        isAdmin: isAdmin,
                        isParent: isParent,
                        isTablet: isTablet,
                        maxAvailableHeight: constraints.maxHeight,
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: isParent
                            ? [
                                _buildStudentAttendanceTab(
                                  context,
                                  isAdmin,
                                  isParent,
                                  isTablet,
                                ),
                              ]
                            : [
                                _buildStudentAttendanceTab(
                                  context,
                                  isAdmin,
                                  isParent,
                                  isTablet,
                                ),
                                _buildStaffAttendanceTab(
                                  context,
                                  isAdmin,
                                  isTablet,
                                ),
                              ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceTab(
    BuildContext context,
    bool isAdmin,
    bool isParent,
    bool isTablet,
  ) {
    final disableStudentSignInOut =
        !AttendancePermissionService.hasPermissionToManageStudentAttendance(
          context,
        );
    final buttonSize = isTablet ? 40.0 : 36.0;
    final fontSize = isTablet ? 14.0 : 12.0;
    final horizontalPadding = isTablet ? 16.0 : 12.0;
    final verticalPadding = isTablet ? 16.0 : 12.0;
    final spacing = isTablet ? 16.0 : 8.0;

    // For very small screens, use wrap layout
    final useWrap = ResponsiveHelper(context).isNarrow;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useWrap)
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildActionButton(
                    icon: MediaRes.Sign_in,
                    label: 'Sign-in',
                    iconSize: buttonSize,
                    fontSize: fontSize,
                    onTap: disableStudentSignInOut
                        ? null
                        : () {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            final router = GoRouter.of(context);
                            navigator.pop();
                            router.push(
                              '/attendance/student-selection-sign-in',
                            );
                          },
                    context: context,
                  ),
                  _buildActionButton(
                    icon: MediaRes.Sign_out,
                    label: 'Sign-Out',
                    iconSize: buttonSize,
                    fontSize: fontSize,
                    onTap: disableStudentSignInOut
                        ? null
                        : () {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            final router = GoRouter.of(context);
                            navigator.pop();
                            router.push(
                              '/attendance/student-selection-sign-out',
                            );
                          },
                    context: context,
                  ),
                  if (!isParent)
                    _buildActionButton(
                      icon: MediaRes.transfer,
                      label: 'Transfer',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: disableStudentSignInOut
                          ? null
                          : () {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              router.push(
                                '/attendance/student-selection-transfer',
                              );
                            },
                      context: context,
                    ),
                  if (!isParent)
                    _buildActionButton(
                      icon: MediaRes.Mark_absent,
                      label: 'Absent',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: disableStudentSignInOut
                          ? null
                          : () {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              router.push(
                                '/attendance/student-selection-mark-absent',
                              );
                            },
                      context: context,
                    ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: MediaRes.Sign_in,
                      label: 'Sign-in',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: disableStudentSignInOut
                          ? null
                          : () {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              router.push(
                                '/attendance/student-selection-sign-in',
                              );
                            },
                      context: context,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildActionButton(
                      icon: MediaRes.Sign_out,
                      label: 'Sign-Out',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: disableStudentSignInOut
                          ? null
                          : () {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              router.push(
                                '/attendance/student-selection-sign-out',
                              );
                            },
                      context: context,
                    ),
                  ),
                  SizedBox(width: spacing),
                  if (!isParent) ...[
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildActionButton(
                        icon: MediaRes.transfer,
                        label: 'Transfer',
                        iconSize: buttonSize,
                        fontSize: fontSize,
                        onTap: disableStudentSignInOut
                            ? null
                            : () {
                                final navigator = Navigator.of(
                                  context,
                                  rootNavigator: true,
                                );
                                final router = GoRouter.of(context);
                                navigator.pop();
                                router.push(
                                  '/attendance/student-selection-transfer',
                                );
                              },
                        context: context,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildActionButton(
                        icon: MediaRes.Mark_absent,
                        label: 'Absent',
                        iconSize: buttonSize,
                        fontSize: fontSize,
                        onTap: disableStudentSignInOut
                            ? null
                            : () {
                                final navigator = Navigator.of(
                                  context,
                                  rootNavigator: true,
                                );
                                final router = GoRouter.of(context);
                                navigator.pop();
                                router.push(
                                  '/attendance/student-selection-mark-absent',
                                );
                              },
                        context: context,
                      ),
                    ),
                  ],
                ],
              ),
            // Parent and admin can open student attendance profile/view.
            if (isAdmin || isParent) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildViewAttendanceButton(
                context,
                isStaffTab: false,
                isTablet: isTablet,
                label: isParent
                    ? 'View My Child Attendance'
                    : 'View Attendance',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStaffAttendanceTab(
    BuildContext context,
    bool isAdmin,
    bool isTablet,
  ) {
    final roleProvider = context.watch<RoleCubit>();
    final geofenceState = context.watch<GeofenceCubit>().state;
    final bool isStaff = roleProvider.isStaff;
    // Self-service gating only applies to the staff persona's own
    // Sign-In/Sign-Out/Transfer/Mark-Absent; the admin staff-selection flow
    // (StaffSelectionSignInForm etc.) is unaffected.
    final StaffAttendanceActionAvailability availability = _todayGate
        .availabilityWithGeofence(geofenceState.isWithinGeofence);
    final bool selfActionsLoading = isStaff && _isTodayStatusLoading;
    final bool isSignInDisabled =
        isStaff && (selfActionsLoading || !availability.signInEnabled);
    final bool isSignOutDisabled =
        isStaff && (selfActionsLoading || !availability.signOutEnabled);
    final bool isTransferDisabledForStaff =
        isStaff && (selfActionsLoading || !availability.transferEnabled);
    final bool isAbsentDisabledForStaff =
        isStaff && (selfActionsLoading || !availability.absentEnabled);

    final buttonSize = isTablet ? 40.0 : 36.0;
    final fontSize = isTablet ? 14.0 : 12.0;
    final horizontalPadding = isTablet ? 16.0 : 12.0;
    final verticalPadding = isTablet ? 16.0 : 12.0;
    final spacing = isTablet ? 16.0 : 8.0;

    // For very small screens, use wrap layout
    final useWrap = ResponsiveHelper(context).isNarrow;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useWrap)
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildActionButton(
                    icon: MediaRes.Sign_in,
                    label: 'Sign-in',
                    iconSize: buttonSize,
                    fontSize: fontSize,
                    onTap: isSignInDisabled
                        ? null
                        : () async {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            final router = GoRouter.of(context);
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              router.push(
                                '/attendance/staff-sign-in',
                                extra: {
                                  'staff': StaffEntity(
                                    id: 0,
                                    name: display.fullName.isNotEmpty
                                        ? display.fullName
                                        : 'My Attendance',
                                    primaryRoomId: 0,
                                    photoUuid:
                                        display.profilePhotoUrl.isNotEmpty
                                        ? display.profilePhotoUrl
                                        : null,
                                    staffCode: display.staffCode.isNotEmpty
                                        ? display.staffCode
                                        : _loggedInStaffCode,
                                  ),
                                },
                              );
                            } else {
                              router.push(
                                '/attendance/staff-selection-sign-in',
                              );
                            }
                          },
                    context: context,
                  ),
                  _buildActionButton(
                    icon: MediaRes.Sign_out,
                    label: 'Sign-Out',
                    iconSize: buttonSize,
                    fontSize: fontSize,
                    onTap: isSignOutDisabled
                        ? null
                        : () async {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            final router = GoRouter.of(context);
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              router.push(
                                '/attendance/staff-sign-out',
                                extra: {
                                  'staff': StaffEntity(
                                    id: 0,
                                    name: display.fullName.isNotEmpty
                                        ? display.fullName
                                        : 'My Attendance',
                                    primaryRoomId: 0,
                                    photoUuid:
                                        display.profilePhotoUrl.isNotEmpty
                                        ? display.profilePhotoUrl
                                        : null,
                                    staffCode: display.staffCode.isNotEmpty
                                        ? display.staffCode
                                        : _loggedInStaffCode,
                                  ),
                                },
                              );
                            } else {
                              router.push(
                                '/attendance/staff-selection-sign-out',
                              );
                            }
                          },
                    context: context,
                  ),
                  _buildActionButton(
                    icon: MediaRes.transfer,
                    label: 'Transfer',
                    iconSize: buttonSize,
                    fontSize: fontSize,
                    onTap: isTransferDisabledForStaff
                        ? null
                        : () async {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            final router = GoRouter.of(context);
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              router.push(
                                '/attendance/staff-transfer',
                                extra: {
                                  'staff': StaffEntity(
                                    id: 0,
                                    name: display.fullName.isNotEmpty
                                        ? display.fullName
                                        : 'My Attendance',
                                    primaryRoomId: 0,
                                    photoUuid:
                                        display.profilePhotoUrl.isNotEmpty
                                        ? display.profilePhotoUrl
                                        : null,
                                    staffCode: display.staffCode.isNotEmpty
                                        ? display.staffCode
                                        : _loggedInStaffCode,
                                  ),
                                },
                              );
                            } else {
                              router.push(
                                '/attendance/staff-selection-transfer',
                              );
                            }
                          },
                    context: context,
                  ),
                  _buildActionButton(
                    icon: MediaRes.Mark_absent,
                    label: 'Absent',
                    iconSize: buttonSize,
                    fontSize: fontSize,
                    onTap: isAbsentDisabledForStaff
                        ? null
                        : () async {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            final router = GoRouter.of(context);
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              router.push(
                                '/attendance/staff-mark-absent',
                                extra: {
                                  'staff': StaffEntity(
                                    id: 0,
                                    name: display.fullName.isNotEmpty
                                        ? display.fullName
                                        : 'My Attendance',
                                    primaryRoomId: 0,
                                    photoUuid:
                                        display.profilePhotoUrl.isNotEmpty
                                        ? display.profilePhotoUrl
                                        : null,
                                    staffCode: display.staffCode.isNotEmpty
                                        ? display.staffCode
                                        : _loggedInStaffCode,
                                  ),
                                },
                              );
                            } else {
                              router.push(
                                '/attendance/staff-selection-mark-absent',
                              );
                            }
                          },
                    context: context,
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: MediaRes.Sign_in,
                      label: 'Sign-in',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: isSignInDisabled
                          ? null
                          : () async {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                router.push(
                                  '/attendance/staff-sign-in',
                                  extra: {
                                    'staff': StaffEntity(
                                      id: 0,
                                      name: display.fullName.isNotEmpty
                                          ? display.fullName
                                          : 'My Attendance',
                                      primaryRoomId: 0,
                                      photoUuid:
                                          display.profilePhotoUrl.isNotEmpty
                                          ? display.profilePhotoUrl
                                          : null,
                                      staffCode: display.staffCode.isNotEmpty
                                          ? display.staffCode
                                          : _loggedInStaffCode,
                                    ),
                                  },
                                );
                              } else {
                                router.push(
                                  '/attendance/staff-selection-sign-in',
                                );
                              }
                            },
                      context: context,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildActionButton(
                      icon: MediaRes.Sign_out,
                      label: 'Sign-Out',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: isSignOutDisabled
                          ? null
                          : () async {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                router.push(
                                  '/attendance/staff-sign-out',
                                  extra: {
                                    'staff': StaffEntity(
                                      id: 0,
                                      name: display.fullName.isNotEmpty
                                          ? display.fullName
                                          : 'My Attendance',
                                      primaryRoomId: 0,
                                      photoUuid:
                                          display.profilePhotoUrl.isNotEmpty
                                          ? display.profilePhotoUrl
                                          : null,
                                      staffCode: display.staffCode.isNotEmpty
                                          ? display.staffCode
                                          : _loggedInStaffCode,
                                    ),
                                  },
                                );
                              } else {
                                router.push(
                                  '/attendance/staff-selection-sign-out',
                                );
                              }
                            },
                      context: context,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildActionButton(
                      icon: MediaRes.transfer,
                      label: 'Transfer',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: isTransferDisabledForStaff
                          ? null
                          : () async {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                router.push(
                                  '/attendance/staff-transfer',
                                  extra: {
                                    'staff': StaffEntity(
                                      id: 0,
                                      name: display.fullName.isNotEmpty
                                          ? display.fullName
                                          : 'My Attendance',
                                      primaryRoomId: 0,
                                      photoUuid:
                                          display.profilePhotoUrl.isNotEmpty
                                          ? display.profilePhotoUrl
                                          : null,
                                      staffCode: display.staffCode.isNotEmpty
                                          ? display.staffCode
                                          : _loggedInStaffCode,
                                    ),
                                  },
                                );
                              } else {
                                router.push(
                                  '/attendance/staff-selection-transfer',
                                );
                              }
                            },
                      context: context,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildActionButton(
                      icon: MediaRes.Mark_absent,
                      label: 'Absent',
                      iconSize: buttonSize,
                      fontSize: fontSize,
                      onTap: isAbsentDisabledForStaff
                          ? null
                          : () async {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final router = GoRouter.of(context);
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                router.push(
                                  '/attendance/staff-mark-absent',
                                  extra: {
                                    'staff': StaffEntity(
                                      id: 0,
                                      name: display.fullName.isNotEmpty
                                          ? display.fullName
                                          : 'My Attendance',
                                      primaryRoomId: 0,
                                      photoUuid:
                                          display.profilePhotoUrl.isNotEmpty
                                          ? display.profilePhotoUrl
                                          : null,
                                      staffCode: display.staffCode.isNotEmpty
                                          ? display.staffCode
                                          : _loggedInStaffCode,
                                    ),
                                  },
                                );
                              } else {
                                router.push(
                                  '/attendance/staff-selection-mark-absent',
                                );
                              }
                            },
                      context: context,
                    ),
                  ),
                ],
              ),
            // Show "View Attendance" button:
            // - Admin: View Attendance (all staff list)
            // - Teacher persona: View My Attendance (self-only profile)
            if (isAdmin || _isTeacherStaffPersona == true) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildViewAttendanceButton(
                context,
                isStaffTab: true,
                isTablet: isTablet,
                label: _isTeacherStaffPersona == true
                    ? 'View My Attendance'
                    : 'View Attendance',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback? onTap,
    required BuildContext context,
    double iconSize = 36.0,
    double fontSize = 12.0,
  }) {
    final bool isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(icon, height: iconSize, width: iconSize),
              const SizedBox(height: AppSpacing.xxs),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: fontSize,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAttendanceButton(
    BuildContext context, {
    required bool isStaffTab,
    required bool isTablet,
    String label = 'View Attendance',
  }) {
    return InkWell(
      onTap: () async {
        final navigator = Navigator.of(context, rootNavigator: true);
        // Captured before popping the popup — the popup's own context is
        // defunct once it's removed.
        final router = GoRouter.of(context);
        navigator.pop();
        if (isStaffTab) {
          if (_isTeacherStaffPersona == true) {
            // Staff persona: only allow viewing own attendance profile. Open it
            // IN-PLACE inside the app shell via the router (the same way the
            // admin case below does) so the bottom nav stays functional and
            // tapping again while already on the page doesn't stack a duplicate
            // detached page — `router.go` to the same location replaces rather
            // than pushes.
            final display = await resolveLoggedInStaffDisplay();
            final staffCode = display.staffCode.trim();
            if (staffCode.isEmpty) {
              return;
            }
            final uri = Uri(
              path: '${StaffAttendanceProfile.routeName}-by-code',
              queryParameters: {
                'code': staffCode,
                'name': display.fullName.isNotEmpty ? display.fullName : '-',
              },
            );
            router.go(uri.toString());
          } else {
            // Admin: open the staff attendance tabbed view inside the app
            // shell (via the router) so the bottom navigation bar stays
            // functional, instead of pushing a detached new screen.
            router.go(StaffAttendanceTabbedView.routeName);
          }
        } else {
          if (_isParentRole) {
            await _openParentStudentAttendanceProfile(navigator.context);
            return;
          }
          // Open the student attendance tabbed view inside the app shell
          // (via the router) so the bottom navigation bar stays functional,
          // instead of pushing a detached new screen.
          router.go(StudentAttendanceTabbedView.routeName);
        }
      },
      borderRadius: AppRadius.allSm,
      child: Container(
        height: isTablet ? 56 : 48,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
        decoration: BoxDecoration(
          borderRadius: AppRadius.allSm,
          gradient: AppColors.buildSecondaryGradient(),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.r7),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: ShaderMask(
                shaderCallback: (Rect bounds) =>
                    AppColors.buildSecondaryGradient().createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: (isTablet ? 18 : 16) * (-3 / 100),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openParentStudentAttendanceProfile(BuildContext context) async {
    final profile = await buildParentChildAttendanceProfile(context);
    if (profile == null || !context.mounted) return;
    // GoRouter holdout (documented): deliberate deterministic branch-navigator / fade / dedup flow (see app_router.dart popAllShellBranchNavigators docs) — kept imperative.
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: StudentAttendanceProfile.routeName),
        builder: (_) => profile,
      ),
    );
  }

  double _getTabHeight({
    required bool isAdmin,
    required bool isParent,
    required bool isTablet,
    required double maxAvailableHeight,
  }) {
    // Calculate required height for content
    final buttonRowHeight = isTablet ? 100.0 : 80.0;
    final viewButtonHeight =
        (isParent || isAdmin || _isTeacherStaffPersona == true)
        ? (isTablet ? 76.0 : 64.0)
        : 0.0;
    final padding = isTablet ? 32.0 : 24.0;
    final calculatedHeight = buttonRowHeight + viewButtonHeight + padding;

    // Use calculated height but don't exceed available space
    return calculatedHeight.clamp(80.0, maxAvailableHeight.clamp(80.0, 300.0));
  }
}
