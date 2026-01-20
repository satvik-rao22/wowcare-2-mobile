import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/shared/common/views/coming_soon_screen.dart';


class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  static final GlobalKey<_CustomNavigationBarState> navBarKey =
      GlobalKey<_CustomNavigationBarState>();

  static double get navBarHeight => navBarKey.currentState?._navBarHeight ?? 0.0;

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  final GlobalKey _containerKey = GlobalKey();
  double _navBarHeight = 0.0;
  bool _hasMeasured = false;
  int _index = 0;
  String _currentRoute = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newRoute = ModalRoute.of(context)?.settings.name ?? '';
    if (newRoute != _currentRoute) {
      setState(() {
        _currentRoute = newRoute;
        _updateIndexFromRoute();
      });
    }
  }

  void _updateIndexFromRoute() {
    if (!mounted) return;
    
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final isParent = roleProvider.isParent;
    
    if (isParent) {
      if (_currentRoute == DashboardScreen.routeName) {
        _index = 0;
      } else if (_currentRoute == ActivityFeedScreen.routeName) {
        _index = 1;
      } else if (_currentRoute == BillingScreen.routeName) {
        _index = 3;
      }
    } else {
      if (_currentRoute == DashboardScreen.routeName) {
        _index = 0;
      } else if (_currentRoute == ActivityFeedScreen.routeName) {
        _index = 3;
      }
    }
  }

  void _measureHeight() {
    if (_hasMeasured) return;
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _navBarHeight = renderBox.size.height;
      _hasMeasured = true;
      setState(() {});
    }
  }

  void _onItemTapped(int index, BuildContext context, bool isParent) {
    setState(() {
      _index = index;
    });
    
    if (isParent) {
      // Parent navigation items: Dashboard, Activities, Communication, Billing
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          break;
        case 1:
          Navigator.pushReplacementNamed(context, ActivityFeedScreen.routeName);
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
          );
          break;
        case 3:
          Navigator.pushReplacementNamed(context, BillingScreen.routeName);
          break;
      }
    } else {
      // Admin navigation items: Dashboard, Attendance, Classrooms, Activities, Messages
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
          );
          break;
        case 3:
          Navigator.pushReplacementNamed(context, ActivityFeedScreen.routeName);
          break;
        case 4:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
          );
          break;
      }
    }
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
    required BuildContext context,
    required bool isParent,
  }) {
    final bool isActive = _index == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context, isParent),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use SVG for vector icons
                SvgPicture.asset(
                  icon,
                  height: 24,
                  colorFilter: isActive
                      ? const ColorFilter.mode(
                          Colors.white,
                          BlendMode.dstIn,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: Fonts.inter,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final isParent = roleProvider.isParent;

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          key: _containerKey,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.buildPrimaryGradient(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: isParent
                ? [
                    // Parent navigation: Dashboard, Activities, Communication, Billing
                    _buildNavItem(
                      icon: MediaRes.dashboardIcon,
                      label: 'Dashboard',
                      index: 0,
                      context: context,
                      isParent: isParent,
                    ),
                    _buildNavItem(
                      icon: MediaRes.activitesIcon,
                      label: 'Activities',
                      index: 1,
                      context: context,
                      isParent: isParent,
                    ),
                    _buildNavItem(
                      icon: MediaRes.communicationIcon,
                      label: 'Communication',
                      index: 2,
                      context: context,
                      isParent: isParent,
                    ),
                    _buildNavItem(
                      icon: MediaRes.billing_drawer_icon,
                      label: 'Billing',
                      index: 3,
                      context: context,
                      isParent: isParent,
                    ),
                  ]
                : [
                    // Admin navigation: Dashboard, Attendance, Classrooms, Activities, Messages
                    _buildNavItem(
                      icon: MediaRes.dashboardIcon,
                      label: 'Dashboard',
                      index: 0,
                      context: context,
                      isParent: isParent,
                    ),
                    _buildNavItem(
                      icon: MediaRes.attendanceIcon,
                      label: 'Attendance',
                      index: 1,
                      context: context,
                      isParent: isParent,
                    ),
                    _buildNavItem(
                      icon: MediaRes.classroomIcon,
                      label: 'Classrooms',
                      index: 2,
                      context: context,
                      isParent: isParent,
                    ),
                    _buildNavItem(
                      icon: MediaRes.activitesIcon,
                      label: 'Activities',
                      index: 3,
                      context: context,
                      isParent: isParent,
                    ),
                    _buildNavItem(
                      icon: MediaRes.communicationIcon,
                      label: 'Messages',
                      index: 4,
                      context: context,
                      isParent: isParent,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
