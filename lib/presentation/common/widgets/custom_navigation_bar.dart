import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/fonts.dart';


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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
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

  void _onItemTapped(int index) {
    setState(() {
      _index = index;
    });
    // TODO: Hook up navigation when routes are ready
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
  }) {
    final bool isActive = _index == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
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
            children: [
              _buildNavItem(
                icon: MediaRes.dashboardIcon,
                label: 'Dashboard',
                index: 0,
              ),
              _buildNavItem(
                icon: MediaRes.attendanceIcon,
                label: 'Attendance',
                index: 1,
              ),
              _buildNavItem(
                icon: MediaRes.classroomIcon,
                label: 'Classrooms',
                index: 2,
              ),
              _buildNavItem(
                icon: MediaRes.activitesIcon,
                label: 'Activities',
                index: 3,
              ),
              _buildNavItem(
                icon: MediaRes.communicationIcon,
                label: 'Messages',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
