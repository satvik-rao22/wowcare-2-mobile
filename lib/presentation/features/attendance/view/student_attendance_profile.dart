import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

// Simple field widget for displaying label and text
class _AttendanceField extends StatelessWidget {
  final String label;
  final String text;

  const _AttendanceField({
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: AppText.small(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withOpacity(0.5),
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppText.value(
            text,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Dummy data models for UI-only implementation
class _AttendanceModel {
  final DateTime date;
  final String signInTime;
  final String signOutTime;
  final String roomName;
  final String signInBy;
  final String signOutBy;

  _AttendanceModel({
    required this.date,
    required this.signInTime,
    required this.signOutTime,
    required this.roomName,
    required this.signInBy,
    required this.signOutBy,
  });
}

class _AbsentDayModel {
  final DateTime startDate;
  final DateTime endDate;
  final String absentTime;
  final String absentBy;
  final String note;

  _AbsentDayModel({
    required this.startDate,
    required this.endDate,
    required this.absentTime,
    required this.absentBy,
    required this.note,
  });
}

class _StudentModel {
  final int id;
  final String name;
  final String? photoUuid;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String profileStatus;
  final bool isPhotoPermission;
  final String medications;
  final String note;
  final String allergies;
  final String dietRestriction;

  _StudentModel({
    required this.id,
    required this.name,
    this.photoUuid,
    required this.roomName,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.isPresentToday = false,
    this.profileStatus = 'A',
    this.isPhotoPermission = true,
    this.medications = '',
    this.note = '',
    this.allergies = '',
    this.dietRestriction = '',
  });
}

class _AttendanceReportModel {
  final int attendedDays;
  final String totalAttendedHours;
  final int absentDays;

  _AttendanceReportModel({
    required this.attendedDays,
    required this.totalAttendedHours,
    required this.absentDays,
  });
}

class StudentAttendanceProfile extends StatefulWidget {
  static const String routeName = '/student-attendance-profile';

  const StudentAttendanceProfile({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUuid,
    required this.roomName,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.isPresentToday = false,
    this.profileStatus = 'A',
  });

  final int studentId;
  final String studentName;
  final String? studentPhotoUuid;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String profileStatus;

  @override
  State<StudentAttendanceProfile> createState() => _StudentAttendanceProfileState();
}

class _StudentAttendanceProfileState extends State<StudentAttendanceProfile> {
  DateTime? _startDate;
  bool isAttendancesLoading = false;
  bool isAbsentDaysLoading = false;
  bool isStudentLoading = false;
  bool showAbsentDays = false;
  int? expandedIndex;

  List<_AttendanceModel> attendances = [];
  List<_AbsentDayModel> absentDays = [];
  _StudentModel? student;
  _AttendanceReportModel? attendanceReport;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);

    // Initialize student model
    student = _StudentModel(
      id: widget.studentId,
      name: widget.studentName,
      photoUuid: widget.studentPhotoUuid,
      roomName: widget.roomName,
      isSignedIn: widget.isSignedIn,
      isAbsent: widget.isAbsent,
      isExpectedToday: widget.isExpectedToday,
      isPresentToday: widget.isPresentToday,
      profileStatus: widget.profileStatus,
    );

    // Load dummy data
    _loadData();
  }

  void _loadData() {
    setState(() {
      isAttendancesLoading = true;
      isAbsentDaysLoading = true;
      isStudentLoading = true;
    });

    // Simulate API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Generate dummy attendance data
      attendances = List.generate(5, (index) {
        final date = DateTime.now().subtract(Duration(days: index));
        return _AttendanceModel(
          date: date,
          signInTime: '08:${30 + index}:00 AM',
          signOutTime: index < 3 ? '05:${10 + index}:00 PM' : '',
          roomName: widget.roomName,
          signInBy: 'Staff Member ${index + 1}',
          signOutBy: index < 3 ? 'Staff Member ${index + 1}' : 'System Auto Signout',
        );
      });

      // Generate dummy absent days
      absentDays = List.generate(2, (index) {
        final startDate = DateTime.now().subtract(Duration(days: index + 10));
        return _AbsentDayModel(
          startDate: startDate,
          endDate: startDate,
          absentTime: '09:00:00 AM',
          absentBy: 'Staff Member ${index + 1}',
          note: index == 0 ? 'Student is absent' : '',
        );
      });

      // Generate dummy attendance report
      attendanceReport = _AttendanceReportModel(
        attendedDays: 12,
        totalAttendedHours: '48h 30m',
        absentDays: 2,
      );

      setState(() {
        isAttendancesLoading = false;
        isAbsentDaysLoading = false;
        isStudentLoading = false;
      });
    });
  }

  Future<void> refreshData() async {
    _loadData();
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    setState(() {
      _startDate = startDate;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: CustomRefreshIndicator(
        onRefresh: () async => refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: contentPadding.left,
            vertical: responsive.verticalSpacing / 2,
          ),
          child: Column(
            children: [
              SizedBox(height: responsive.verticalSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomDateTimeField(
                      hasLabel: false,
                      isRangePicker: true,
                      initialDate: _startDate,
                      label: 'Date Range',
                      onRangeSelected: (start, end) {
                        _onDateRangeSelected(start, end);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildPopupMenu(),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  return isStudentLoading && (isAttendancesLoading || isAbsentDaysLoading)
                      ? _buildAttendanceShimmer()
                      : Column(
                          children: [
                            _buildStudentCard(),
                            const SizedBox(height: 16),
                            // Toggle for showing absent days
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText.title(
                                  showAbsentDays ? 'Absent Days' : 'Present Days',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                CustomToggle(
                                  label: 'Show Absent',
                                  isToggled: showAbsentDays,
                                  onToggle: (value) {
                                    setState(() {
                                      showAbsentDays = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildAttendanceList(),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    final responsive = ResponsiveHelper(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;
    
    return GradientAddButton(
      onTap: () {
        _showActionMenu(context);
      },
      isTablet: isTablet,
      isLargeTablet: isLargeTablet,
      isRectangle: true,
    );
  }

  void _showActionMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final Size screenSize = MediaQuery.of(context).size;
        final double menuWidth = screenSize.width <= 360
            ? screenSize.width * 0.58
            : screenSize.width <= 420
                ? 200
                : 220;
        final double maxMenuHeight = screenSize.height * 0.55;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 80),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: menuWidth,
                  maxHeight: maxMenuHeight,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBorderColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.login,
                          color: Colors.blue,
                          label: "Sign-in",
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to sign-in form
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildActionButton(
                          icon: Icons.logout,
                          color: Colors.blue,
                          label: "Sign-Out",
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to sign-out form
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildActionButton(
                          icon: Icons.swap_horiz,
                          color: Colors.blue,
                          label: "Transfer",
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to transfer form
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildActionButton(
                          icon: Icons.cancel,
                          color: Colors.blue,
                          label: "Absent",
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to absent form
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
          ),
          const SizedBox(height: 5),
          AppText.small(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard() {
    if (student == null) return const SizedBox.shrink();

    final responsive = ResponsiveHelper(context);
    final currentStudent = student!;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      shadowColor: AppColors.primaryColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 5),
                Stack(
                  children: [
                    DocumentImageWidget(
                      fileUuid: currentStudent.photoUuid ?? '',
                      size: 80,
                      name: currentStudent.name,
                      fontSize: 24,
                    ),
                    // Status dot logic
                    if (currentStudent.isSignedIn ||
                        currentStudent.isAbsent ||
                        currentStudent.profileStatus == 'Upcoming')
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: currentStudent.profileStatus == 'Upcoming'
                                ? const Color.fromARGB(255, 253, 205, 22) // Yellow for upcoming
                                : currentStudent.isSignedIn
                                    ? const Color.fromRGBO(0, 177, 21, 1) // Green when signed in
                                    : currentStudent.isAbsent
                                        ? const Color.fromRGBO(200, 32, 32, 1) // Red when absent
                                        : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.title(
                        currentStudent.name,
                        style: TextStyle(
                          fontSize: responsive.isTablet ? 23 : 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppText.body(
                            currentStudent.roomName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 100),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: AppText.title(
                                    'Details',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!currentStudent.isPhotoPermission)
                                        _buildIconDetail(
                                          MediaRes.cameraIcon,
                                          "No Photo Permission",
                                        ),
                                      if (currentStudent.medications.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.healthIcon,
                                          currentStudent.medications,
                                        ),
                                      if (currentStudent.note.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.docsIcon,
                                          currentStudent.note,
                                        ),
                                      if (currentStudent.allergies.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.alertIcon,
                                          currentStudent.allergies,
                                        ),
                                      if (currentStudent.dietRestriction.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.foodIcon2,
                                          currentStudent.dietRestriction,
                                        ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: AppText.body(
                                        'Close',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (!currentStudent.isPhotoPermission)
                                  _buildIconItem(MediaRes.cameraIcon),
                                if (currentStudent.medications.isNotEmpty)
                                  _buildIconItem(MediaRes.healthIcon),
                                if (currentStudent.note.isNotEmpty)
                                  _buildIconItem(MediaRes.docsIcon),
                                if (currentStudent.allergies.isNotEmpty)
                                  _buildIconItem(MediaRes.alertIcon),
                                if (currentStudent.dietRestriction.isNotEmpty)
                                  _buildIconItem(MediaRes.foodIcon2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconItem(String icon) {
    final bool isSvg = icon.toLowerCase().endsWith('.svg');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: isSvg
          ? SvgPicture.asset(icon, height: 20)
          : Image.asset(icon, height: 20),
    );
  }

  Widget _buildIconDetail(String iconPath, String detail) {
    final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          isSvg
              ? SvgPicture.asset(iconPath, height: 24)
              : Image.asset(iconPath, height: 24),
          const SizedBox(width: 16),
          Expanded(
            child: AppText.body(
              detail,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (attendanceReport == null) {
      return Column(
        children: [
          _buildStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: const Color(0xFF4285F4),
            label: 'Attended Days',
            value: '',
            valueColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: MediaRes.timerIcon,
            iconColor: const Color(0xFF4285F4),
            label: 'Attended Hours',
            value: 'h',
            valueColor: const Color(0xFF4285F4),
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: const Color(0xFF4285F4),
            label: 'Absent Days',
            value: '',
            valueColor: Colors.red,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          iconColor: const Color(0xFF4285F4),
          label: 'Attended Days',
          value: '${attendanceReport!.attendedDays}',
          valueColor: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          icon: MediaRes.timerIcon,
          iconColor: const Color(0xFF4285F4),
          label: 'Attended Hours',
          value: attendanceReport!.totalAttendedHours.isNotEmpty
              ? '${attendanceReport!.totalAttendedHours.split(' ').first}h'
              : '0h',
          valueColor: const Color(0xFF4285F4),
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          iconColor: const Color(0xFF4285F4),
          label: 'Absent Days',
          value: '${attendanceReport!.absentDays}',
          valueColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, height: 22, colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
          const SizedBox(width: 8),
          AppText.body(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: valueColor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: AppText.body(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (showAbsentDays) {
      return _buildAbsentDaysList();
    } else {
      return _buildPresentDaysList();
    }
  }

  Widget _buildPresentDaysList() {
    if (isAttendancesLoading) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerLoaderCard(
            child: SizedBox(height: 50),
          );
        },
      );
    }

    if (attendances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: AppText.body(
            'No attendance records found for selected date range',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        attendances.length,
        (index) {
          return _buildAttendanceItem(index);
        },
      ),
    );
  }

  Widget _buildAbsentDaysList() {
    if (isAbsentDaysLoading) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerLoaderCard(
            child: SizedBox(height: 50),
          );
        },
      );
    }

    if (absentDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: AppText.body(
            'No absent days found for selected date range',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        absentDays.length,
        (index) {
          return _buildAbsentDayItem(index);
        },
      ),
    );
  }

  String calculateAttendedTime(String signInTime, String signOutTime) {
    if (signInTime.isEmpty || signOutTime.isEmpty) {
      return 'Not Yet Signed Out';
    }

    try {
      final format = DateFormat("hh:mm:ss a");
      final signIn = format.parse(signInTime);
      final signOut = format.parse(signOutTime);

      final duration = signOut.difference(signIn);

      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      if (hours < 1) {
        return "$minutes minutes";
      } else {
        return "$hours hours $minutes minutes";
      }
    } catch (e) {
      return 'Not Yet Signed Out';
    }
  }

  String getFirstName(String name) {
    if (name == 'System Auto Signout') return name;
    return name.split(' ').first;
  }

  String formatTime(String time) {
    if (time.isEmpty) {
      return 'Not Yet Signed Out';
    }
    try {
      return DateFormat("hh:mm a").format(DateFormat("hh:mm:ss a").parse(time));
    } catch (e) {
      return time;
    }
  }

  Widget _buildAttendanceItem(int index) {
    final attendance = attendances[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(attendance.date),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: AppText.body(
          calculateAttendedTime(attendance.signInTime, attendance.signOutTime),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? index : null;
          });
        },
        children: [
          Divider(
            color: AppColors.primaryColor.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Classroom',
            text: attendance.roomName,
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign In',
            text: formatTime(attendance.signInTime),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign In By',
            text: getFirstName(attendance.signInBy),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign Out',
            text: formatTime(attendance.signOutTime),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign Out By',
            text: getFirstName(attendance.signOutBy),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsentDayItem(int index) {
    final absentDay = absentDays[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(absentDay.startDate),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? index + 1000 : null;
          });
        },
        children: [
          Divider(
            color: AppColors.primaryColor.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Classroom',
            text: student?.roomName ?? '',
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Date',
            text: '${DateFormat('MMM dd, yyyy').format(absentDay.startDate)} - ${DateFormat('MMM dd, yyyy').format(absentDay.endDate)}',
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Marked By',
            text: getFirstName(absentDay.absentBy),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Marked Absent Time',
            text: absentDay.absentTime,
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Absent Note',
            text: absentDay.note.isNotEmpty ? absentDay.note : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceShimmer() {
    return Column(
      children: [
        ShimmerLoaderCard(
          child: Container(
            height: 300,
            width: double.infinity,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (context, index) {
            return const ShimmerLoaderCard(
              child: SizedBox(height: 50),
            );
          },
        ),
      ],
    );
  }
}
