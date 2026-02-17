import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart';

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
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_onTabChanged);
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
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final isAdmin = roleProvider.isAdmin;
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
                  tabs: const [
                    Tab(text: 'Student Attendance'),
                    Tab(text: 'Staff Attendance'),
                  ],
                ),
              ),
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: _getTabHeight(isAdmin, isTablet, constraints.maxHeight),
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStudentAttendanceTab(context, isAdmin, isTablet, screenWidth),
                          _buildStaffAttendanceTab(context, isAdmin, isTablet, screenWidth),
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
                    Navigator.pop(context);
                    Navigator.push(
                      context,
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
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentSelectionSignOutForm(),
                      ),
                    );
                  },
                  context: context,
                ),
                _buildActionButton(
                  icon: MediaRes.transfer,
                  label: 'Transfer',
                  iconSize: buttonSize,
                  fontSize: fontSize,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentSelectionTransferForm(),
                      ),
                    );
                  },
                  context: context,
                ),
                _buildActionButton(
                  icon: MediaRes.Mark_absent,
                  label: 'Absent',
                  iconSize: buttonSize,
                  fontSize: fontSize,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentSelectionSignOutForm(),
                        ),
                      );
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
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentSelectionMarkAbsentForm(),
                        ),
                      );
                    },
                    context: context,
                  ),
                ),
              ],
            ),
          // Show "View Attendance" button for admin users in student tab
          if (isAdmin) ...[
            SizedBox(height: isTablet ? 20 : 16),
            _buildViewAttendanceButton(context, isStaffTab: false, isTablet: isTablet),
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StaffSelectionSignInForm(),
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
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StaffSelectionSignOutForm(),
                      ),
                    );
                  },
                  context: context,
                ),
                _buildActionButton(
                  icon: MediaRes.transfer,
                  label: 'Transfer',
                  iconSize: buttonSize,
                  fontSize: fontSize,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StaffSelectionTransferForm(),
                      ),
                    );
                  },
                  context: context,
                ),
                _buildActionButton(
                  icon: MediaRes.Mark_absent,
                  label: 'Absent',
                  iconSize: buttonSize,
                  fontSize: fontSize,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StaffSelectionMarkAbsentForm(),
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffSelectionSignInForm(),
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffSelectionSignOutForm(),
                        ),
                      );
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
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffSelectionTransferForm(),
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffSelectionMarkAbsentForm(),
                        ),
                      );
                    },
                    context: context,
                  ),
                ),
              ],
            ),
          // Show "View Attendance" button only for admin users in staff tab
          if (isAdmin) ...[
            SizedBox(height: isTablet ? 20 : 16),
            _buildViewAttendanceButton(context, isStaffTab: true, isTablet: isTablet),
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
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (isStaffTab) {
          // Navigate to staff attendance tabbed view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StaffAttendanceTabbedView(),
            ),
          );
        } else {
          // Navigate to student attendance tabbed view
          Navigator.push(
            context,
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
                  'View Attendance',
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

  double _getTabHeight(bool isAdmin, bool isTablet, double maxAvailableHeight) {
    // Calculate required height for content
    final buttonRowHeight = isTablet ? 100.0 : 80.0;
    final viewButtonHeight = isAdmin ? (isTablet ? 76.0 : 64.0) : 0.0;
    final padding = isTablet ? 32.0 : 24.0;
    final calculatedHeight = buttonRowHeight + viewButtonHeight + padding;
    
    // Use calculated height but don't exceed available space
    return calculatedHeight.clamp(80.0, maxAvailableHeight.clamp(80.0, 300.0));
  }
}


