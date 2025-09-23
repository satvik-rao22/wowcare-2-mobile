import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';

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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double navBarHeight = kBottomNavigationBarHeight; // approx
    final double screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: screenHeight - (navBarHeight * 4.5),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                child: TabBar(
                  controller: _tabController,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.themeColor, width: 1.2),
                  ),
                  indicatorPadding: const EdgeInsets.only(bottom: 8),
                  labelPadding: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'Manrope',
                    fontSize: 16,
                  ),
                  unselectedLabelColor: AppColors.primaryColor.withOpacity(0.5),
                  tabs: const [
                    Tab(text: 'Student Attendance'),
                    Tab(text: 'Staff Attendance'),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActionsRow(context),
                    _buildActionsRow(context, isStaff: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context, {bool isStaff = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSvgActionButton(svgPath: MediaRes.Sign_in, label: 'Sign-in', onTap: () => Navigator.pop(context)),
          _buildSvgActionButton(svgPath: MediaRes.Sign_out, label: 'Sign-Out', onTap: () => Navigator.pop(context)),
          _buildSvgActionButton(svgPath: MediaRes.transfer, label: 'Transfer', onTap: () => Navigator.pop(context)),
          _buildSvgActionButton(svgPath: MediaRes.Mark_absent, label: 'Absent', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildSvgActionButton({
    required String svgPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgPath,
            height: 36,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 12, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }
}


