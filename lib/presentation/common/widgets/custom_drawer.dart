import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: AppColors.buildPrimaryGradient(),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 28, backgroundColor: Colors.white,
            backgroundImage: AssetImage(MediaRes.logo_wow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('WowCare',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Preschool Management',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String icon,
    required String label,
    String? routeName,
  }) {
    final bool isCurrent = routeName != null && routeName == _currentRoute;

    final bool isSvg = icon.toLowerCase().endsWith('.svg');

    return ListTile(
      leading: isSvg
          ? SvgPicture.asset(
              icon,
              height: 20,
              colorFilter: ColorFilter.mode(
                isCurrent ? AppColors.themeColor : (Colors.grey[700] ?? Colors.grey),
                BlendMode.srcIn,
              ),
            )
          : Image.asset(icon, height: 20, color: isCurrent ? AppColors.themeColor : null),
      title: Text(label,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          )),
      onTap: () {
        Navigator.pop(context);
        // TODO: Hook up routes when implemented
        // if (routeName != null && routeName != _currentRoute) {
        //   Navigator.pushNamed(context, routeName);
        // }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Dashboards
                  _tile(icon: MediaRes.dashboardIcon, label: 'Dashboard'),

                  // Classrooms / Students / Staff
                  _tile(icon: MediaRes.classroom_drawer_icon, label: 'Classrooms'),
                  _tile(icon: MediaRes.students_drawer_icon, label: 'Students'),
                  _tile(icon: MediaRes.staffs_drawer_icon, label: 'Staff'),

                  // Attendance
                  _tile(icon: MediaRes.studentAttendanceDrawer, label: 'Student Attendance'),
                  _tile(icon: MediaRes.staffAttendanceDrawer, label: 'Staff Attendance'),

                  // Activities & Communication
                  _tile(icon: MediaRes.activitesIcon, label: 'Activities'),
                  _tile(icon: MediaRes.communicationIcon, label: 'Communication'),

                  // Billing
                  _tile(icon: MediaRes.billing_drawer_icon, label: 'Billing'),

                  // Newsletter
                  _tile(icon: MediaRes.newsletter, label: 'Newsletter'),

                  // Settings
                  _tile(icon: MediaRes.settings_drawer_Blue, label: 'Settings'),

                  const Divider(),

                  // Logout
                  ListTile(
                    leading: Image.asset(MediaRes.logout, height: 20),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: show logout modal when available
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
