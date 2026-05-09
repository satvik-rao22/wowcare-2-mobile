import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
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

class AttendancePopupManager {
  static void showAttendancePopup(
    BuildContext context, {
    int initialTabIndex = 0,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (context) => AttendancePopupOverlay(
        initialTabIndex: initialTabIndex,
      ),
    );
  }
}

class AttendancePopupOverlay extends StatefulWidget {
  const AttendancePopupOverlay({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<AttendancePopupOverlay> createState() => _AttendancePopupOverlayState();
}

class _AttendancePopupOverlayState extends State<AttendancePopupOverlay>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isParentRole = false;
  bool? _isTeacherStaffPersona; // When true: skip staff selection and use self forms.
  String _loggedInStaffCode = '';
  String? _lastSeenRole;

  @override
  void initState() {
    super.initState();
    _isParentRole = context.read<RoleProvider>().isParent;
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
    final role = context.watch<RoleProvider>().role;
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
      _replaceTabController(
        length: _isParentRole ? 1 : 2,
        initialIndex: 0,
      );
      setState(() {});
    }

    if (!_isParentRole) {
      await _loadStaffPersonaFlags();
    }
  }

  void _replaceTabController({
    required int length,
    required int initialIndex,
  }) {
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
    return context.read<RoleProvider>().isParent;
  }

  Future<void> _loadStaffPersonaFlags() async {
    try {
      final storage = serviceLocator<StorageService>();
      var staffCode =
          (await storage.getString(StorageKeys.staffCode) ?? '').trim();
      if (staffCode.isEmpty) {
        staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      }
      final staffType =
          (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();

      bool isStaffAdmin =
          staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';

      if (!isStaffAdmin) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.trim().isNotEmpty) {
          final List<dynamic> roles = jsonDecode(rolesJson) as List<dynamic>;
          isStaffAdmin = roles.any((r) {
            if (r is! Map<String, dynamic>) return false;
            final roleCode = (r['role'] ?? '').toString().toUpperCase();
            return roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN';
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = staffCode;
        _isTeacherStaffPersona = staffCode.isNotEmpty && !isStaffAdmin;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = '';
        _isTeacherStaffPersona = false;
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
    final roleProvider = context.watch<RoleProvider>();
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
    final bottomPadding = effectiveNavBarHeight + safeAreaBottom + spacingFromNavBar;
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
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
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
                      ? const [
                          Tab(text: 'Student Attendance'),
                        ]
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
                  onTap: () {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const StudentSelectionSignInForm(),
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
                  onTap: () {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const StudentSelectionSignOutForm(),
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
                    onTap: () {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const StudentSelectionTransferForm(),
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
                    onTap: () {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const StudentSelectionMarkAbsentForm(),
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
                    onTap: () {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const StudentSelectionSignInForm(),
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
                    onTap: () {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const StudentSelectionSignOutForm(),
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
                      onTap: () {
                        final navigator = Navigator.of(context, rootNavigator: true);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const StudentSelectionTransferForm(),
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
                      onTap: () {
                        final navigator = Navigator.of(context, rootNavigator: true);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const StudentSelectionMarkAbsentForm(),
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
              label: isParent ? 'View My Child Attendance' : 'View Attendance',
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
                  onTap: () async {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop();
                    if (_isTeacherStaffPersona == true &&
                        _loggedInStaffCode.isNotEmpty) {
                      final display = await resolveLoggedInStaffDisplay();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => StaffSignInForm(
                            staff: StaffEntity(
                              id: 0,
                              name: display.fullName.isNotEmpty
                                  ? display.fullName
                                  : 'My Attendance',
                              primaryRoomId: 0,
                              photoUuid: display.profilePhotoUrl.isNotEmpty
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
                          builder: (_) => const StaffSelectionSignInForm(),
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
                  onTap: () async {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop();
                    if (_isTeacherStaffPersona == true &&
                        _loggedInStaffCode.isNotEmpty) {
                      final display = await resolveLoggedInStaffDisplay();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => StaffSignOutForm(
                            staff: StaffEntity(
                              id: 0,
                              name: display.fullName.isNotEmpty
                                  ? display.fullName
                                  : 'My Attendance',
                              primaryRoomId: 0,
                              photoUuid: display.profilePhotoUrl.isNotEmpty
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
                          builder: (_) => const StaffSelectionSignOutForm(),
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
                  onTap: () async {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop();
                    if (_isTeacherStaffPersona == true &&
                        _loggedInStaffCode.isNotEmpty) {
                      final display = await resolveLoggedInStaffDisplay();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => StaffTransferForm(
                            staff: StaffEntity(
                              id: 0,
                              name: display.fullName.isNotEmpty
                                  ? display.fullName
                                  : 'My Attendance',
                              primaryRoomId: 0,
                              photoUuid: display.profilePhotoUrl.isNotEmpty
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
                          builder: (_) => const StaffSelectionTransferForm(),
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
                  onTap: () async {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop();
                    if (_isTeacherStaffPersona == true &&
                        _loggedInStaffCode.isNotEmpty) {
                      final display = await resolveLoggedInStaffDisplay();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => StaffMarkAbsentForm(
                            staff: StaffEntity(
                              id: 0,
                              name: display.fullName.isNotEmpty
                                  ? display.fullName
                                  : 'My Attendance',
                              primaryRoomId: 0,
                              photoUuid: display.profilePhotoUrl.isNotEmpty
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
                          builder: (_) => const StaffSelectionMarkAbsentForm(),
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
                    onTap: () async {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      if (_isTeacherStaffPersona == true &&
                          _loggedInStaffCode.isNotEmpty) {
                        final display = await resolveLoggedInStaffDisplay();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => StaffSignInForm(
                              staff: StaffEntity(
                                id: 0,
                                name: display.fullName.isNotEmpty
                                    ? display.fullName
                                    : 'My Attendance',
                                primaryRoomId: 0,
                                photoUuid: display.profilePhotoUrl.isNotEmpty
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
                            builder: (_) => const StaffSelectionSignInForm(),
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
                    onTap: () async {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      if (_isTeacherStaffPersona == true &&
                          _loggedInStaffCode.isNotEmpty) {
                        final display = await resolveLoggedInStaffDisplay();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => StaffSignOutForm(
                              staff: StaffEntity(
                                id: 0,
                                name: display.fullName.isNotEmpty
                                    ? display.fullName
                                    : 'My Attendance',
                                primaryRoomId: 0,
                                photoUuid: display.profilePhotoUrl.isNotEmpty
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
                            builder: (_) => const StaffSelectionSignOutForm(),
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
                    onTap: () async {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      if (_isTeacherStaffPersona == true &&
                          _loggedInStaffCode.isNotEmpty) {
                        final display = await resolveLoggedInStaffDisplay();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => StaffTransferForm(
                              staff: StaffEntity(
                                id: 0,
                                name: display.fullName.isNotEmpty
                                    ? display.fullName
                                    : 'My Attendance',
                                primaryRoomId: 0,
                                photoUuid: display.profilePhotoUrl.isNotEmpty
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
                            builder: (_) => const StaffSelectionTransferForm(),
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
                    onTap: () async {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop();
                      if (_isTeacherStaffPersona == true &&
                          _loggedInStaffCode.isNotEmpty) {
                        final display = await resolveLoggedInStaffDisplay();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => StaffMarkAbsentForm(
                              staff: StaffEntity(
                                id: 0,
                                name: display.fullName.isNotEmpty
                                    ? display.fullName
                                    : 'My Attendance',
                                primaryRoomId: 0,
                                photoUuid: display.profilePhotoUrl.isNotEmpty
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
                            builder: (_) => const StaffSelectionMarkAbsentForm(),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              height: iconSize,
              width: iconSize,
            ),
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
        navigator.pop();
        if (isStaffTab) {
          if (_isTeacherStaffPersona == true) {
            // Staff persona: only allow viewing own attendance profile.
            final display = await resolveLoggedInStaffDisplay();
            if (display.staffCode.trim().isEmpty) {
              return;
            }
            navigator.push(
              MaterialPageRoute(
                builder: (_) => StaffAttendanceProfile(
                  staffCode: display.staffCode,
                  staffId: 0,
                  staffName:
                      display.fullName.isNotEmpty ? display.fullName : '-',
                  staffPhotoUuid:
                      display.profilePhotoUrl.isNotEmpty ? display.profilePhotoUrl : null,
                  roomName: '',
                ),
              ),
            );
          } else {
            // Admin: Navigate to staff attendance tabbed view
            navigator.push(
              MaterialPageRoute(
                builder: (_) => const StaffAttendanceTabbedView(),
              ),
            );
          }
        } else {
          if (_isParentRole) {
            await _openParentStudentAttendanceProfile(navigator.context);
            return;
          }
          // Navigate to student attendance tabbed view
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const StudentAttendanceTabbedView(),
            ),
          );
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
      final parentChild = context.read<ParentChildProvider>();
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
          size: 100,
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
          settings: const RouteSettings(name: StudentAttendanceProfile.routeName),
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


