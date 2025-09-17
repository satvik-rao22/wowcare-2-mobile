// custom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../res/colors.dart';
import '../../res/fonts.dart';
import '../../res/media_res.dart';
import '../app/providers/nav_bar_providers.dart';
import 'package:wowcare/src/presentation/screens/dashboard/admin_dashboard.dart';

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  static final GlobalKey<_CustomNavigationBarState> navBarKey =
      GlobalKey<_CustomNavigationBarState>();

  static double get navBarHeight =>
      navBarKey.currentState?._navBarHeight ?? 0.0;

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  String _currentRoute = '';
  final GlobalKey _containerKey = GlobalKey();
  double _navBarHeight = 0.0;
  bool _hasMeasured = false;

  static const List<String> dashboardRoutes = [AdminDashboard.routeName];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute = ModalRoute.of(context)?.settings.name ?? '';
  }

  void _measureHeight() {
    if (_hasMeasured) return;

    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null && mounted) {
      final bottomInset = MediaQuery.of(context).padding.bottom;
      final height = renderBox.size.height + bottomInset;
      setState(() {
        _navBarHeight = height;
        _hasMeasured = true;
      });

      context.read<NavBarHeightProvider>().height = height;
    }
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required String routeName,
  }) {
    final bool isActive = _currentRoute == routeName;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isActive) {
            Navigator.pushNamed(context, routeName);
          }
        },
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
              children: [
                SvgPicture.asset(
                  icon,
                  height: 24, // ✅ same height as others
                  width: 24, // ✅ enforce equal width for consistency
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
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          key: _containerKey,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(gradient: AppColors.buildPrimaryGradient()),
          child: Row(
            children: [
              _buildNavItem(
                icon: MediaRes.dashboardIcon,
                label: 'Dashboard',
                routeName: AdminDashboard.routeName,
              ),
              _buildNavItem(
                icon: MediaRes.attendanceIcon,
                label: 'Attendance',
                routeName: '/attendance',
              ),
              _buildNavItem(
                icon: MediaRes.classroomIcon,
                label: 'Classrooms',
                routeName: '/classrooms',
              ),
              _buildNavItem(
                icon: MediaRes.activitesIcon,
                label: 'Activities',
                routeName: '/activities',
              ),
              _buildNavItem(
                icon: MediaRes.communicationIcon, // ✅ now matches others
                label: 'Communication',
                routeName: '/communication',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
