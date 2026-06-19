import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/events/view/events_screen.dart';
import 'package:wowcare/presentation/features/tasks/view/tasks_screen.dart';
import 'package:wowcare/presentation/features/assessments/view/assessments_home_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_newsletter_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/features/scheduling/view/scheduling_screen.dart';
import '../../../presentation/features/scheduling/view/staff_scheduling_screen.dart';
import '../../../presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/activity_feed_invalidation.dart';
import 'package:wowcare/core/cache/session_local_cache_wiper.dart';
import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_students_tab_card.dart';
import 'package:wowcare/presentation/features/scheduling/utils/scheduling_cache_gate.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/availability/view/future_availability_screen.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _currentRoute = '';
  bool _isSchoolDropdownOpen = false;
  bool _isLoadingSchools = true;
  bool _schoolContextLoaded = false;
  String? _currentOrgCode;
  String? _selectedSchoolCode;
  String? _selectedSchoolName;
  List<Map<String, String>> _schoolsForOrg = const <Map<String, String>>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    // Load once per drawer-state lifetime — previously fired on every
    // didChangeDependencies (MediaQuery/Theme/Provider change), which with
    // 5 drawer instances alive in the shell's IndexedStack means many
    // duplicate network calls competing for the main thread during
    // transitions.
    if (!_schoolContextLoaded) {
      _schoolContextLoaded = true;
      _loadSchoolContext();
    }
  }

  Future<void> _loadSchoolContext() async {
    try {
      final storage = serviceLocator<StorageService>();
      final authLocal = serviceLocator<AuthLocalDataSource>();
      final authCubit = context.read<AuthCubit>();
      final orgCode = await storage.getString(StorageKeys.organizationCode);
      final schoolCode = await storage.getString(StorageKeys.schoolCode);
      final selectedName = await storage.getString(
        StorageKeys.selectedSchoolName,
      );
      List<Map<String, String>> schoolsForOrg = const <Map<String, String>>[];

      // Primary source: API-backed school list
      // GET /api/v1/organization/schools/names-by-org/{orgCode}?isAdmin=true
      if (orgCode != null && orgCode.isNotEmpty) {
        await authCubit.loadSchoolsForOrg(orgCode);
        final state = authCubit.state;
        if (state is AuthLoaded) {
          schoolsForOrg = List<Map<String, String>>.from(
            state.schoolsByOrg[orgCode] ?? const <Map<String, String>>[],
          );
        }
      }

      // Fallback to local cache if API-backed state is empty.
      if (schoolsForOrg.isEmpty) {
        final orgSchools = await authLocal.getOrganizationsAndSchools();
        schoolsForOrg = orgSchools
            .where((e) => e['organizationCode'] == (orgCode ?? ''))
            .toList();
      }

      // Keep only entries with valid code; prefer readable schoolName.
      schoolsForOrg = schoolsForOrg
          .where((e) => (e['schoolCode'] ?? '').trim().isNotEmpty)
          .map(
            (e) => <String, String>{
              'schoolCode': (e['schoolCode'] ?? '').trim(),
              'schoolName': (e['schoolName'] ?? '').trim(),
            },
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _currentOrgCode = orgCode;
        _schoolsForOrg = schoolsForOrg;
        _selectedSchoolCode = schoolCode;
        _selectedSchoolName = selectedName;
        _isLoadingSchools = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchools = false;
      });
    }
  }

  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 28,
              backgroundImage: AssetImage(MediaRes.logo_wow),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  const Text(
                    'WowCare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // School switcher dropdown (for current organization)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSchoolSwitcher(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolSwitcher() {
    if (_isLoadingSchools) {
      return const SizedBox.shrink();
    }

    if (_currentOrgCode == null || _currentOrgCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_schoolsForOrg.isEmpty) {
      return const SizedBox.shrink();
    }

    // Resolve a human-friendly school name. Prefer the name from the
    // cached org/school list, falling back to selectedSchoolName and
    // finally to a generic placeholder.
    String currentName = 'Select school';
    if (_selectedSchoolCode != null && _selectedSchoolCode!.isNotEmpty) {
      final match = _schoolsForOrg.firstWhere(
        (e) => e['schoolCode'] == _selectedSchoolCode,
        orElse: () => const <String, String>{},
      );
      final fromList = match['schoolName'];
      if (fromList != null && fromList.isNotEmpty) {
        currentName = fromList;
      } else if (_selectedSchoolName != null &&
          _selectedSchoolName!.isNotEmpty &&
          _selectedSchoolName != _selectedSchoolCode) {
        // Only use stored name if it's not just the code.
        currentName = _selectedSchoolName!;
      }
    } else {
      currentName = _schoolsForOrg.first['schoolName'] ?? 'Select school';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isSchoolDropdownOpen = !_isSchoolDropdownOpen;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                _isSchoolDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
        if (_isSchoolDropdownOpen) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _schoolsForOrg.length,
              itemBuilder: (context, index) {
                final school = _schoolsForOrg[index];
                final code = school['schoolCode'] ?? '';
                final schoolName = (school['schoolName'] ?? '').trim();
                final name = schoolName.isNotEmpty ? schoolName : code;
                final isSelected = code == _selectedSchoolCode;
                return InkWell(
                  onTap: () => _onSchoolSelected(code, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onSchoolSelected(String schoolCode, String schoolName) async {
    if (_currentOrgCode == null || _currentOrgCode!.isEmpty) return;
    final isSchoolChanged =
        (_selectedSchoolCode ?? '').trim() != schoolCode.trim();

    final authLocal = serviceLocator<AuthLocalDataSource>();
    final authCubit = context.read<AuthCubit>();

    // Persist new selection locally (used by all APIs).
    await authLocal.setSelectedOrgAndSchool(
      organizationCode: _currentOrgCode!,
      schoolCode: schoolCode,
      schoolName: schoolName,
    );

    // Keep flow same: update backend login-context when school selection changes.
    if (isSchoolChanged) {
      await authCubit.updateLoginContext(
        lastLoginOrganizationCode: _currentOrgCode!,
        lastLoginSchoolCode: schoolCode,
      );

      // School actually changed: wipe every cached artifact so the newly
      // selected school loads fresh data everywhere instead of hydrating from
      // the previous school's cache. Runs BEFORE the prefetch/refresh below so
      // those re-populate clean caches for the new school.
      await _clearAllCachesForSchoolSwitch();
    }

    // Prefetch staff profile for the newly selected organisation/school
    // so that My Profile and related screens load instantly after switch.
    await authCubit.prefetchStaffProfileForOrgAndSchool(
      organizationCode: _currentOrgCode!,
      schoolCode: schoolCode,
    );
    await context.read<RoleCubit>().refreshAccessFromServer(force: true);

    if (!mounted) return;
    context.read<ParentChildCubit>().invalidate();
    await context.read<ParentChildCubit>().ensureLoaded(force: true);

    if (!mounted) return;
    setState(() {
      _selectedSchoolCode = schoolCode;
      _selectedSchoolName = schoolName;
      _isSchoolDropdownOpen = false;
    });

    // Close drawer and send user to Dashboard for the newly selected school.
    Navigator.pop(context);
    if (!mounted) return;
    context.go(DashboardScreen.routeName);
  }

  /// Clears every cache layer so a school switch starts from a clean slate:
  ///  1. Persisted `*_cache_*` SharedPreferences entries (repository caches),
  ///     keeping the auth/session login cache which is not school-scoped.
  ///  2. Non-prefs caches — image cache, Isar messaging/conversation
  ///     collections, in-flight staff request caches (via the session wiper).
  ///  3. Process-wide in-memory caches / invalidation gates that open screens
  ///     listen to (students attendance status, scheduling, activity feed).
  ///
  /// Each step is isolated so one failure never blocks the rest of the switch.
  Future<void> _clearAllCachesForSchoolSwitch() async {
    final storage = serviceLocator<StorageService>();

    try {
      await CacheManager(storage).clearAllStandardCaches(
        protectedKeys: <String>{
          StorageKeys.loginCacheKey,
          StorageKeys.loginCacheTimestamp,
        },
      );
    } catch (_) {}

    try {
      await serviceLocator<SessionLocalCacheWiper>().wipe();
    } catch (_) {}

    try {
      clearClassroomStudentsAttendanceCache();
    } catch (_) {}

    try {
      SchedulingCacheGate.invalidate();
    } catch (_) {}

    try {
      await ActivityFeedInvalidation.invalidate(storage);
    } catch (_) {}
  }

  void _showSnackOnRoot(String message, {bool isError = false}) {
    final ctx = CoreUtils.rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.errorColor
            : AppColors.warningColor,
      ),
    );
  }

  /// Opens [StudentAttendanceProfile] for the child selected in the global app bar
  /// dropdown.
  ///
  /// [navigator] and [parentChild] must be captured **before** closing the drawer.
  /// After [Navigator.pop], this [State] is often disposed while awaiting
  /// [ensureLoaded], so we must not rely on [mounted] or this widget's [context].
  Future<void> _openParentAttendanceProfile(
    NavigatorState navigator,
    ParentChildCubit parentChild,
  ) async {
    try {
      await parentChild.ensureLoaded();

      final selectedChild = parentChild.selectedChild;
      if (selectedChild == null || selectedChild.code.trim().isEmpty) {
        _showSnackOnRoot(
          'No child selected. Choose a child from the menu at the top first.',
        );
        return;
      }

      String roomName = selectedChild.classroom.trim().isNotEmpty
          ? selectedChild.classroom
          : '—';
      var isSignedIn = false;

      try {
        final signOutFormList =
            serviceLocator<GetStudentSignOutFormListUseCase>();
        final now = DateTime.now();
        final date =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final signedInPage = await signOutFormList(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: 200,
        );
        final selected = signedInPage.items.where(
          (i) => i.studentCode.trim() == selectedChild.code.trim(),
        );
        if (selected.isNotEmpty) {
          final child = selected.first;
          roomName = child.classroomName.trim().isNotEmpty
              ? child.classroomName
              : roomName;
          isSignedIn = child.hasSignIn && !child.hasSignOut;
        }
      } catch (_) {
        // Parents/guardians may not have sign-out form list access.
      }

      if (!navigator.context.mounted) return;
      navigator.context.go(
        StudentAttendanceProfile.routeName,
        extra: <String, dynamic>{
          'studentCode': selectedChild.code.trim(),
          'studentId': 0,
          'studentName': selectedChild.name,
          'studentPhotoUuid': null,
          'roomName': roomName,
          'isSignedIn': isSignedIn,
          'syncWithParentChildSelection': true,
        },
      );
    } catch (_) {
      _showSnackOnRoot('Unable to open attendance right now.', isError: true);
    }
  }

  /// Opens [StudentProfileScreen] for the child selected in the global app bar
  /// dropdown.
  ///
  /// [navigator] and [parentChild] must be captured **before** closing the drawer.
  /// After [Navigator.pop], this [State] is often disposed while awaiting
  /// [refreshAccessFromServer], so we must not rely on [mounted] or this widget's
  /// [context] (same pattern as [_openParentAttendanceProfile]).
  Future<void> _openParentStudentProfile(
    NavigatorState navigator,
    ParentChildCubit parentChild,
  ) async {
    try {
      await parentChild.ensureLoaded();

      final selectedChild = parentChild.selectedChild;
      if (selectedChild == null || selectedChild.code.trim().isEmpty) {
        _showSnackOnRoot(
          'No child selected. Choose a child from the menu at the top first.',
        );
        return;
      }

      if (!navigator.context.mounted) return;
      await navigator.context.read<RoleCubit>().refreshAccessFromServer(
        force: true,
      );

      if (!navigator.context.mounted) return;
      navigator.context.go(
        StudentProfileScreen.routeName,
        extra: <String, dynamic>{
          'name': selectedChild.name,
          'classroom': selectedChild.classroom,
          'tags': selectedChild.tags,
          'schedule': selectedChild.schedule,
          'sibling': const <String, dynamic>{
            'name': <dynamic>[],
            'relation': <dynamic>[],
            'status': <dynamic>[],
          },
          'studentCode': selectedChild.code,
          'syncWithParentChildSelection': true,
        },
      );
    } catch (_) {
      _showSnackOnRoot(
        'Unable to open student profile right now.',
        isError: true,
      );
    }
  }

  Future<void> _openLoggedInStaffProfile(NavigatorState navigator) async {
    try {
      final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      if (staffCode.isEmpty) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to resolve your staff profile. Please re-login.',
            ),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }

      final repo = serviceLocator<StaffRepository>();
      final profile = await repo.getStaffProfile(staffCode: staffCode);

      final classroomCode = profile.primaryClassroomCode.trim().isNotEmpty
          ? profile.primaryClassroomCode.trim()
          : (profile.allowedClassroomCodes.isNotEmpty
                ? profile.allowedClassroomCodes.first.trim()
                : '-');
      final classroom = await _resolveClassroomName(classroomCode);

      if (!navigator.context.mounted) return;
      navigator.context.go(
        StaffProfileScreen.routeName,
        extra: <String, dynamic>{
          'staffCode': profile.staffCode,
          'name': profile.fullName.trim().isNotEmpty
              ? profile.fullName.trim()
              : '-',
          'classroom': classroom,
          'designation': profile.designation,
          'phoneNumber': profile.phoneNumber,
          'employmentStatus': profile.status,
        },
      );
    } catch (_) {
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open your profile right now.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _openLoggedInStaffAttendanceProfile(
    NavigatorState navigator,
  ) async {
    try {
      final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      if (staffCode.isEmpty) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to resolve your attendance profile. Please re-login.',
            ),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }

      final repo = serviceLocator<StaffRepository>();
      final profile = await repo.getStaffProfile(staffCode: staffCode);
      final roomCode = profile.primaryClassroomCode.trim().isNotEmpty
          ? profile.primaryClassroomCode.trim()
          : (profile.allowedClassroomCodes.isNotEmpty
                ? profile.allowedClassroomCodes.first.trim()
                : '-');
      final roomName = await _resolveClassroomName(roomCode);

      if (!navigator.context.mounted) return;
      navigator.context.go(
        StaffAttendanceProfile.routeName,
        extra: <String, dynamic>{
          'staffCode': profile.staffCode,
          'staffId': 0,
          'staffName': profile.fullName.trim().isNotEmpty
              ? profile.fullName.trim()
              : '-',
          'staffPhotoUuid': profile.profilePhotoUrl.trim().isNotEmpty
              ? profile.profilePhotoUrl
              : null,
          'designationName': profile.designation,
          'roomName': roomName,
        },
      );
    } catch (_) {
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open your attendance right now.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<String> _resolveClassroomName(String classroomCode) async {
    final trimmedCode = classroomCode.trim();
    if (trimmedCode.isEmpty || trimmedCode == '-') return '-';

    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (schoolCode.isEmpty) return trimmedCode;

      final getActiveClassrooms = serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getActiveClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );

      for (final classroom in classrooms) {
        if (classroom.code.trim() == trimmedCode) {
          final name = classroom.name.trim();
          return name.isNotEmpty ? name : trimmedCode;
        }
      }
    } catch (_) {
      // Fall back to code on resolution errors.
    }

    return trimmedCode;
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleCubit>();
    final isParent = roleProvider.isParent;
    final isStaff = roleProvider.isStaff;
    final canViewStudents = roleProvider.canAccessAny([
      AppAccessModules.student,
    ]);
    final canViewStaff = roleProvider.canAccessAny([AppAccessModules.staff]);
    final canViewClassrooms = roleProvider.canAccessAny([
      AppAccessModules.classroom,
    ]);
    final showStudentAttendance = roleProvider.canOpenModule(
      AppAccessModules.studentAttendance,
    );
    final showStaffAttendance = roleProvider.canOpenModule(
      AppAccessModules.staffAttendance,
    );
    final showAdminAttendanceMenu =
        showStudentAttendance || showStaffAttendance;
    final canViewActivities = roleProvider.canReadModule(
      AppAccessModules.dailyActivity,
    );
    final showParentMessagingDrawer = roleProvider.canReadModule(
      AppAccessModules.parentMessaging,
    );
    final showParentNewsletterDrawer = roleProvider.canReadModule(
      AppAccessModules.newsletter,
    );
    final showStaffMessagingDrawer = roleProvider.canReadModule(
      AppAccessModules.staffMessaging,
    );
    final canViewBilling = roleProvider.canAccessAny([
      AppAccessModules.transaction,
      AppAccessModules.invoices,
      AppAccessModules.recurringPlans,
      AppAccessModules.billingSettings,
    ]);
    final showIndividualMovement = roleProvider.canOpenModule(
      AppAccessModules.individualMovements,
    );
    final showFutureAvailability = roleProvider.canOpenModule(
      AppAccessModules.futureAvailability,
    );
    final showAvailabilityMenu =
        showIndividualMovement || showFutureAvailability;
    final showDashboardDrawer =
        !roleProvider.usesGranularModuleAccess ||
        roleProvider.canOpenModule(AppAccessModules.dashboard);
    final showSettingsMenu =
        !roleProvider.usesGranularModuleAccess ||
        roleProvider.canOpenModule(AppAccessModules.settings);
    final parentChildProvider = context.watch<ParentChildCubit>();
    if (isParent &&
        !parentChildProvider.isLoaded &&
        !parentChildProvider.isLoading) {
      Future.microtask(parentChildProvider.ensureLoaded);
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 2 / 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(gradient: AppColors.buildPrimaryGradient()),
        child: Column(
          children: [
            _header(),
            const Divider(
              color: Colors.white,
              thickness: 0.3,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      if (showDashboardDrawer)
                        _CustomExpansionTile(
                          title: 'Dashboard',
                          icon: MediaRes.dashboardIcon,
                          isDashboard: true,
                          isCurrentRoute:
                              _currentRoute == DashboardScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != DashboardScreen.routeName) {
                              context.go(DashboardScreen.routeName);
                            }
                          },
                        ),
                      if (isParent) ...[
                        // Parent-specific menu items (not gated on STUDENT module read:
                        // [canViewStudents] is false for many parents with legacy/empty
                        // permissions, but they must still open their linked child's profile.)
                        _CustomExpansionTile(
                          title: 'My Child',
                          icon: MediaRes.students_drawer_icon,
                          isCurrentRoute:
                              _currentRoute == StudentProfileScreen.routeName,
                          onTap: () {
                            final nav = Navigator.of(context);
                            final parentChild = context
                                .read<ParentChildCubit>();
                            final alreadyHere =
                                _currentRoute == StudentProfileScreen.routeName;
                            Navigator.pop(context);
                            if (alreadyHere) return;
                            _openParentStudentProfile(nav, parentChild);
                          },
                        ),
                        if (showStudentAttendance)
                          _CustomExpansionTile(
                            title: 'Attendance',
                            icon: MediaRes.attendanceIcon,
                            isCurrentRoute:
                                _currentRoute ==
                                StudentAttendanceProfile.routeName,
                            onTap: () {
                              final nav = Navigator.of(context);
                              final parentChild = context
                                  .read<ParentChildCubit>();
                              final alreadyHere =
                                  _currentRoute ==
                                  StudentAttendanceProfile.routeName;
                              Navigator.pop(context);
                              if (alreadyHere) return;
                              _openParentAttendanceProfile(nav, parentChild);
                            },
                          ),
                        if (canViewActivities)
                          _CustomExpansionTile(
                            title: 'Activities',
                            icon: MediaRes.activitesIcon,
                            isCurrentRoute:
                                _currentRoute == ActivityFeedScreen.routeName,
                            onTap: () {
                              Navigator.pop(context);
                              if (_currentRoute !=
                                  ActivityFeedScreen.routeName) {
                                context.go(ActivityFeedScreen.routeName);
                              }
                            },
                          ),
                        _CustomExpansionTile(
                          title: 'Events',
                          icon: MediaRes.calenderClockIcon,
                          isCurrentRoute:
                              _currentRoute == EventsScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != EventsScreen.routeName) {
                              context.go(EventsScreen.routeName);
                            }
                          },
                        ),
                        if (showParentMessagingDrawer ||
                            showParentNewsletterDrawer)
                          _CustomExpansionTile(
                            title: 'Communication',
                            icon: MediaRes.communicationIcon,
                            isCurrentRoute:
                                _currentRoute == MessagingScreen.routeName,
                            isExpansionEnabled: true,
                            children: [
                              if (showParentMessagingDrawer)
                                DrawerListTile(
                                  title: 'Messaging',
                                  leading: SvgPicture.asset(
                                    MediaRes.parentMessaging,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(MessagingScreen.routeName);
                                  },
                                ),
                              if (showParentNewsletterDrawer)
                                DrawerListTile(
                                  title: 'Newsletter',
                                  leading: SvgPicture.asset(
                                    MediaRes.newsletter,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(
                                      ParentNewsletterScreen.routeName,
                                    );
                                  },
                                ),
                            ],
                          ),
                        if (canViewBilling)
                          _CustomExpansionTile(
                            title: 'Billing',
                            icon: MediaRes.billing_drawer_icon,
                            isCurrentRoute:
                                _currentRoute == ParentBillingScreen.routeName,
                            onTap: () {
                              Navigator.pop(context);
                              if (_currentRoute !=
                                  ParentBillingScreen.routeName) {
                                context.go(ParentBillingScreen.routeName);
                              }
                            },
                          ),
                      ] else ...[
                        // Admin menu items
                        if (canViewClassrooms)
                          _CustomExpansionTile(
                            title: 'Classrooms',
                            icon: MediaRes.classroom_drawer_icon,
                            isCurrentRoute:
                                _currentRoute == ClassroomScreen.routeName,
                            onTap: () {
                              Navigator.pop(context);
                              // Classroom is a tab branch — go (not push) so
                              // the bottom-nav switches to its tab and we
                              // don't stack a second copy on the current
                              // branch's navigator.
                              context.go(ClassroomScreen.routeName);
                            },
                          ),
                        if (canViewStudents)
                          _CustomExpansionTile(
                            title: 'Students',
                            icon: MediaRes.students_drawer_icon,
                            isCurrentRoute:
                                _currentRoute == StudentScreen.routeName,
                            onTap: () {
                              Navigator.pop(context);
                              if (_currentRoute != StudentScreen.routeName) {
                                context.go(StudentScreen.routeName);
                              }
                            },
                          ),
                        if (canViewStaff)
                          _CustomExpansionTile(
                            title: 'Staff',
                            icon: MediaRes.staffs_drawer_icon,
                            isCurrentRoute:
                                _currentRoute == StaffScreen.routeName ||
                                (isStaff &&
                                    _currentRoute ==
                                        StaffProfileScreen.routeName),
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              final captured = _currentRoute;
                              Navigator.pop(context);
                              if (isStaff) {
                                if (captured == StaffProfileScreen.routeName) {
                                  return;
                                }
                                await _openLoggedInStaffProfile(navigator);
                                return;
                              }
                              if (captured != StaffScreen.routeName) {
                                context.go(StaffScreen.routeName);
                              }
                            },
                          ),

                        if (showAdminAttendanceMenu)
                          _CustomExpansionTile(
                            title: 'Attendance',
                            icon: MediaRes.attendanceIcon,
                            isExpansionEnabled: true,
                            children: [
                              if (showStudentAttendance)
                                DrawerListTile(
                                  title: 'Student Attendance',
                                  leading: SvgPicture.asset(
                                    MediaRes.studentAttendanceDrawer,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (_currentRoute !=
                                        StudentAttendanceTabbedView.routeName) {
                                      context.go(
                                        StudentAttendanceTabbedView.routeName,
                                      );
                                    }
                                  },
                                ),
                              if (showStaffAttendance)
                                DrawerListTile(
                                  title: isStaff
                                      ? 'My Attendance'
                                      : 'Staff Attendance',
                                  leading: SvgPicture.asset(
                                    MediaRes.staffAttendanceDrawer,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    final navigator = Navigator.of(context);
                                    final captured = _currentRoute;
                                    Navigator.pop(context);
                                    if (isStaff) {
                                      if (captured ==
                                          StaffAttendanceProfile.routeName) {
                                        return;
                                      }
                                      _openLoggedInStaffAttendanceProfile(
                                        navigator,
                                      );
                                      return;
                                    }
                                    if (captured !=
                                        StaffAttendanceTabbedView.routeName) {
                                      context.go(
                                        StaffAttendanceTabbedView.routeName,
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        if (showAvailabilityMenu)
                          _CustomExpansionTile(
                            title: 'Availability',
                            icon: MediaRes.attendanceIcon,
                            isExpansionEnabled: true,
                            children: [
                              if (showIndividualMovement)
                                DrawerListTile(
                                  title: 'Individual Movement',
                                  leading: const Icon(
                                    Icons.directions_walk,
                                    color: AppColors.themeColor,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (_currentRoute !=
                                        IndividualMovementScreen.routeName) {
                                      context.go(
                                        IndividualMovementScreen.routeName,
                                      );
                                    }
                                  },
                                ),
                              if (showFutureAvailability)
                                DrawerListTile(
                                  title: 'Future Availability',
                                  leading: const Icon(
                                    Icons.calendar_month,
                                    color: AppColors.themeColor,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (_currentRoute !=
                                        FutureAvailabilityScreen.routeName) {
                                      context.go(
                                        FutureAvailabilityScreen.routeName,
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        if (canViewActivities)
                          _CustomExpansionTile(
                            title: 'Activities',
                            icon: MediaRes.activitesIcon,
                            isCurrentRoute:
                                _currentRoute == ActivityFeedScreen.routeName,
                            onTap: () {
                              Navigator.pop(context);
                              if (_currentRoute !=
                                  ActivityFeedScreen.routeName) {
                                context.go(ActivityFeedScreen.routeName);
                              }
                            },
                          ),
                        _CustomExpansionTile(
                          title: 'Events',
                          icon: MediaRes.calenderClockIcon,
                          isCurrentRoute:
                              _currentRoute == EventsScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != EventsScreen.routeName) {
                              context.go(EventsScreen.routeName);
                            }
                          },
                        ),
                        // Tasks — admin/staff only. This sits in the
                        // non-parent branch so guardians never see the
                        // module, its navigation, or any task data
                        // (PRD §5.2).
                        _CustomExpansionTile(
                          title: 'Tasks',
                          icon: MediaRes.tasksIcon,
                          isCurrentRoute:
                              _currentRoute == TasksScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != TasksScreen.routeName) {
                              context.go(TasksScreen.routeName);
                            }
                          },
                        ),
                        // Assessments — admin/staff only. Sits in the
                        // non-parent branch so guardians never see the module,
                        // its navigation, or any assessment data (PRD §3.2).
                        _CustomExpansionTile(
                          title: 'Assessments',
                          icon: MediaRes.documents_drawer_Icon,
                          isCurrentRoute:
                              _currentRoute == AssessmentsHomeScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute !=
                                AssessmentsHomeScreen.routeName) {
                              context.go(AssessmentsHomeScreen.routeName);
                            }
                          },
                        ),
                        if (showStaffMessagingDrawer ||
                            showParentMessagingDrawer ||
                            showParentNewsletterDrawer)
                          _CustomExpansionTile(
                            title: 'Communication',
                            icon: MediaRes.communicationIcon,
                            isExpansionEnabled: true,
                            children: [
                              if (showStaffMessagingDrawer)
                                DrawerListTile(
                                  title: 'Staff Messaging',
                                  leading: SvgPicture.asset(
                                    MediaRes.staffMessaging,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(MessagingScreen.routeName);
                                  },
                                ),
                              if (showParentMessagingDrawer)
                                DrawerListTile(
                                  title: 'Parent Messaging',
                                  leading: SvgPicture.asset(
                                    MediaRes.parentMessaging,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(MessagingScreen.routeName);
                                  },
                                ),
                              if (showParentNewsletterDrawer)
                                DrawerListTile(
                                  title: 'Newsletter',
                                  leading: SvgPicture.asset(
                                    MediaRes.newsletter,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(MessagingScreen.newsletterRoute);
                                  },
                                ),
                            ],
                          ),
                        // Scheduling
                        if (showAdminAttendanceMenu)
                          _CustomExpansionTile(
                            title: 'Scheduling',
                            icon: MediaRes.calenderClockIcon,
                            isExpansionEnabled: true,
                            children: [
                              // Staff persona only ever sees their own schedule —
                              // hide the school-wide Classroom Scheduling entry.
                              if (!isStaff)
                                DrawerListTile(
                                  title: 'Classroom Scheduling',
                                  leading: SvgPicture.asset(
                                    MediaRes.classroom_Schedule_drawer_icon,
                                  ),
                                  onTap: () {
                                    final captured = _currentRoute;
                                    Navigator.pop(context);
                                    if (captured !=
                                        SchedulingScreen.routeName) {
                                      context.go(SchedulingScreen.routeName);
                                    }
                                  },
                                ),
                              DrawerListTile(
                                title: 'Staff Scheduling',
                                leading: SvgPicture.asset(
                                  MediaRes.staff_Schedule_drawer_icon,
                                ),
                                onTap: () {
                                  final captured = _currentRoute;
                                  Navigator.pop(context);
                                  if (captured !=
                                      StaffSchedulingScreen.routeName) {
                                    context.go(StaffSchedulingScreen.routeName);
                                  }
                                },
                              ),
                            ],
                          ),
                        if (canViewBilling)
                          _CustomExpansionTile(
                            title: 'Billing',
                            icon: MediaRes.billing_drawer_icon,
                            onTap: () {
                              Navigator.pop(context);
                              if (_currentRoute != BillingScreen.routeName) {
                                context.go(BillingScreen.routeName);
                              }
                            },
                          ),
                        _CustomExpansionTile(
                          title: 'Reports',
                          icon: MediaRes.documents_drawer_Icon,
                          preserveIconColors: true,
                          isCurrentRoute:
                              _currentRoute == ReportsScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != ReportsScreen.routeName) {
                              context.go(ReportsScreen.routeName);
                            }
                          },
                        ),
                        if (showSettingsMenu)
                          _CustomExpansionTile(
                            title: 'Settings',
                            icon: MediaRes.settings_drawer_Blue,
                            isExpansionEnabled: true,
                            children: [
                              DrawerListTile(
                                title: 'Privacy Policy',
                                leading: SvgPicture.asset(
                                  MediaRes.settings_drawer_Blue,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: () {},
                              ),
                              DrawerListTile(
                                title: 'Terms & Conditions',
                                leading: SvgPicture.asset(
                                  MediaRes.settings_drawer_Blue,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: () {},
                              ),
                            ],
                          ),
                      ],
                      _CustomExpansionTile(
                        title: 'Logout',
                        icon: MediaRes.logout,
                        onTap: () {
                          Navigator.pop(context);
                          SignOutScreen.show(context);
                        },
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Version : 1.3.9",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomExpansionTile extends StatefulWidget {
  final String title;
  final String icon;
  final List<Widget> children;
  final bool isExpansionEnabled;
  final bool isCurrentRoute;
  final VoidCallback? onTap;
  final bool isDashboard;

  /// When true, the icon's native colors (e.g. gradient fills, multi-color
  /// strokes) are preserved instead of being flattened by a single
  /// [ColorFilter]. Use for SVGs that ship their own gradient like the
  /// Reports/Documents drawer icon.
  final bool preserveIconColors;

  const _CustomExpansionTile({
    required this.title,
    required this.icon,
    this.children = const [],
    this.isExpansionEnabled = false,
    this.isCurrentRoute = false,
    this.onTap,
    this.isDashboard = false,
    this.preserveIconColors = false,
  });

  @override
  State<_CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<_CustomExpansionTile> {
  bool _isExpanded = false;

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (!widget.isExpansionEnabled) {
      return;
    }
  }

  Color _getIconColor() {
    if (widget.isCurrentRoute) {
      return AppColors.themeColor;
    }
    return _isExpanded ? AppColors.themeColor : Colors.white;
  }

  Color _getTextColor() {
    if (widget.isCurrentRoute) {
      return AppColors.themeColor;
    }
    return _isExpanded ? AppColors.themeColor : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: widget.isCurrentRoute || _isExpanded
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (widget.isCurrentRoute || _isExpanded)
              const BoxShadow(
                blurRadius: 4,
                color: Colors.black26,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: widget.isExpansionEnabled
            ? ExpansionTile(
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                maintainState: true,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isExpanded = expanded;
                  });
                },
                leading: SvgPicture.asset(
                  widget.icon,
                  colorFilter: widget.preserveIconColors
                      ? null
                      : ColorFilter.mode(_getIconColor(), BlendMode.srcIn),
                ),
                iconColor: AppColors.themeColor,
                collapsedIconColor: Colors.white,
                title: Text(
                  widget.title,
                  maxLines: 1,
                  style: TextStyle(color: _getTextColor()),
                ),
                children: widget.children,
                trailing: const Icon(Icons.keyboard_arrow_down),
              )
            : ListTile(
                leading: SvgPicture.asset(
                  widget.icon,
                  colorFilter: widget.preserveIconColors
                      ? null
                      : ColorFilter.mode(
                          widget.isCurrentRoute
                              ? AppColors.themeColor
                              : Colors.white,
                          BlendMode.srcIn,
                        ),
                ),
                title: Text(
                  widget.title,
                  maxLines: 1,
                  style: TextStyle(
                    color: widget.isCurrentRoute
                        ? AppColors.themeColor
                        : Colors.white,
                  ),
                ),
                tileColor: (widget.isDashboard && widget.isCurrentRoute)
                    ? Colors.white
                    : (!widget.isDashboard && widget.isCurrentRoute)
                    ? Colors.white
                    : Colors.transparent,
                selected: widget.isCurrentRoute,
                selectedTileColor: Colors.white,
              ),
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  final String title;
  final Widget leading;
  final VoidCallback onTap;
  final double horizontalTitleGap;
  final Color? textColor;

  const DrawerListTile({
    super.key,
    required this.title,
    required this.leading,
    required this.onTap,
    this.horizontalTitleGap = 16,
    this.textColor = AppColors.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      horizontalTitleGap: horizontalTitleGap,
      leading: leading,
      title: Text(title, maxLines: 1, style: TextStyle(color: textColor)),
    );
  }
}
