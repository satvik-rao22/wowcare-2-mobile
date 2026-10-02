import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
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

      // Hide schools that are not yet ACTIVE (e.g. still PENDING approval),
      // or that this user has no role at all, from the switcher — using the
      // cached `/users/details` snapshot. `names-by-org` lists every school
      // in the organization regardless of this user's own access, so without
      // this an account with a role at only one school of three saw all
      // three in the dropdown (two of them unusable, just padding the list).
      // A missing snapshot entry is only let through for the CURRENTLY
      // active school — never hidden just because the cache is momentarily
      // stale — not for every other school in the org.
      if (orgCode != null && orgCode.isNotEmpty) {
        final cachedUsers = await readCachedUserAccessDetailsUsers(storage);
        if (cachedUsers.isNotEmpty) {
          schoolsForOrg = schoolsForOrg.where((e) {
            final code = e['schoolCode'] ?? '';
            final status = schoolStatusFromUserDetails(
              cachedUsers,
              orgCode,
              code,
            );
            if (status != null) return status == 'ACTIVE';
            return code == schoolCode;
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
    // Matches WowInventory's drawer header layout: logo + title on one row,
    // then the school switcher as its own full-width block underneath —
    // not squeezed into the title's column beside the avatar, which left it
    // too narrow and truncated names early.
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 28,
                  backgroundImage: AssetImage(MediaRes.appLogo),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'WowCare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // School switcher dropdown (for current organization)
            _buildSchoolSwitcher(),
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

    // WowInventory's original drawer style (ported here to match): white70
    // text in a tinted box, white-to-pink gradient panel/selected row, dark
    // (0xFF573353) row text.
    const whiteToPinkGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xFFFBEEFA)],
    );
    const darkText = Color(0xFF573353);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10.67),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                      color: Colors.white70,
                      fontSize: 14.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _isSchoolDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
          if (_isSchoolDropdownOpen) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                gradient: whiteToPinkGradient,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              // A plain Column, not a ListView — there are only ever a
              // handful of schools and no scrolling is wanted
              // (NeverScrollableScrollPhysics was already disabling it), so
              // there's no reason to involve Sliver/Viewport machinery that
              // can reserve more height than the content actually needs.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _schoolsForOrg.map((school) {
                  final code = school['schoolCode'] ?? '';
                  final schoolName = (school['schoolName'] ?? '').trim();
                  final name = schoolName.isNotEmpty ? schoolName : code;
                  final isSelected = code == _selectedSchoolCode;
                  return InkWell(
                    onTap: () => _onSchoolSelected(code, name),
                    child: Container(
                      // Horizontal padding kept tight (8, not 16) — this row
                      // already sits inside the switcher box's own 16px
                      // padding, and the name needs the room, especially
                      // with the checkmark box eating into it too.
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.67,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? whiteToPinkGradient : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              // Wraps rather than silently truncating a long
                              // school name — there's no good single-line
                              // width to promise once the checkmark box is
                              // accounted for.
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? darkText
                                    : darkText.withValues(alpha: 0.8),
                                fontSize: 14.4,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: darkText.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14.4,
                                color: darkText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
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
                                  leading: SvgPicture.asset(
                                    MediaRes.classroom_drawer_icon,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
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
                                  leading: SvgPicture.asset(
                                    MediaRes.parentMessaging,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
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
                                  leading: SvgPicture.asset(
                                    MediaRes.newsletter,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
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
                                  leading: SvgPicture.asset(
                                    MediaRes.studentAttendanceDrawer,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
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
                                  leading: SvgPicture.asset(
                                    MediaRes.staffAttendanceDrawer,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
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
                                    color: AppColors.themeColor,
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
                                    color: AppColors.themeColor,
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
                                  leading: SvgPicture.asset(
                                    MediaRes.staffMessaging,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
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
                                        leading: SvgPicture.asset(
                                          MediaRes.parentMessaging,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.themeColor,
                                            BlendMode.srcIn,
                                          ),
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
                                        leading: SvgPicture.asset(
                                          MediaRes.parentMessaging,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.themeColor,
                                            BlendMode.srcIn,
                                          ),
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
                                  leading: SvgPicture.asset(
                                    MediaRes.newsletter,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.themeColor,
                                      BlendMode.srcIn,
                                    ),
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
                                  leading: SvgPicture.asset(
                                    MediaRes.classroom_Schedule_drawer_icon,
                                  ),
                                  onTap: () =>
                                      _navigate(SchedulingScreen.routeName),
                                ),
                              if (showStaffScheduling)
                                DrawerListTile(
                                  title: 'Staff Scheduling',
                                  leading: SvgPicture.asset(
                                    MediaRes.staff_Schedule_drawer_icon,
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
                            preserveIconColors: true,
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
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                      SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                      const SizedBox(height: 15),
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
    this.preserveIconColors = false,
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

  Color _getIconColor() {
    if (_effectiveIsCurrentRoute) {
      return AppColors.themeColor;
    }
    return _isExpanded ? AppColors.themeColor : Colors.white;
  }

  Color _getTextColor() {
    if (_effectiveIsCurrentRoute) {
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
          color: _effectiveIsCurrentRoute || _isExpanded
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (_effectiveIsCurrentRoute || _isExpanded)
              const BoxShadow(
                blurRadius: 4,
                color: Colors.black26,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: widget.isExpansionEnabled
            ? ExpansionTile(
                controller: _expansionController,
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
                  widget.onExpansionChanged?.call(expanded);
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
                          _effectiveIsCurrentRoute
                              ? AppColors.themeColor
                              : Colors.white,
                          BlendMode.srcIn,
                        ),
                ),
                title: Text(
                  widget.title,
                  maxLines: 1,
                  style: TextStyle(
                    color: _effectiveIsCurrentRoute
                        ? AppColors.themeColor
                        : Colors.white,
                  ),
                ),
                tileColor: _effectiveIsCurrentRoute
                    ? Colors.white
                    : Colors.transparent,
                selected: _effectiveIsCurrentRoute,
                selectedTileColor: Colors.white,
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
        color: AppColors.paidLegendColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
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
    this.textColor = AppColors.themeColor,
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
/// "Communication"). Unlike [_CustomExpansionTile] — which toggles between
/// white/themeColor text+icon to stay legible against the drawer's own
/// colored background when collapsed — this always uses [AppColors.themeColor],
/// matching the sibling [DrawerListTile] items (e.g. "Staff Messaging") it
/// sits alongside on the panel's white background.
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
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      // Suppresses Flutter's default top/bottom divider border that
      // ExpansionTile draws while expanded.
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: AppColors.themeColor,
      collapsedIconColor: AppColors.themeColor,
      leading: SvgPicture.asset(
        icon,
        colorFilter: const ColorFilter.mode(
          AppColors.themeColor,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        style: const TextStyle(color: AppColors.themeColor),
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
