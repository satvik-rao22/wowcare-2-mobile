import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/shared/common/views/coming_soon_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _currentRoute = '';
  bool _isSchoolDropdownOpen = false;
  bool _isLoadingSchools = true;
  String? _currentOrgCode;
  String? _selectedSchoolCode;
  String? _selectedSchoolName;
  List<Map<String, String>> _schoolsForOrg = const <Map<String, String>>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    // Load school context once we have a BuildContext and DI is ready.
    _loadSchoolContext();
  }

  Future<void> _loadSchoolContext() async {
    try {
      final storage = serviceLocator<StorageService>();
      final authLocal = serviceLocator<AuthLocalDataSource>();
      final orgCode = await storage.getString(StorageKeys.organizationCode);
      final schoolCode = await storage.getString(StorageKeys.schoolCode);
      final selectedName =
          await storage.getString(StorageKeys.selectedSchoolName);
      final orgSchools = await authLocal.getOrganizationsAndSchools();

      final schoolsForOrg = orgSchools
          .where((e) => e['organizationCode'] == (orgCode ?? ''))
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
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_currentOrgCode == null || _currentOrgCode!.isEmpty) {
      return const Text(
        'No organization selected',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (_schoolsForOrg.isEmpty) {
      return const Text(
        'No schools found',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
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
                final name = school['schoolName'] ?? code;
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

    final authLocal = serviceLocator<AuthLocalDataSource>();
    final authCubit = context.read<AuthCubit>();

    // Persist new selection locally (used by all APIs).
    await authLocal.setSelectedOrgAndSchool(
      organizationCode: _currentOrgCode!,
      schoolCode: schoolCode,
      schoolName: schoolName,
    );

    // Best-effort: update backend login-context with new school.
    await authCubit.updateLoginContext(
      lastLoginOrganizationCode: _currentOrgCode!,
      lastLoginSchoolCode: schoolCode,
    );

    if (!mounted) return;
    setState(() {
      _selectedSchoolCode = schoolCode;
      _selectedSchoolName = schoolName;
      _isSchoolDropdownOpen = false;
    });

    // Close drawer and send user to Dashboard for the newly selected school.
    Navigator.pop(context);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final isParent = roleProvider.isParent;

    return Drawer(
      width: MediaQuery.of(context).size.width * 2 / 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
        ),
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
                      _CustomExpansionTile(
                        title: 'Dashboard',
                        icon: MediaRes.dashboardIcon,
                        isDashboard: true,
                        isCurrentRoute: _currentRoute == DashboardScreen.routeName,
                        onTap: () {
                          Navigator.pop(context);
                          if (_currentRoute != DashboardScreen.routeName) {
                            Navigator.pushNamed(
                                context, DashboardScreen.routeName);
                          }
                        },
                      ),
                      if (isParent) ...[
                        // Parent-specific menu items
                        _CustomExpansionTile(
                          title: 'My Child',
                          icon: MediaRes.students_drawer_icon,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider<StudentCubit>(
                                      create: (_) => serviceLocator<StudentCubit>()
                                        ..loadInitial(),
                                    ),
                                    BlocProvider<ClassroomCubit>(
                                      create: (_) =>
                                          serviceLocator<ClassroomCubit>()
                                            ..loadActiveClassrooms(),
                                    ),
                                  ],
                                  child: const StudentScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Attendance',
                          icon: MediaRes.attendanceIcon,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ComingSoonScreen()),
                            );
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Activities',
                          icon: MediaRes.activitesIcon,
                          isCurrentRoute:
                              _currentRoute == ActivityFeedScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute !=
                                ActivityFeedScreen.routeName) {
                              Navigator.pushNamed(
                                  context, ActivityFeedScreen.routeName);
                            }
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Communication',
                          icon: MediaRes.communicationIcon,
                          isCurrentRoute:
                              _currentRoute == MessagingScreen.routeName,
                          isExpansionEnabled: true,
                          children: [
                            DrawerListTile(
                              title: 'Messaging',
                              leading: SvgPicture.asset(
                                MediaRes.parentMessaging,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MessagingScreen(
                                      userPersona: UserPersona.parent,
                                    ),
                                    settings: const RouteSettings(
                                        name: MessagingScreen.routeName),
                                  ),
                                );
                              },
                            ),
                            DrawerListTile(
                              title: 'Newsletter',
                              leading: SvgPicture.asset(
                                MediaRes.newsletter,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MessagingScreen(
                                      userPersona: UserPersona.parent,
                                    ),
                                    settings: const RouteSettings(
                                        name: MessagingScreen.routeName),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        _CustomExpansionTile(
                          title: 'Billing',
                          icon: MediaRes.billing_drawer_icon,
                          isCurrentRoute:
                              _currentRoute == ParentBillingScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute !=
                                ParentBillingScreen.routeName) {
                              Navigator.pushNamed(
                                  context, ParentBillingScreen.routeName);
                            }
                          },
                        ),
                      ] else ...[
                        // Admin menu items
                        _CustomExpansionTile(
                          title: 'Classrooms',
                          icon: MediaRes.classroom_drawer_icon,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ClassroomScreen()),
                            );
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Students',
                          icon: MediaRes.students_drawer_icon,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider<StudentCubit>(
                                      create: (_) => serviceLocator<StudentCubit>()
                                        ..loadInitial(),
                                    ),
                                    BlocProvider<ClassroomCubit>(
                                      create: (_) =>
                                          serviceLocator<ClassroomCubit>()
                                            ..loadActiveClassrooms(),
                                    ),
                                  ],
                                  child: const StudentScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Staff',
                          icon: MediaRes.staffs_drawer_icon,
                          isCurrentRoute:
                              _currentRoute == StaffScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != StaffScreen.routeName) {
                              Navigator.pushNamed(
                                  context, StaffScreen.routeName);
                            }
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Attendance',
                          icon: MediaRes.attendanceIcon,
                          isExpansionEnabled: true,
                          children: [
                            DrawerListTile(
                              title: 'Student Attendance',
                              leading: SvgPicture.asset(
                                MediaRes.studentAttendanceDrawer,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentAttendanceTabbedView()),
                                );
                              },
                            ),
                            DrawerListTile(
                              title: 'Staff Attendance',
                              leading: SvgPicture.asset(
                                MediaRes.staffAttendanceDrawer,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const StaffAttendanceTabbedView()),
                                );
                              },
                            ),
                          ],
                        ),
                        _CustomExpansionTile(
                          title: 'Activities',
                          icon: MediaRes.activitesIcon,
                          isCurrentRoute:
                              _currentRoute == ActivityFeedScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute !=
                                ActivityFeedScreen.routeName) {
                              Navigator.pushNamed(
                                  context, ActivityFeedScreen.routeName);
                            }
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Communication',
                          icon: MediaRes.communicationIcon,
                          isExpansionEnabled: true,
                          children: [
                            DrawerListTile(
                              title: 'Staff Messaging',
                              leading: SvgPicture.asset(
                                MediaRes.staffMessaging,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MessagingScreen(
                                      userPersona: UserPersona.admin,
                                    ),
                                    settings: const RouteSettings(
                                        name: MessagingScreen.routeName),
                                  ),
                                );
                              },
                            ),
                            DrawerListTile(
                              title: 'Parent Messaging',
                              leading: SvgPicture.asset(
                                MediaRes.parentMessaging,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MessagingScreen(
                                      userPersona: UserPersona.admin,
                                      initialTabIndex: 1,
                                    ),
                                    settings: const RouteSettings(
                                        name: MessagingScreen.routeName),
                                  ),
                                );
                              },
                            ),
                            DrawerListTile(
                              title: 'Newsletter',
                              leading: SvgPicture.asset(
                                MediaRes.newsletter,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MessagingScreen(
                                      userPersona: UserPersona.admin,
                                    ),
                                    settings: const RouteSettings(
                                        name: MessagingScreen.routeName),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        _CustomExpansionTile(
                          title: 'Billing',
                          icon: MediaRes.billing_drawer_icon,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != BillingScreen.routeName) {
                              Navigator.pushNamed(
                                  context, BillingScreen.routeName);
                            }
                          },
                        ),
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
                                    AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {},
                            ),
                            DrawerListTile(
                              title: 'Terms & Conditions',
                              leading: SvgPicture.asset(
                                MediaRes.settings_drawer_Blue,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.themeColor, BlendMode.srcIn),
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

  const _CustomExpansionTile({
    required this.title,
    required this.icon,
    this.children = const [],
    this.isExpansionEnabled = false,
    this.isCurrentRoute = false,
    this.onTap,
    this.isDashboard = false,
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
                  colorFilter: ColorFilter.mode(
                    _getIconColor(),
                    BlendMode.srcIn,
                  ),
                ),
                iconColor: AppColors.themeColor,
                collapsedIconColor: Colors.white,
                title: Text(
                  widget.title,
                  maxLines: 1,
                  style: TextStyle(
                    color: _getTextColor(),
                  ),
                ),
                children: widget.children,
                trailing: const Icon(Icons.keyboard_arrow_down),
              )
            : ListTile(
                leading: SvgPicture.asset(
                  widget.icon,
                  colorFilter: ColorFilter.mode(
                    widget.isCurrentRoute ? AppColors.themeColor : Colors.white,
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
      title: Text(
        title,
        maxLines: 1,
        style: TextStyle(color: textColor),
      ),
    );
  }
}
