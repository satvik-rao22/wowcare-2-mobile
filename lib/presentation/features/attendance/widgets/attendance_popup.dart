import 'dart:async';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/src/app_router.dart' show dashboardBranchKey;
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/view_model/student_attendance_profile_fetch_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/model/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/view_model/staff_attendance_profile_fetch_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Resolves the parent persona's selected child and builds the
/// [StudentAttendanceProfile] to open for them. Shows the matching snackbar
/// and returns null when no profile can be built.
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

    final fetchCubit = serviceLocator<StudentAttendanceProfileFetchCubit>();
    try {
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
    } finally {
      fetchCubit.close();
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
  /// Guards the Attendance tab against a double tap stacking two sheets.
  static bool _isOpening = false;

  static void showAttendancePopup(
    BuildContext context, {
    int initialTabIndex = 0,
  }) {
    if (_isOpening) return;
    _isOpening = true;

    // A parent skips the sheet and lands on the child's profile directly.
    final isParent = context.read<RoleCubit>().isParent;
    if (isParent) {
      unawaited(
        openParentChildAttendance(
          context,
        ).whenComplete(() => _isOpening = false),
      );
      return;
    }

    final isTablet = ResponsiveHelper(context).isTabletCompact;
    showModalBottomSheet<void>(
      context: context,
      // The sheet's actions pop the root navigator, as the old dialog did.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      barrierColor: AppColors.attendancePopupBarrierColor,
      constraints: isTablet ? const BoxConstraints(maxWidth: 600) : null,
      builder: (sheetContext) => MultiBlocProvider(
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

  /// Opens the selected child's attendance profile directly (parent tap on
  /// the Attendance tab). Safe to call repeatedly: an already-open profile is
  /// popped back to instead of pushed again.
  static Future<void> openParentChildAttendance(BuildContext context) async {
    // Always the Dashboard branch's own navigator: the shell keeps every
    // branch alive, so the ambient context's navigator may be a hidden one.
    final navigatorState = dashboardBranchKey.currentState;
    if (navigatorState == null) return;

    // Pop back to the profile if it is already on the stack; never past the
    // bottom of the stack when it is not there at all.
    bool alreadyOnProfile = false;
    navigatorState.popUntil((route) {
      if (route.settings.name == StudentAttendanceProfile.routeName) {
        alreadyOnProfile = true;
        return true;
      }
      return route.isFirst;
    });
    if (alreadyOnProfile) return;

    try {
      final profile = await buildParentChildAttendanceProfile(context);
      if (profile == null) return;

      if (!context.mounted) return;
      // A fade, not the default slide: this stands in for a tab switch.
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

/// A quick cross-fade for a pushed route that stands in for a bottom-nav tab.
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

/// Opens a staff attendance form: [selfRoute] for the teacher persona's own
/// record, [selectionRoute] when an admin picks a staff member first.
typedef _StaffActionOpener =
    Future<void> Function(
      BuildContext context, {
      required String selfRoute,
      required String selectionRoute,
    });

// The parent-only single-tab path below is kept but never reached at
// runtime: showAttendancePopup() short-circuits parents to the profile.

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

  /// True: skip staff selection and open the logged-in teacher's own forms.
  bool? _isTeacherStaffPersona;
  String _loggedInStaffCode = '';
  String? _lastSeenRole;

  /// Today's self-attendance status for the staff persona, which together
  /// with geofencing gates the "My Attendance" actions.
  String? _todayStatusRaw;

  /// Starts true so those actions render disabled until the real status has
  /// been fetched, instead of briefly enabling Sign-In for someone signed in.
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
    // Student actions gate on the staff being signed in; the shared
    // GeofenceCubit may be stale, so refresh it as the sheet opens.
    if (!context.read<RoleCubit>().isParent) {
      unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
      _resolveCrossClassPermission();
    }
  }

  /// Resolves the school's `allowTeacherCrossClassAttendance` flag, which the
  /// permission gate reads synchronously, then rebuilds.
  Future<void> _resolveCrossClassPermission() async {
    try {
      await _profileFetchCubit.resolveCrossClassEnabled();
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

  /// Multi-role users (e.g. ADMIN + GUARDIAN) follow the *active* persona
  /// chosen in switch-profile, not the mere presence of a guardian role.
  Future<bool> _resolveIsParentSession() async {
    try {
      final activeRole = await _profileFetchCubit.resolveActiveSchoolRole();
      if (activeRole != null) {
        final upper = activeRole.toUpperCase();
        return upper.contains('PARENT') || upper.contains('GUARDIAN');
      }
    } catch (_) {
      // Keep default false when session metadata is unavailable.
    }
    return context.read<RoleCubit>().isParent;
  }

  /// "My Attendance" (self) vs "Staff Attendance" (manage all) follows the
  /// active persona in RoleCubit; staffType is written too late to be relied on.
  Future<void> _loadStaffPersonaFlags() async {
    try {
      final isStaffPersona = context.read<RoleCubit>().isStaff;

      var staffCode = await _profileFetchCubit.resolveStaffCodeFromStorage();
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

  /// Rebuilds so the body height follows the current tab.
  void _onTabChanged() {
    setState(() {});
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
    // The student actions re-enable as soon as the staff sign-in resolves.
    context.watch<GeofenceCubit>();
    final isAdmin = roleProvider.isAdmin && !_isParentRole;
    final isParent = _isParentRole;
    final isTeacherPersona = _isTeacherStaffPersona == true;
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTabletCompact;
    final maxBodyHeight = (responsive.screenHeight * 0.45).clamp(140.0, 350.0);

    return Container(
      width: double.infinity,
      decoration: AppSurfaces.sheet(),
      // A Material of its own, so the keys' ink shows above the sheet ground.
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabber(),
              _tabBar(
                isParent: isParent,
                isTeacherPersona: isTeacherPersona,
                isTablet: isTablet,
              ),
              SizedBox(
                height: _tabHeight(
                  isAdmin: isAdmin,
                  isParent: isParent,
                  isTablet: isTablet,
                  maxAvailableHeight: maxBodyHeight,
                ),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StudentAttendanceTabView(
                      isAdmin: isAdmin,
                      isParent: isParent,
                      isTablet: isTablet,
                      onViewAttendanceTap: () =>
                          _handleViewAttendanceTap(context, isStaffTab: false),
                    ),
                    if (!isParent)
                      _StaffAttendanceTabView(
                        isAdmin: isAdmin,
                        isTablet: isTablet,
                        isTeacherPersona: isTeacherPersona,
                        todayGate: _todayGate,
                        isTodayStatusLoading: _isTodayStatusLoading,
                        onAction: _openStaffAction,
                        onViewAttendanceTap: () =>
                            _handleViewAttendanceTap(context, isStaffTab: true),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabber() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Container(
        width: 36,
        height: 4,
        decoration: const BoxDecoration(
          color: AppPalette.sheetGrabber,
          borderRadius: AppRadius.allPill,
        ),
      ),
    );
  }

  Widget _tabBar({
    required bool isParent,
    required bool isTeacherPersona,
    required bool isTablet,
  }) {
    return SizedBox(
      height: isTablet ? 56 : 50,
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.themeColor, width: 1.2),
        ),
        indicatorPadding: EdgeInsets.only(bottom: isTablet ? 10 : 8),
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 8),
        labelStyle: AppTextStyles.attendancePopupTabLabelSelected(
          isTablet: isTablet,
        ),
        unselectedLabelStyle: AppTextStyles.attendancePopupTabLabelUnselected(
          isTablet: isTablet,
        ),
        tabs: isParent
            ? const [Tab(text: 'Student Attendance')]
            : [
                const Tab(text: 'Student Attendance'),
                Tab(
                  text: isTeacherPersona ? 'My Attendance' : 'Staff Attendance',
                ),
              ],
      ),
    );
  }

  /// Closes the sheet, then opens a staff form: the teacher persona goes
  /// straight to its own form, an admin picks a staff member first.
  Future<void> _openStaffAction(
    BuildContext context, {
    required String selfRoute,
    required String selectionRoute,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    navigator.pop();
    if (_isTeacherStaffPersona == true && _loggedInStaffCode.isNotEmpty) {
      final display = await resolveLoggedInStaffDisplay();
      router.push(selfRoute, extra: {'staff': _selfStaffEntity(display)});
    } else {
      router.push(selectionRoute);
    }
  }

  StaffEntity _selfStaffEntity(LoggedInStaffDisplay display) => StaffEntity(
    id: 0,
    name: display.fullName.isNotEmpty ? display.fullName : 'My Attendance',
    primaryRoomId: 0,
    photoUuid: display.profilePhotoUrl.isNotEmpty
        ? display.profilePhotoUrl
        : null,
    staffCode: display.staffCode.isNotEmpty
        ? display.staffCode
        : _loggedInStaffCode,
  );

  Future<void> _handleViewAttendanceTap(
    BuildContext context, {
    required bool isStaffTab,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    // Captured before popping: the sheet's context is defunct afterwards.
    final router = GoRouter.of(context);
    navigator.pop();
    if (isStaffTab) {
      if (_isTeacherStaffPersona == true) {
        // Staff persona: only its own profile, opened in place via `go` so
        // the bottom nav stays live and a repeat tap does not stack a copy.
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
        // Admin: the tabbed view inside the shell, not a detached screen.
        router.go(StaffAttendanceTabbedView.routeName);
      }
    } else {
      if (_isParentRole) {
        await _openParentStudentAttendanceProfile(navigator.context);
        return;
      }
      router.go(StudentAttendanceTabbedView.routeName);
    }
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

  double _tabHeight({
    required bool isAdmin,
    required bool isParent,
    required bool isTablet,
    required double maxAvailableHeight,
  }) {
    final buttonRowHeight = isTablet ? 100.0 : 80.0;
    final viewButtonHeight =
        (isParent || isAdmin || _isTeacherStaffPersona == true)
        ? (isTablet ? 76.0 : 64.0)
        : 0.0;
    final padding = isTablet ? 32.0 : 24.0;
    final calculatedHeight = buttonRowHeight + viewButtonHeight + padding;
    return calculatedHeight.clamp(80.0, maxAvailableHeight.clamp(80.0, 300.0));
  }
}

/// Shared body for both tabs: the action tiles, wrapping on a narrow screen
/// and spread evenly otherwise, with the optional view key beneath.
class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.isTablet,
    required this.tiles,
    this.viewButton,
  });

  final bool isTablet;
  final List<Widget> tiles;
  final Widget? viewButton;

  @override
  Widget build(BuildContext context) {
    final double padding = isTablet ? 16 : 12;
    final double spacing = isTablet ? 16 : 8;
    final bool useWrap = ResponsiveHelper(context).isNarrow;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useWrap)
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: spacing,
                runSpacing: spacing,
                children: tiles,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < tiles.length; i++) ...[
                    if (i > 0) SizedBox(width: spacing),
                    Expanded(child: tiles[i]),
                  ],
                ],
              ),
            if (viewButton != null) ...[
              SizedBox(height: isTablet ? 20 : 16),
              viewButton!,
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentAttendanceTabView extends StatelessWidget {
  const _StudentAttendanceTabView({
    required this.isAdmin,
    required this.isParent,
    required this.isTablet,
    required this.onViewAttendanceTap,
  });

  final bool isAdmin;
  final bool isParent;
  final bool isTablet;
  final VoidCallback onViewAttendanceTap;

  /// Closes the sheet, then opens the student selection form at [route].
  void _open(BuildContext context, String route) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    navigator.pop();
    router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final disabled =
        !AttendancePermissionService.hasPermissionToManageStudentAttendance(
          context,
        );
    final iconSize = isTablet ? 40.0 : 36.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    Widget tile(String icon, String label, String route) {
      return AttendancePopupActionButton(
        icon: icon,
        label: label,
        iconSize: iconSize,
        fontSize: fontSize,
        onTap: disabled ? null : () => _open(context, route),
      );
    }

    return _TabBody(
      isTablet: isTablet,
      tiles: [
        tile(
          MediaRes.Sign_in,
          'Sign-in',
          '/attendance/student-selection-sign-in',
        ),
        tile(
          MediaRes.Sign_out,
          'Sign-Out',
          '/attendance/student-selection-sign-out',
        ),
        if (!isParent)
          tile(
            MediaRes.transfer,
            'Transfer',
            '/attendance/student-selection-transfer',
          ),
        if (!isParent)
          tile(
            MediaRes.Mark_absent,
            'Absent',
            '/attendance/student-selection-mark-absent',
          ),
      ],
      // Parent and admin can open the student attendance profile/view.
      viewButton: (isAdmin || isParent)
          ? AttendancePopupViewButton(
              onTap: onViewAttendanceTap,
              isTablet: isTablet,
              label: isParent ? 'View My Child Attendance' : 'View Attendance',
            )
          : null,
    );
  }
}

class _StaffAttendanceTabView extends StatelessWidget {
  const _StaffAttendanceTabView({
    required this.isAdmin,
    required this.isTablet,
    required this.isTeacherPersona,
    required this.todayGate,
    required this.isTodayStatusLoading,
    required this.onAction,
    required this.onViewAttendanceTap,
  });

  final bool isAdmin;
  final bool isTablet;
  final bool isTeacherPersona;
  final StaffAttendanceGate todayGate;
  final bool isTodayStatusLoading;
  final _StaffActionOpener onAction;
  final VoidCallback onViewAttendanceTap;

  @override
  Widget build(BuildContext context) {
    final bool isStaff = context.watch<RoleCubit>().isStaff;
    final geofenceState = context.watch<GeofenceCubit>().state;
    // Self-service gating applies only to the staff persona's own actions;
    // the admin staff-selection flow is never gated here.
    final StaffAttendanceActionAvailability availability = todayGate
        .availabilityWithGeofence(geofenceState.isWithinGeofence);
    final bool selfActionsLoading = isStaff && isTodayStatusLoading;
    bool isDisabled(bool enabled) =>
        isStaff && (selfActionsLoading || !enabled);

    final iconSize = isTablet ? 40.0 : 36.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    Widget tile({
      required String icon,
      required String label,
      required bool enabled,
      required String selfRoute,
      required String selectionRoute,
    }) {
      return AttendancePopupActionButton(
        icon: icon,
        label: label,
        iconSize: iconSize,
        fontSize: fontSize,
        onTap: isDisabled(enabled)
            ? null
            : () => onAction(
                context,
                selfRoute: selfRoute,
                selectionRoute: selectionRoute,
              ),
      );
    }

    return _TabBody(
      isTablet: isTablet,
      tiles: [
        tile(
          icon: MediaRes.Sign_in,
          label: 'Sign-in',
          enabled: availability.signInEnabled,
          selfRoute: '/attendance/staff-sign-in',
          selectionRoute: '/attendance/staff-selection-sign-in',
        ),
        tile(
          icon: MediaRes.Sign_out,
          label: 'Sign-Out',
          enabled: availability.signOutEnabled,
          selfRoute: '/attendance/staff-sign-out',
          selectionRoute: '/attendance/staff-selection-sign-out',
        ),
        tile(
          icon: MediaRes.transfer,
          label: 'Transfer',
          enabled: availability.transferEnabled,
          selfRoute: '/attendance/staff-transfer',
          selectionRoute: '/attendance/staff-selection-transfer',
        ),
        tile(
          icon: MediaRes.Mark_absent,
          label: 'Absent',
          enabled: availability.absentEnabled,
          selfRoute: '/attendance/staff-mark-absent',
          selectionRoute: '/attendance/staff-selection-mark-absent',
        ),
      ],
      // Admin: all staff. Teacher persona: own profile only.
      viewButton: (isAdmin || isTeacherPersona)
          ? AttendancePopupViewButton(
              onTap: onViewAttendanceTap,
              isTablet: isTablet,
              label: isTeacherPersona
                  ? 'View My Attendance'
                  : 'View Attendance',
            )
          : null,
    );
  }
}

/// A single action icon+label tile in the sheet's action row (Sign-in,
/// Sign-Out, Transfer, Absent), shared by both tabs.
class AttendancePopupActionButton extends StatelessWidget {
  const AttendancePopupActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 36.0,
    this.fontSize = 12.0,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  /// The edge of the tile, not of the glyph — see [build].
  final double iconSize;
  final double fontSize;

  /// How much of the tile the glyph fills, leaving the tile's bevel and rim
  /// visible all the way round at every size the sheet uses.
  static const double _glyphRatio = 0.56;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A fixed tile per glyph: the four assets disagree on their
              // own bounds, so left alone they line up at four widths.
              Container(
                width: iconSize,
                height: iconSize,
                alignment: Alignment.center,
                decoration: AppSurfaces.iconKey(),
                child: AppIcon(
                  icon,
                  size: iconSize * _glyphRatio,
                  tone: IconTone.action,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.attendancePopupActionButton(
                    fontSize: fontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "View Attendance" key at the foot of both tab bodies.
class AttendancePopupViewButton extends StatelessWidget {
  const AttendancePopupViewButton({
    super.key,
    required this.onTap,
    required this.isTablet,
    this.label = 'View Attendance',
  });

  final VoidCallback onTap;
  final bool isTablet;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: SkeuKeyBox(
        variant: KeyVariant.secondary,
        width: double.infinity,
        height: isTablet ? 56 : 48,
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.attendancePopupViewButton(
                isTablet: isTablet,
              ).copyWith(color: AppSurfaces.keyInk(KeyVariant.secondary)),
            ),
          ),
        ),
      ),
    );
  }
}
