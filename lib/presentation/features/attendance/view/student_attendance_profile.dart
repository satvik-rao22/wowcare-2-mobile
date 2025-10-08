import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/widgets/staff_attendance_vertical_popup.dart';
import 'package:wowcare/presentation/features/attendance/widgets/student_attendance_card.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentAttendanceProfile extends StatefulWidget {
  static const String routeName = '/student-attendance-profile';

  const StudentAttendanceProfile({
    super.key,
  });

  @override
  State<StudentAttendanceProfile> createState() => _StudentAttendanceProfileState();
}

class _StudentAttendanceProfileState extends State<StudentAttendanceProfile> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "View Staff Attendance",
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontSize: responsive.titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff573353),
                          ),
                        ),
                      ),
                    ),
                    // Gradient action button opening vertical popup
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showActionMenu(context),
                          child: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
              _buildDateRangePicker(context),
              // Row(
              //   children: [
              //     Expanded(child: _buildDateRangePicker(context)),
              //     const SizedBox(width: 16),
              //     _buildActionMenuButton(context),
              //   ],
              // ),
              const SizedBox(height: 16),
              _buildStudentCard(context),
              const SizedBox(height: 16),
              _buildAttendanceList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDatePickerField(
            label: 'From',
            date: _startDate,
            onTap: () => _selectDate(true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDatePickerField(
            label: 'To',
            date: _endDate,
            onTap: () => _selectDate(false),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff573353),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select Date',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff573353),
                    ),
                  ),
                ),
                SvgPicture.asset(
                  MediaRes.calender_icon,
                  height: 20,
                  colorFilter: const ColorFilter.mode(Color(0xff573353), BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
          context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: isStartDate ? _startDate : _endDate,
        ),
      );
      
      if (result != null && result['date'] != null) {
        final picked = result['date'] as DateTime;
          setState(() {
          if (isStartDate) {
            _startDate = picked;
            // If end date is before start date, update end date
            if (_endDate != null && _endDate!.isBefore(picked)) {
              _endDate = picked;
            }
          } else {
            _endDate = picked;
            // If start date is after end date, update start date
            if (_startDate != null && _startDate!.isAfter(picked)) {
              _startDate = picked;
            }
          }
            _isLoading = true;
          });
        
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
    } catch (e) {
      print('Error opening calendar dialog: $e');
    }
  }

  Widget _buildActionMenuButton(BuildContext context) {
    return SizedBox(
      height: 45,
      width: 45,
      child: Material(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showActionMenu(context),
          child: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.only(
            top: 100,
            bottom: MediaQuery.of(context).size.height * 0.45,
            left: MediaQuery.of(context).size.width * 0.75,
            right: 16,
          ),
          child: StaffAttendanceVerticalPopupOnly(
            students: const [],
            refreshCallback: () {},
            topPosition: 100,
            leftPosition: MediaQuery.of(context).size.width * 0.75,
            rightPosition: 16,
            bottomPosition: MediaQuery.of(context).size.height * 0.45,
          ),
        );
      },
    );
  }

  Widget _menuItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: const Color(0xFF4285F4)),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primaryColor.withOpacity(0.2), width: 0.5),
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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF80A3DC),
                      child: const Text('ST', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B115),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Name',
                      style: TextStyle(color: AppColors.primaryColor, fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -0.6),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Room A', style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 100),
                        // Row(
                        //   children: const [
                        //     Icon(Icons.camera_alt_outlined, size: 20),
                        //     SizedBox(width: 4),
                        //     Icon(Icons.health_and_safety_outlined, size: 20),
                        //     SizedBox(width: 4),
                        //     Icon(Icons.description_outlined, size: 20),
                        //     SizedBox(width: 4),
                        //     Icon(Icons.warning_amber_outlined, size: 20),
                        //     SizedBox(width: 4),
                        //     Icon(Icons.fastfood_outlined, size: 20),
                        //   ],
                        // ),
                      ],
                    ),
                  ],
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

  Widget _buildStats() {
    return Column(
        children: [
          _statRowSvg(iconAsset: MediaRes.calenderClockIcon, label: 'Attended Days', value: '12', valueColor: const Color(0xFF4CAF50)),
          const SizedBox(height: 16),
          _statRowSvg(iconAsset: MediaRes.timerIcon, label: 'Attended Hours', value: '48h', valueColor: const Color(0xFF4285F4)),
          const SizedBox(height: 16),
          _statRowSvg(iconAsset: MediaRes.calenderClockIcon, label: 'Absent Days', value: '2', valueColor: Colors.red),
        ],
    );
  }

  Widget _statRowSvg({required String iconAsset, required String label, required String value, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconAsset, height: 22, colorFilter: const ColorFilter.mode(Color(0xFF4285F4), BlendMode.srcIn)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: valueColor, width: 1.5)),
            child: Center(
              child: Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Dummy attendance data
    final attendanceData = [
      {
        'date': DateTime.now().subtract(const Duration(days: 0)),
        'signIn': '08:30:00 AM',
        'signOut': '05:10:00 PM',
        'roomName': 'Room A',
        'signInBy': 'John Doe',
        'signOutBy': 'Jane Smith',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'signIn': '08:45:00 AM',
        'signOut': '05:00:00 PM',
        'roomName': 'Room A',
        'signInBy': 'Mike Johnson',
        'signOutBy': 'Sarah Wilson',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'signIn': '08:20:00 AM',
        'signOut': '', // Not yet signed out
        'roomName': 'Room A',
        'signInBy': 'David Brown',
        'signOutBy': 'System Auto Signout',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'signIn': '09:00:00 AM',
        'signOut': '04:30:00 PM',
        'roomName': 'Room A',
        'signInBy': 'Lisa Davis',
        'signOutBy': 'Tom Anderson',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'signIn': '08:15:00 AM',
        'signOut': '05:15:00 PM',
        'roomName': 'Room A',
        'signInBy': 'Emma Taylor',
        'signOutBy': 'Chris Miller',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attendanceData.length,
          itemBuilder: (context, index) {
            final data = attendanceData[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StudentAttendanceCard(
                date: data['date'] as DateTime,
                signIn: data['signIn'] as String,
                signOut: data['signOut'] as String,
                roomName: data['roomName'] as String,
                signInBy: data['signInBy'] as String,
                signOutBy: data['signOutBy'] as String,
                onDelete: () {
                  // Handle delete action
                  print('Delete attendance for ${DateFormat('MMM dd, yyyy').format(data['date'] as DateTime)}');
                },
                onEdit: () {
                  // Handle edit action
                  print('Edit attendance for ${DateFormat('MMM dd, yyyy').format(data['date'] as DateTime)}');
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    final df = DateFormat('MMM dd, yyyy');
    return '${df.format(start)} - ${df.format(end)}';
  }


  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}



