import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';

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
      barrierColor: Colors.black54,
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
    // If the profile screen is already showing, pop everything above it
    // instead of stacking a second copy.
    final navigator = Navigator.of(context, rootNavigator: false);
    bool alreadyOnProfile = false;
    navigator.popUntil((route) {
      if (route.settings.name == StudentAttendanceProfile.routeName) {
        alreadyOnProfile = true;
      }
      return true; // don't actually pop — just inspect
    });
    if (alreadyOnProfile) return;

    try {
      final parentChild = context.read<ParentChildCubit>();
      await parentChild.ensureLoaded();

      final selectedChild = parentChild.selectedChild;
      if (selectedChild == null || selectedChild.code.trim().isEmpty) {
        if (!context.mounted) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('No child linked to this parent account.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }

      String roomName = selectedChild.classroom.trim().isNotEmpty
          ? selectedChild.classroom
          : '—';
      var isSignedIn = false;

      try {
        final useCase = serviceLocator<GetStudentSignOutFormListUseCase>();
        final now = DateTime.now();
        final date =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final page = await useCase(
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

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: StudentAttendanceProfile.routeName,
          ),
          builder: (_) => StudentAttendanceProfile(
            studentCode: selectedChild.code.trim(),
            studentId: 0,
            studentName: selectedChild.name,
            studentPhotoUuid: null,
            roomName: roomName,
            isSignedIn: isSignedIn,
            syncWithParentChildSelection: true,
          ),
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
  bool _isParentRole = false;
  bool?
  _isTeacherStaffPersona; // When true: skip staff selection and use self forms.
  String _loggedInStaffCode = '';
  String? _lastSeenRole;

  // Today's self-attendance status for the logged-in staff persona, used
  // (alongside geofencing) to gate Sign-In/Sign-Out/Transfer/Mark-Absent in
  // the "My Attendance" tab. Not used for the admin staff-selection flow.
  String? _todayStatusRaw;
  bool _isTodayStatusLoading = false;

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
      final useCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
      final status = await useCase(staffCode: staffCode);
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
    final isAdmin = roleProvider.isAdmin && !_isParentRole;
    final isParent = _isParentRole;
    final isTeacherPersona = _isTeacherStaffPersona == true;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTablet = ResponsiveSizing.isTablet(context);
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.only(
        left: isTablet ? 24 : 12,
        right: isTablet ? 24 : 12,
        bottom: bottomPadding,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                    color: Colors.black,
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
                                  screenWidth,
                                ),
                              ]
                            : [
                                _buildStudentAttendanceTab(
                                  context,
                                  isAdmin,
                                  isParent,
                                  isTablet,
                                  screenWidth,
                                ),
                                _buildStaffAttendanceTab(
                                  context,
                                  isAdmin,
                                  isTablet,
                                  screenWidth,
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
    double screenWidth,
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
    final useWrap = screenWidth < 360;

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
                            navigator.pop();
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StudentSelectionSignInForm(),
                              ),
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
                            navigator.pop();
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StudentSelectionSignOutForm(),
                              ),
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
                              navigator.pop();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentSelectionTransferForm(),
                                ),
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
                              navigator.pop();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentSelectionMarkAbsentForm(),
                                ),
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
                              navigator.pop();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentSelectionSignInForm(),
                                ),
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
                              navigator.pop();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentSelectionSignOutForm(),
                                ),
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
                                navigator.pop();
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentSelectionTransferForm(),
                                  ),
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
                                navigator.pop();
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentSelectionMarkAbsentForm(),
                                  ),
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
    double screenWidth,
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
    final useWrap = screenWidth < 360;

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
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => StaffSignInForm(
                                    staff: StaffEntity(
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
                                  ),
                                ),
                              );
                            } else {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StaffSelectionSignInForm(),
                                ),
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
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => StaffSignOutForm(
                                    staff: StaffEntity(
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
                                  ),
                                ),
                              );
                            } else {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StaffSelectionSignOutForm(),
                                ),
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
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => StaffTransferForm(
                                    staff: StaffEntity(
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
                                  ),
                                ),
                              );
                            } else {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StaffSelectionTransferForm(),
                                ),
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
                            navigator.pop();
                            if (_isTeacherStaffPersona == true &&
                                _loggedInStaffCode.isNotEmpty) {
                              final display =
                                  await resolveLoggedInStaffDisplay();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => StaffMarkAbsentForm(
                                    staff: StaffEntity(
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
                                  ),
                                ),
                              );
                            } else {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StaffSelectionMarkAbsentForm(),
                                ),
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
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => StaffSignInForm(
                                      staff: StaffEntity(
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
                                    ),
                                  ),
                                );
                              } else {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StaffSelectionSignInForm(),
                                  ),
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
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => StaffSignOutForm(
                                      staff: StaffEntity(
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
                                    ),
                                  ),
                                );
                              } else {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StaffSelectionSignOutForm(),
                                  ),
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
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => StaffTransferForm(
                                      staff: StaffEntity(
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
                                    ),
                                  ),
                                );
                              } else {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StaffSelectionTransferForm(),
                                  ),
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
                              navigator.pop();
                              if (_isTeacherStaffPersona == true &&
                                  _loggedInStaffCode.isNotEmpty) {
                                final display =
                                    await resolveLoggedInStaffDisplay();
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => StaffMarkAbsentForm(
                                      staff: StaffEntity(
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
                                    ),
                                  ),
                                );
                              } else {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StaffSelectionMarkAbsentForm(),
                                  ),
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(icon, height: iconSize, width: iconSize),
              const SizedBox(height: 4),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: isTablet ? 56 : 48,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: AppColors.buildSecondaryGradient(),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
    try {
      final parentChild = context.read<ParentChildCubit>();
      await parentChild.ensureLoaded();

      final selectedChild = parentChild.selectedChild;
      if (selectedChild == null || selectedChild.code.trim().isEmpty) {
        if (!context.mounted) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('No child linked to this parent account.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }

      String roomName = selectedChild.classroom.trim().isNotEmpty
          ? selectedChild.classroom
          : '—';
      var isSignedIn = false;

      try {
        final useCase = serviceLocator<GetStudentSignOutFormListUseCase>();
        final now = DateTime.now();
        final date =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final page = await useCase(
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
        // Parents may not have sign-out form list access.
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: StudentAttendanceProfile.routeName,
          ),
          builder: (_) => StudentAttendanceProfile(
            studentCode: selectedChild.code.trim(),
            studentId: 0,
            studentName: selectedChild.name,
            studentPhotoUuid: null,
            roomName: roomName,
            isSignedIn: isSignedIn,
            syncWithParentChildSelection: true,
          ),
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
