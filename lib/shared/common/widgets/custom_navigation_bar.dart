import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/shared/common/views/coming_soon_screen.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  static final GlobalKey<_CustomNavigationBarState> navBarKey =
      GlobalKey<_CustomNavigationBarState>();

  static double get navBarHeight =>
      navBarKey.currentState?._navBarHeight ?? 0.0;

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar>
    with WidgetsBindingObserver {
  final GlobalKey _containerKey = GlobalKey();
  double _navBarHeight = 0.0;
  bool _hasMeasured = false;
  int _index = 0;
  String _currentRoute = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Re-measure height when keyboard opens/closes or orientation changes
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
      if (_currentRoute == DashboardScreen.routeName)
        _index = 0;
      else if (_currentRoute == ActivityFeedScreen.routeName)
        _index = 1;
      else if (_currentRoute == ParentBillingScreen.routeName)
        _index = 3;
    } else {
      if (_currentRoute == DashboardScreen.routeName)
        _index = 0;
      else if (_currentRoute == ActivityFeedScreen.routeName)
        _index = 3;
    }
  }

  void _measureHeight() {
    if (_hasMeasured && !mounted) return;

    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final newHeight = renderBox.size.height;
      if (newHeight != _navBarHeight) {
        setState(() {
          _navBarHeight = newHeight;
          _hasMeasured = true;
        });
      }
    }
  }

  void _onItemTapped(int index, BuildContext context, bool isParent) {
    setState(() => _index = index);

    if (isParent) {
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
          Navigator.pushReplacementNamed(
            context,
            ParentBillingScreen.routeName,
          );
          break;
      }
    } else {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          break;
        case 1:
          AttendancePopupManager.showAttendancePopup(context);
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
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
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
                SvgPicture.asset(
                  icon,
                  height: 24,
                  colorFilter: isActive
                      ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
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

    return Container(
      // This ensures the gradient extends under the home indicator on iPhone
      color: AppColors.buildPrimaryGradient().colors.first,
      child: SafeArea(
        top: false, // Disable top padding (status bar)
        bottom: false, // ← Critical fix for iPhone home indicator
        maintainBottomViewPadding: true,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            key: _containerKey,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: isParent
                  ? [
                      // Parent Navigation
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
                      // Admin Navigation
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
      ),
    );
  }
}
