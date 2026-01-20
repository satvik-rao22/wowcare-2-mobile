import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/shared/common/views/coming_soon_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _currentRoute = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute = ModalRoute.of(context)?.settings.name ?? '';
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
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      'Demo School',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                            Navigator.pushNamed(context, DashboardScreen.routeName);
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
                              MaterialPageRoute(builder: (_) => const StudentScreen()),
                            );
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Attendance',
                          icon: MediaRes.attendanceIcon,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                            );
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Activities',
                          icon: MediaRes.activitesIcon,
                          isCurrentRoute: _currentRoute == ActivityFeedScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != ActivityFeedScreen.routeName) {
                              Navigator.pushNamed(context, ActivityFeedScreen.routeName);
                            }
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Communication',
                          icon: MediaRes.communicationIcon,
                          isExpansionEnabled: true,
                          children: [
                            DrawerListTile(
                              title: 'Messaging',
                              leading: SvgPicture.asset(
                                MediaRes.parentMessaging,
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                                );
                              },
                            ),
                            DrawerListTile(
                              title: 'Newsletter',
                              leading: SvgPicture.asset(
                                MediaRes.newsletter,
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                        _CustomExpansionTile(
                          title: 'Billing',
                          icon: MediaRes.billing_drawer_icon,
                          isCurrentRoute: _currentRoute == BillingScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != BillingScreen.routeName) {
                              Navigator.pushNamed(context, BillingScreen.routeName);
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
                              MaterialPageRoute(builder: (_) => const ClassroomScreen()),
                            );                      
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Students',
                          icon: MediaRes.students_drawer_icon,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => StudentScreen()),
                            );
                          },
                        ),
                        _CustomExpansionTile(
                          title: 'Staff',
                          icon: MediaRes.staffs_drawer_icon,
                          isCurrentRoute: _currentRoute == StaffScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if (_currentRoute != StaffScreen.routeName) {
                              Navigator.pushNamed(context, StaffScreen.routeName);
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
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
                              },
                            ),
                            DrawerListTile(
                              title: 'Staff Attendance',
                              leading: SvgPicture.asset(
                                MediaRes.staffAttendanceDrawer,
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
                              },
                            ),
                          ],
                        ),
                        _CustomExpansionTile(
                          title: 'Activities',
                          icon: MediaRes.activitesIcon,
                          isCurrentRoute: _currentRoute == ActivityFeedScreen.routeName,
                          onTap: () {
                            Navigator.pop(context);
                            if(_currentRoute != ActivityFeedScreen.routeName){
                              Navigator.pushNamed(context, ActivityFeedScreen.routeName);
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
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
                              },
                            ),
                            DrawerListTile(
                              title: 'Parent Messaging',
                              leading: SvgPicture.asset(
                                MediaRes.parentMessaging,
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
                              },
                            ),
                            DrawerListTile(
                              title: 'Newsletter',
                              leading: SvgPicture.asset(
                                MediaRes.newsletter,
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
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
                              Navigator.pushNamed(context, BillingScreen.routeName);
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
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
                              ),
                              onTap: () {},
                            ),
                            DrawerListTile(
                              title: 'Terms & Conditions',
                              leading: SvgPicture.asset(
                                MediaRes.settings_drawer_Blue,
                                colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
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
