import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/widgets/staff_attendance_vertical_popup.dart';

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
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildDateRangePicker(context)),
                  const SizedBox(width: 16),
                  _buildActionMenuButton(context),
                ],
              ),
              const SizedBox(height: 16),
              _buildStudentCard(context),
              const SizedBox(height: 16),
              _isLoading ? _buildShimmerList() : _buildStatsAndList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    final rangeText = _formatRange(_startDate, _endDate);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        side: BorderSide(color: AppColors.primaryColor.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
          initialDateRange: _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
        );
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
            _isLoading = true;
          });
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      child: Row(
        children: [
          SvgPicture.asset(MediaRes.calenderClockIcon, height: 20, colorFilter: const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rangeText.isEmpty ? 'Date Range' : rangeText,
              style: const TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryColor),
        ],
      ),
    );
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
                        Row(
                          children: const [
                            Icon(Icons.camera_alt_outlined, size: 20),
                            SizedBox(width: 4),
                            Icon(Icons.health_and_safety_outlined, size: 20),
                            SizedBox(width: 4),
                            Icon(Icons.description_outlined, size: 20),
                            SizedBox(width: 4),
                            Icon(Icons.warning_amber_outlined, size: 20),
                            SizedBox(width: 4),
                            Icon(Icons.fastfood_outlined, size: 20),
                          ],
                        ),
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

  Widget _buildStatsAndList() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            final date = DateTime.now().subtract(Duration(days: index));
            return _attendanceItem(
              date: date,
              signIn: '08:30:00 AM',
              signOut: index % 3 == 0 ? '' : '05:10:00 PM',
              roomName: 'Room A',
              signInBy: 'John Doe',
              signOutBy: 'Jane Smith',
            );
          },
        ),
      ],
    );
  }

  Widget _attendanceItem({
    required DateTime date,
    required String signIn,
    required String signOut,
    required String roomName,
    required String signInBy,
    required String signOutBy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          DateFormat('MMM dd, yyyy').format(date),
          style: const TextStyle(color: Color(0xff573353), fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          _calculateAttendedTime(signIn, signOut),
          style: const TextStyle(color: Color(0xff573353), fontSize: 16, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        collapsedShape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0x33573353)),
          borderRadius: BorderRadius.circular(14),
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0x33573353)),
          borderRadius: BorderRadius.circular(14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Color(0x1A573353)),
          const SizedBox(height: 16),
          _labelValue(label: 'Classroom', value: roomName),
          const SizedBox(height: 16),
          _labelValue(label: 'Sign In', value: _formatTime(signIn)),
          const SizedBox(height: 16),
          _labelValue(label: 'Sign In By', value: _firstName(signInBy)),
          const SizedBox(height: 16),
          _labelValue(label: 'Sign Out', value: _formatTime(signOut)),
          const SizedBox(height: 16),
          _labelValue(label: 'Sign Out By', value: _firstName(signOutBy)),
        ],
      ),
    );
  }

  Widget _labelValue({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xff573353))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      ],
    );
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 50,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    final df = DateFormat('MMM dd, yyyy');
    return '${df.format(start)} - ${df.format(end)}';
  }

  String _formatTime(String time) {
    if (time.isEmpty) return 'Not Yet Signed Out';
    return DateFormat('hh:mm a').format(DateFormat('hh:mm:ss a').parse(time));
  }

  String _calculateAttendedTime(String signInTime, String signOutTime) {
    if (signInTime.isEmpty || signOutTime.isEmpty) return 'Not Yet Signed Out';
    final format = DateFormat('hh:mm:ss a');
    final signIn = format.parse(signInTime);
    final signOut = format.parse(signOutTime);
    final duration = signOut.difference(signIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours < 1) return '$minutes minutes';
    return '$hours hours $minutes minutes';
  }

  String _firstName(String name) {
    if (name == 'System Auto Signout') return name;
    return name.split(' ').first;
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}



