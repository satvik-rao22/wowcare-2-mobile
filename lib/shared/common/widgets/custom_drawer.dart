import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
// ignore: unused_import — kept for the temporary gate below
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/presentation/features/events/view/events_screen.dart';
// ignore: unused_import — kept for the temporary gate below
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/presentation/features/tasks/view/tasks_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/admin_chat_host_screen.dart';
import 'package:wowcare/presentation/features/newsletter/view/parent_newsletter_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/staff/model/staff_route_args.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/classroom/view/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/features/scheduling/view/scheduling_screen.dart';
import '../../../presentation/features/scheduling/view/staff_scheduling_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/shared/common/view/web_view_screen.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_cubit.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/context_switch_cache_cleaner.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/user_details_school_roles.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/availability/view/future_availability_screen.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';

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

  /// Accordion behavior — title of the one top-level expandable drawer
  /// section (Communication, Attendance, Availability, Scheduling,
  /// Settings, ...) currently open, or null when none is. Opening one
  /// collapses whichever other section was previously open.
  String? _expandedDrawerSection;

  void _onDrawerSectionExpansionChanged(String title, bool expanded) {
    setState(() {
      _expandedDrawerSection = expanded ? title : null;
    });
  }

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

  /// Closes the drawer, then navigates on the NEXT frame.
  ///
  /// Closing a [Scaffold] drawer pops its [LocalHistoryEntry] from the current
  /// page. Inside [StatefulShellRoute] that pop makes go_router re-sync the
  /// route info to the branch's CURRENT location on the next microtask — which
  /// runs after a synchronous `context.go(...)` and clobbers it, bouncing the
  /// user back to the dashboard. Deferring the navigation past that frame makes
  /// it stick. Uses the global [appRouter] (not `context.go`) because this
  /// drawer's [State] is often disposed once the drawer finishes closing.
  void _navigate(String location, {Object? extra}) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // appRouterGo (not a bare appRouter.go) — the drawer bypasses
      // CustomNavigationBar's tap handler entirely, so this is what tells a
      // kept-alive branch screen (e.g. Activities, Classroom) it just became
      // visible again when reached via a drawer link. See appRouterGo's doc
      // comment / TabVisibilityEvents for why that's needed at all.
      appRouterGo(location, extra: extra);
    });
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
      print(
        'CustomDrawer: _loadSchoolContext: orgCode=$orgCode, schoolCode=$schoolCode, selectedName=$selectedName',
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

      // Hide schools that are not yet ACTIVE (e.g. still PENDING approval)
      // from the switcher, using the cached `/users/details` snapshot. An
      // unknown/missing status is treated as active so a stale snapshot
      // never hides a school the user should be able to reach.
      if (orgCode != null && orgCode.isNotEmpty) {
        final cachedUsers = await readCachedUserAccessDetailsUsers(storage);
        if (cachedUsers.isNotEmpty) {
          schoolsForOrg = schoolsForOrg.where((e) {
            final status = schoolStatusFromUserDetails(
              cachedUsers,
              orgCode,
              e['schoolCode'] ?? '',
            );
            return status == null || status == 'ACTIVE';
          }).toList();
        }
      }

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
              backgroundColor: AppPalette.surfaceCard,
              radius: 28,
              backgroundImage: AssetImage(MediaRes.appLogo),
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
                      color: AppPalette.textPrimary,
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
                    color: AppPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                _isSchoolDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppPalette.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
        if (_isSchoolDropdownOpen) ...[
          const SizedBox(height: 8),
          Container(
            decoration: AppSurfaces.sub(radius: 12, bordered: true),
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
                          ? AppPalette.surfaceSelected
                          : AppColors.transparentColor,
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
                              color: isSelected
                                  ? AppPalette.brandDark
                                  : AppPalette.textPrimary,
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
                            color: AppPalette.brandDark,
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

    // Re-verify from the backend (not just the possibly-stale dropdown list)
    // that the target school is still active before switching into it.
    if (isSchoolChanged) {
      final blockMessage = await authCubit.verifySchoolActiveOrBlockMessage(
        organizationCode: _currentOrgCode!,
        schoolCode: schoolCode,
      );
      if (blockMessage != null) {
        if (!mounted) return;
        setState(() => _isSchoolDropdownOpen = false);
        CoreUtils.showTopSnackBar(
          context: context,
          message: blockMessage,
          isError: true,
        );
        return;
      }
    }

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

    // Tell every kept-alive branch screen (Dashboard, Classroom, Activity,
    // Messaging, Billing) to reload fresh for the new school. Only when the
    // school actually changed — re-selecting the same school is a no-op.
    if (isSchoolChanged) {
      SchoolSwitchEvents.notifySwitched();
    }

    // Close drawer and send user to Dashboard for the newly selected school.
    if (!mounted) return;
    _navigate(DashboardScreen.routeName);
  }

  /// Clears every cache layer so a school switch starts from a clean slate —
  /// see [clearAllCachesForContextSwitch] for exactly what's covered. Shared
  /// with the persona-switch path (user_profile_screen.dart) and the
  /// FCM-driven school switch (active_school_switcher.dart) so a cache added
  /// to one module is covered for every switch kind automatically.
  Future<void> _clearAllCachesForSchoolSwitch() async {
    await clearAllCachesForContextSwitch(serviceLocator<StorageService>());
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
        final now = AppTime.now();
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
          'sibling': const StudentSiblingInfo(),
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
        extra: StaffProfileArgs(
          staffCode: profile.staffCode,
          name: profile.fullName.trim().isNotEmpty
              ? profile.fullName.trim()
              : '-',
          classroom: classroom,
          designation: profile.designation,
          phoneNumber: profile.phoneNumber,
          employmentStatus: profile.status,
        ),
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
    final unreadState = context.watch<UnreadBadgeCubit>().state;
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
    // TEMPORARY: Events and Tasks are forced visible in the drawer.
    //
    // The backend's `users/details` payload does not list EVENT / EVENT_RSVP /
    // HOLIDAY / CALENDAR / TASK for any school on this org, even though the
    // events-todo service happily serves the same account (GET calendar/feed,
    // occurrences, holidays and tasks/assignments all 200, POST events and
    // tasks both 201). The gate below is therefore hiding a module that works.
    //
    // Restore both lines once the permission payload includes those modules.
    // NOTE: this unhides the drawer entries only. The router's module guard in
    // lib/src/app_router.dart and the per-tab `canReadModule` checks inside
    // events_screen.dart / tasks_screen.dart are untouched, so tapping either
    // entry still bounces back to the dashboard.
    // final canViewEvents = EventAccess.canOpenModule(roleProvider);
    // final canViewTasks = TaskAccess.canAccessModule(roleProvider);
    const canViewEvents = true;
    const canViewTasks = true;
    final showParentMessagingDrawer = roleProvider.canReadModule(
      AppAccessModules.parentMessaging,
    );
    final showParentNewsletterDrawer = roleProvider.canReadModule(
      AppAccessModules.newsletter,
    );
    final showStaffMessagingDrawer = roleProvider.canReadModule(
      AppAccessModules.staffMessaging,
    );
    // Admin Chat: visible to admins/directors and parents; hidden for staff/teachers.
    final showAdminChatDrawer = !isStaff;
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
    final showReportsDrawer =
        !roleProvider.usesGranularModuleAccess ||
        roleProvider.canOpenModule(AppAccessModules.reports);
    // Scheduling sub-items are gated on their own modules (a staff persona only
    // ever sees their own schedule, so Classroom Scheduling also needs !isStaff).
    final showClassroomScheduling =
        !isStaff &&
        roleProvider.canOpenModule(AppAccessModules.classroomSchedule);
    final showStaffScheduling = roleProvider.canOpenModule(
      AppAccessModules.staffScheduling,
    );
    final showSchedulingMenu = showClassroomScheduling || showStaffScheduling;
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
        decoration: AppSurfaces.tray(),
        child: Column(
          children: [
            _header(),
            const Divider(
              color: AppPalette.borderHairline,
              thickness: 1,
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
                          suppressRouteHighlight:
                              _expandedDrawerSection != null,
                          onTap: () => _navigate(DashboardScreen.routeName),
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
                          suppressRouteHighlight:
                              _expandedDrawerSection != null,
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
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
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
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () =>
                                _navigate(ActivityFeedScreen.routeName),
                          ),
                        if (canViewEvents)
                          _CustomExpansionTile(
                            title: 'Events',
                            icon: MediaRes.calenderClockIcon,
                            isCurrentRoute:
                                _currentRoute == EventsScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () => _navigate(EventsScreen.routeName),
                          ),
                        if (showParentMessagingDrawer ||
                            showParentNewsletterDrawer ||
                            showAdminChatDrawer)
                          _CustomExpansionTile(
                            title: 'Communication',
                            icon: MediaRes.communicationIcon,
                            isCurrentRoute:
                                _currentRoute == MessagingScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null &&
                                _expandedDrawerSection != 'Communication',
                            isExpansionEnabled: true,
                            expandedOverride:
                                _expandedDrawerSection == 'Communication',
                            onExpansionChanged: (expanded) =>
                                _onDrawerSectionExpansionChanged(
                                  'Communication',
                                  expanded,
                                ),
                            children: [
                              // Flattened directly under "Messages" (no
                              // intermediate "Parent Messaging" nesting) —
                              // Room Chat and Admin Chat are the two options
                              // a parent needs, one tap away.
                              if (showParentMessagingDrawer)
                                DrawerListTile(
                                  title: 'Room Chat',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.classroom_drawer_icon,
                                    color: AppPalette.textPrimary,
                                  ),
                                  trailing: _UnreadBadge(
                                    count: unreadState.unreadFor(
                                      ConversationType.roomChat,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(
                                      MessagingScreen.parentMessagingRoute,
                                    );
                                  },
                                ),
                              if (showAdminChatDrawer)
                                DrawerListTile(
                                  title: 'Admin Chat',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.parentMessaging,
                                    color: AppPalette.textPrimary,
                                  ),
                                  trailing: _UnreadBadge(
                                    count: unreadState.unreadFor(
                                      ConversationType.adminChat,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(AdminChatHostScreen.routeName);
                                  },
                                ),
                              if (showParentNewsletterDrawer)
                                DrawerListTile(
                                  title: 'Newsletter',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.newsletter,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () => _navigate(
                                    ParentNewsletterScreen.routeName,
                                  ),
                                ),
                            ],
                          ),
                        if (canViewBilling)
                          _CustomExpansionTile(
                            title: 'Billing',
                            icon: MediaRes.billing_drawer_icon,
                            isCurrentRoute:
                                _currentRoute == ParentBillingScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () =>
                                _navigate(ParentBillingScreen.routeName),
                          ),
                      ] else ...[
                        // Admin menu items
                        if (canViewClassrooms)
                          _CustomExpansionTile(
                            title: 'Classrooms',
                            icon: MediaRes.classroom_drawer_icon,
                            isCurrentRoute:
                                _currentRoute == ClassroomScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            // Classroom is a tab branch — go (not push) so the
                            // bottom-nav switches to its tab and we don't stack
                            // a second copy on the current branch's navigator.
                            onTap: () => _navigate(ClassroomScreen.routeName),
                          ),
                        if (canViewStudents)
                          _CustomExpansionTile(
                            title: 'Students',
                            icon: MediaRes.students_drawer_icon,
                            isCurrentRoute:
                                _currentRoute == StudentScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () => _navigate(StudentScreen.routeName),
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
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () async {
                              if (isStaff) {
                                final navigator = Navigator.of(context);
                                final captured = _currentRoute;
                                Navigator.pop(context);
                                if (captured == StaffProfileScreen.routeName) {
                                  return;
                                }
                                await _openLoggedInStaffProfile(navigator);
                                return;
                              }
                              _navigate(StaffScreen.routeName);
                            },
                          ),

                        if (showAdminAttendanceMenu)
                          _CustomExpansionTile(
                            title: 'Attendance',
                            icon: MediaRes.attendanceIcon,
                            isExpansionEnabled: true,
                            expandedOverride:
                                _expandedDrawerSection == 'Attendance',
                            onExpansionChanged: (expanded) =>
                                _onDrawerSectionExpansionChanged(
                                  'Attendance',
                                  expanded,
                                ),
                            children: [
                              if (showStudentAttendance)
                                DrawerListTile(
                                  title: 'Student Attendance',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.studentAttendanceDrawer,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () => _navigate(
                                    StudentAttendanceTabbedView.routeName,
                                  ),
                                ),
                              if (showStaffAttendance)
                                DrawerListTile(
                                  title: isStaff
                                      ? 'My Attendance'
                                      : 'Staff Attendance',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.staffAttendanceDrawer,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () {
                                    if (isStaff) {
                                      final navigator = Navigator.of(context);
                                      final captured = _currentRoute;
                                      Navigator.pop(context);
                                      if (captured ==
                                          StaffAttendanceProfile.routeName) {
                                        return;
                                      }
                                      _openLoggedInStaffAttendanceProfile(
                                        navigator,
                                      );
                                      return;
                                    }
                                    _navigate(
                                      StaffAttendanceTabbedView.routeName,
                                    );
                                  },
                                ),
                            ],
                          ),
                        if (showAvailabilityMenu)
                          _CustomExpansionTile(
                            title: 'Availability',
                            icon: MediaRes.attendanceIcon,
                            isExpansionEnabled: true,
                            expandedOverride:
                                _expandedDrawerSection == 'Availability',
                            onExpansionChanged: (expanded) =>
                                _onDrawerSectionExpansionChanged(
                                  'Availability',
                                  expanded,
                                ),
                            children: [
                              if (showIndividualMovement)
                                DrawerListTile(
                                  title: 'Individual Movement',
                                  leading: const Icon(
                                    Icons.directions_walk,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () => _navigate(
                                    IndividualMovementScreen.routeName,
                                  ),
                                ),
                              if (showFutureAvailability)
                                DrawerListTile(
                                  title: 'Future Availability',
                                  leading: const Icon(
                                    Icons.calendar_month,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () => _navigate(
                                    FutureAvailabilityScreen.routeName,
                                  ),
                                ),
                            ],
                          ),
                        if (canViewActivities)
                          _CustomExpansionTile(
                            title: 'Activities',
                            icon: MediaRes.activitesIcon,
                            isCurrentRoute:
                                _currentRoute == ActivityFeedScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () =>
                                _navigate(ActivityFeedScreen.routeName),
                          ),
                        if (canViewEvents)
                          _CustomExpansionTile(
                            title: 'Events',
                            icon: MediaRes.calenderClockIcon,
                            isCurrentRoute:
                                _currentRoute == EventsScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () => _navigate(EventsScreen.routeName),
                          ),
                        // Guardians/parents have no Tasks access at all, so
                        // the entry point itself must not exist for them —
                        // this block is the non-parent (staff/admin) branch.
                        if (canViewTasks)
                          _CustomExpansionTile(
                            title: 'Tasks',
                            icon: MediaRes.tasksIcon,
                            isCurrentRoute:
                                _currentRoute == TasksScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () => _navigate(TasksScreen.routeName),
                          ),
                        if (showStaffMessagingDrawer ||
                            showParentMessagingDrawer ||
                            showParentNewsletterDrawer ||
                            showAdminChatDrawer)
                          _CustomExpansionTile(
                            title: 'Communication',
                            icon: MediaRes.communicationIcon,
                            isExpansionEnabled: true,
                            expandedOverride:
                                _expandedDrawerSection == 'Communication',
                            onExpansionChanged: (expanded) =>
                                _onDrawerSectionExpansionChanged(
                                  'Communication',
                                  expanded,
                                ),
                            children: [
                              if (showStaffMessagingDrawer)
                                DrawerListTile(
                                  title: 'Staff Messaging',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.staffMessaging,
                                    color: AppPalette.textPrimary,
                                  ),
                                  trailing: _UnreadBadge(
                                    count: unreadState.unreadFor(
                                      ConversationType.staffDirect,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(
                                      MessagingScreen.staffMessagingRoute,
                                    );
                                  },
                                ),
                              if (showParentMessagingDrawer ||
                                  showAdminChatDrawer)
                                _NestedExpansionTile(
                                  title: 'Parent Messaging',
                                  icon: MediaRes.parentMessaging,
                                  children: [
                                    if (showParentMessagingDrawer)
                                      DrawerListTile(
                                        title: 'Room Chat',
                                        leading: _DrawerGlyph(
                                          asset: MediaRes.parentMessaging,
                                          color: AppPalette.textPrimary,
                                        ),
                                        trailing: _UnreadBadge(
                                          count: unreadState.unreadFor(
                                            ConversationType.roomChat,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.go(
                                            MessagingScreen
                                                .parentMessagingRoute,
                                          );
                                        },
                                      ),
                                    if (showAdminChatDrawer)
                                      DrawerListTile(
                                        title: 'Admin Chat',
                                        leading: _DrawerGlyph(
                                          asset: MediaRes.parentMessaging,
                                          color: AppPalette.textPrimary,
                                        ),
                                        trailing: _UnreadBadge(
                                          count: unreadState.unreadFor(
                                            ConversationType.adminChat,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.go(
                                            AdminChatHostScreen.routeName,
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              if (showParentNewsletterDrawer)
                                DrawerListTile(
                                  title: 'Newsletter',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.newsletter,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () => _navigate(
                                    MessagingScreen.newsletterRoute,
                                  ),
                                ),
                            ],
                          ),
                        // Scheduling
                        if (showSchedulingMenu)
                          _CustomExpansionTile(
                            title: 'Scheduling',
                            icon: MediaRes.calenderClockIcon,
                            isExpansionEnabled: true,
                            expandedOverride:
                                _expandedDrawerSection == 'Scheduling',
                            onExpansionChanged: (expanded) =>
                                _onDrawerSectionExpansionChanged(
                                  'Scheduling',
                                  expanded,
                                ),
                            children: [
                              if (showClassroomScheduling)
                                DrawerListTile(
                                  title: 'Classroom Scheduling',
                                  leading: _DrawerGlyph(
                                    asset:
                                        MediaRes.classroom_Schedule_drawer_icon,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () =>
                                      _navigate(SchedulingScreen.routeName),
                                ),
                              if (showStaffScheduling)
                                DrawerListTile(
                                  title: 'Staff Scheduling',
                                  leading: _DrawerGlyph(
                                    asset: MediaRes.staff_Schedule_drawer_icon,
                                    color: AppPalette.textPrimary,
                                  ),
                                  onTap: () => _navigate(
                                    StaffSchedulingScreen.routeName,
                                  ),
                                ),
                            ],
                          ),
                        if (canViewBilling)
                          _CustomExpansionTile(
                            title: 'Billing',
                            icon: MediaRes.billing_drawer_icon,
                            onTap: () => _navigate(BillingScreen.routeName),
                          ),
                        if (showReportsDrawer)
                          _CustomExpansionTile(
                            title: 'Reports',
                            icon: MediaRes.documents_drawer_Icon,
                            isCurrentRoute:
                                _currentRoute == ReportsScreen.routeName,
                            suppressRouteHighlight:
                                _expandedDrawerSection != null,
                            onTap: () => _navigate(ReportsScreen.routeName),
                          ),
                        // if (showSettingsMenu)
                        //   _CustomExpansionTile(
                        //     title: 'Settings',
                        //     icon: MediaRes.settings_drawer_Blue,
                        //     isExpansionEnabled: true,
                        //     expandedOverride:
                        //         _expandedDrawerSection == 'Settings',
                        //     onExpansionChanged: (expanded) =>
                        //         _onDrawerSectionExpansionChanged(
                        //           'Settings',
                        //           expanded,
                        //         ),
                        //     children: [
                        //       DrawerListTile(
                        //         title: 'Privacy Policy',
                        //         leading: SvgPicture.asset(
                        //           MediaRes.settings_drawer_Blue,
                        //           colorFilter: const ColorFilter.mode(
                        //             AppColors.themeColor,
                        //             BlendMode.srcIn,
                        //           ),
                        //         ),
                        //         onTap: () {},
                        //       ),
                        //       DrawerListTile(
                        //         title: 'Terms & Conditions',
                        //         leading: SvgPicture.asset(
                        //           MediaRes.settings_drawer_Blue,
                        //           colorFilter: const ColorFilter.mode(
                        //             AppColors.themeColor,
                        //             BlendMode.srcIn,
                        //           ),
                        //         ),
                        //         onTap: () {},
                        //       ),
                        //     ],
                        //   ),

                        _CustomExpansionTile(
                          title: 'Privacy Policy',
                          icon: MediaRes.settings_drawer_Blue,
                          suppressRouteHighlight:
                              _expandedDrawerSection != null,
                          onTap: () => openWebViewScreen(
                            context,
                            url: 'https://childcarewow.com/privacy/',
                            title: 'Privacy Policy',
                          ),
                        ),
                        _CustomExpansionTile(
                          title: 'Terms & Conditions',
                          icon: MediaRes.dailyActivityDrawer,
                          suppressRouteHighlight:
                              _expandedDrawerSection != null,
                          onTap: () => openWebViewScreen(
                            context,
                            url: 'https://childcarewow.com/terms/',
                            title: 'Terms & Conditions',
                          ),
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
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.hasData
                              ? snapshot.data!.version
                              : '';
                          return Text(
                            version.isNotEmpty ? "Version : $version" : "",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppPalette.textMuted),
                          );
                        },
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

/// One drawer destination's glyph, in a box the same size on every row.
///
/// The drawer's assets do not agree on a size: most are 24x25, billing is
/// 17x25, the classroom one 24x26, the calendar 26x26 and logout 18x18. Drawn
/// at their intrinsic size no two rows put the glyph in the same place, and a
/// narrow one pulls its label left with it, because a `ListTile` sizes its
/// leading slot to whatever it is given. A fixed box fixes both.
class _DrawerGlyph extends StatelessWidget {
  const _DrawerGlyph({required this.asset, required this.color});

  final String asset;
  final Color color;

  /// Matches `AppDimensions.iconMd`, which is what the bottom bar uses, so
  /// the two pieces of chrome agree.
  static const double _box = AppDimensions.iconMd;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _box,
    height: _box,
    child: Center(
      child: AppIcon(asset, size: _box, color: color),
    ),
  );
}

class _CustomExpansionTile extends StatefulWidget {
  final String title;
  final String icon;
  final List<Widget> children;
  final bool isExpansionEnabled;
  final bool isCurrentRoute;
  final VoidCallback? onTap;
  final bool isDashboard;

  /// When non-null, this tile's expanded/collapsed state is driven by the
  /// parent (accordion behavior — only one top-level drawer section open at
  /// a time) instead of being managed internally.
  final bool? expandedOverride;

  /// Notifies the parent when this tile is expanded/collapsed by the user,
  /// so it can collapse any other currently-open section.
  final ValueChanged<bool>? onExpansionChanged;

  /// True while a *different* accordion section is open elsewhere in the
  /// drawer. Suppresses this tile's [isCurrentRoute] highlight so the white
  /// background only ever shows on the one section the user most recently
  /// interacted with — otherwise a single (non-expandable) tile for the
  /// still-active route stayed highlighted forever alongside whichever
  /// accordion section was opened afterwards, since opening an accordion
  /// item doesn't itself navigate (so [isCurrentRoute] never goes false).
  final bool suppressRouteHighlight;

  const _CustomExpansionTile({
    required this.title,
    required this.icon,
    this.children = const [],
    this.isExpansionEnabled = false,
    this.isCurrentRoute = false,
    this.onTap,
    this.isDashboard = false,
    this.expandedOverride,
    this.onExpansionChanged,
    this.suppressRouteHighlight = false,
  });

  @override
  State<_CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<_CustomExpansionTile> {
  bool _isExpanded = false;
  final _expansionController = ExpansibleController();

  bool get _effectiveIsCurrentRoute =>
      widget.isCurrentRoute && !widget.suppressRouteHighlight;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandedOverride ?? false;
  }

  @override
  void didUpdateWidget(covariant _CustomExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandedOverride != null &&
        widget.expandedOverride != _isExpanded) {
      final shouldExpand = widget.expandedOverride!;
      if (shouldExpand) {
        _expansionController.expand();
      } else {
        _expansionController.collapse();
      }
      // Drive the white-background highlight directly rather than relying
      // on ExpansionTile's own onExpansionChanged callback — that callback
      // doesn't reliably fire for controller-driven (programmatic)
      // expand/collapse, which previously left a stale white background on
      // a section after the accordion moved on to a different one.
      setState(() {
        _isExpanded = shouldExpand;
      });
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (!widget.isExpansionEnabled) {
      return;
    }
  }

  /// True when this tile is the solid pink squircle: the route you are on,
  /// and not opened out into a panel. An expanded section is a well holding
  /// its children, so it takes navy ink like the tray does.
  bool get _isActiveTile => _effectiveIsCurrentRoute && !_isExpanded;

  Color _getIconColor() =>
      _isActiveTile ? AppPalette.onBrand : AppPalette.textPrimary;

  Color _getTextColor() =>
      _isActiveTile ? AppPalette.onBrand : AppPalette.textPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: _isActiveTile
            ? AppSurfaces.navActive(radius: 12)
            : _isExpanded
            ? AppSurfaces.sub(radius: 12)
            : const SkeuDecoration(),
        child: widget.isExpansionEnabled
            ? ExpansionTile(
                controller: _expansionController,
                backgroundColor: AppColors.transparentColor,
                collapsedBackgroundColor: AppColors.transparentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                maintainState: true,
                onExpansionChanged: (expanded) {
                  widget.onExpansionChanged?.call(expanded);
                  setState(() {
                    _isExpanded = expanded;
                  });
                },
                leading: _DrawerGlyph(
                  asset: widget.icon,
                  color: _getIconColor(),
                ),
                iconColor: AppPalette.textPrimary,
                collapsedIconColor: _getIconColor(),
                title: Text(
                  widget.title,
                  maxLines: 1,
                  style: TextStyle(color: _getTextColor()),
                ),
                children: widget.children,
                trailing: const Icon(Icons.keyboard_arrow_down),
              )
            : ListTile(
                leading: _DrawerGlyph(
                  asset: widget.icon,
                  color: _getIconColor(),
                ),
                title: Text(
                  widget.title,
                  maxLines: 1,
                  style: TextStyle(color: _getTextColor()),
                ),
                // The pink squircle is painted by the Container above, so the
                // tile itself stays clear and never doubles the fill.
                tileColor: AppColors.transparentColor,
                selected: _effectiveIsCurrentRoute,
                selectedTileColor: AppColors.transparentColor,
              ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppPalette.brand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppPalette.textOnDark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
  final Widget? trailing;

  const DrawerListTile({
    super.key,
    required this.title,
    required this.leading,
    required this.onTap,
    this.horizontalTitleGap = 16,
    this.textColor = AppPalette.textPrimary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      horizontalTitleGap: horizontalTitleGap,
      leading: leading,
      title: Text(title, maxLines: 1, style: TextStyle(color: textColor)),
      trailing: trailing,
    );
  }
}

/// A sub-menu expansion tile for nesting inside an already-expanded
/// [_CustomExpansionTile] panel (e.g. "Parent Messaging" inside
/// "Communication"). Unlike [_CustomExpansionTile] — which flips to warm
/// white on the pink squircle when it is the active route — this always uses
/// navy ink, matching the sibling [DrawerListTile] items (e.g. "Staff
/// Messaging") it sits alongside inside the panel's well.
class _NestedExpansionTile extends StatelessWidget {
  final String title;
  final String icon;
  final List<Widget> children;

  const _NestedExpansionTile({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      // Clear, so the panel's own well shows through rather than stacking a
      // second tone on top of it.
      backgroundColor: AppColors.transparentColor,
      collapsedBackgroundColor: AppColors.transparentColor,
      // Suppresses Flutter's default top/bottom divider border that
      // ExpansionTile draws while expanded.
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: AppPalette.textPrimary,
      collapsedIconColor: AppPalette.textPrimary,
      leading: _DrawerGlyph(asset: icon, color: AppPalette.textPrimary),
      title: Text(
        title,
        maxLines: 1,
        style: const TextStyle(color: AppPalette.textPrimary),
      ),
      // Indent sub-items relative to this tile's own leading icon so they
      // read as nested children (e.g. "Room Chat"/"Admin Chat" under
      // "Parent Messaging") rather than flush-left siblings.
      children: children
          .map(
            (child) =>
                Padding(padding: const EdgeInsets.only(left: 16), child: child),
          )
          .toList(),
    );
  }
}
