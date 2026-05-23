import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Local mock data — replaces the cubit-driven attendance report and student
// entity that the original source fetched via API / service-locator.
// ---------------------------------------------------------------------------

class _MockAttendanceReport {
  const _MockAttendanceReport({
    required this.attendedDays,
    required this.totalAttendedHours,
    required this.absentDays,
  });
  final int attendedDays;
  final String totalAttendedHours;
  final int absentDays;
}

class _MockStudent {
  const _MockStudent({
    required this.fullName,
    required this.isSignedIn,
    required this.isAbsent,
    this.profileStatus = 'Active',
    this.medications = '',
    this.note = '',
    this.allergies = '',
    this.dietRestriction = '',
    this.isPhotoPermission = true,
  });
  final String fullName;
  final bool isSignedIn;
  final bool isAbsent;
  final String profileStatus;
  final String medications;
  final String note;
  final String allergies;
  final String dietRestriction;
  final bool isPhotoPermission;
}

const _mockStudents = <_MockStudent>[
  _MockStudent(
    fullName: 'Emma Johnson',
    isSignedIn: true,
    isAbsent: false,
    profileStatus: 'Active',
    medications: 'Allergy relief (10 mg daily)',
    note: 'Prefers indoor activities',
    allergies: 'Peanuts',
    dietRestriction: 'Nut-free meals',
    isPhotoPermission: true,
  ),
  _MockStudent(
    fullName: 'Liam Johnson',
    isSignedIn: false,
    isAbsent: false,
    profileStatus: 'Active',
    isPhotoPermission: false,
  ),
];

const _mockReport = _MockAttendanceReport(
  attendedDays: 16,
  totalAttendedHours: '112 hours',
  absentDays: 2,
);

// ---------------------------------------------------------------------------
// StudentAttendanceCard
// ---------------------------------------------------------------------------

/// Dashboard card showing a student's attendance summary for a date range.
///
/// UI-only port of the reference `StudentAttendanceCard`: header with
/// collapse toggle and redirect, student selector row, date-range picker,
/// and three attendance stat tiles (attended days, attended hours, absent
/// days).
class StudentAttendanceCard extends StatefulWidget {
  const StudentAttendanceCard({super.key});

  @override
  State<StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<StudentAttendanceCard> {
  bool _minimized = false;
  late DateTime _startDate;
  int _selectedStudentIndex = 0;

  _MockStudent get _currentStudent => _mockStudents[_selectedStudentIndex];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
  }

  void _onDateRangeSelected(DateTime start, DateTime? end) {
    setState(() {
      _startDate = start;
    });
  }

  // --------------------------------------------------------------------------
  // Sub-builders
  // --------------------------------------------------------------------------

  Color _statusDotColor(_MockStudent s) {
    if (s.profileStatus == 'Upcoming') {
      return const Color.fromARGB(255, 253, 205, 22);
    }
    if (s.isSignedIn) return const Color.fromRGBO(0, 177, 21, 1);
    if (s.isAbsent) return const Color.fromRGBO(200, 32, 32, 1);
    return Colors.transparent;
  }

  bool _hasDotBorder(_MockStudent s) =>
      s.profileStatus == 'Upcoming' || s.isSignedIn || s.isAbsent;

  Widget _buildStudentRow() {
    final hasMultiple = _mockStudents.length > 1;
    if (hasMultiple) {
      // Dropdown to switch between mock students
      return Expanded(
        child: CustomDropdown(
          hintText: 'Student',
          items: _mockStudents.map((s) => s.fullName).toList(),
          selectedItem: _mockStudents[_selectedStudentIndex].fullName,
          isField: false,
          prependHintAsSelectableItem: false,
          onSelect: (value) {
            if (value == null) return;
            final idx =
                _mockStudents.indexWhere((s) => s.fullName == value);
            if (idx >= 0) {
              setState(() => _selectedStudentIndex = idx);
            }
          },
        ),
      );
    }

    // Single student: show avatar + name + optional detail icons
    final s = _currentStudent;
    final hasDetails = !s.isPhotoPermission ||
        s.medications.isNotEmpty ||
        s.note.isNotEmpty ||
        s.allergies.isNotEmpty ||
        s.dietRestriction.isNotEmpty;

    return Expanded(
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                DocumentImageWidget(
                  fileUuid: '',
                  name: s.fullName,
                  size: 30,
                  fontSize: 12,
                  disableProfileLookupFallback: true,
                  disableAttendanceStatusLookup: true,
                ),
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _statusDotColor(s) == Colors.transparent
                          ? null
                          : _statusDotColor(s),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _hasDotBorder(s)
                            ? Colors.white
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 9,
                      minHeight: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                s.fullName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasDetails) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDetailsDialog(s),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!s.isPhotoPermission)
                          _buildIconItem(MediaRes.cameraIcon),
                        if (s.medications.isNotEmpty)
                          _buildIconItem(MediaRes.healthIcon),
                        if (s.note.isNotEmpty)
                          _buildIconItem(MediaRes.docsIcon),
                        if (s.allergies.isNotEmpty)
                          _buildIconItem(MediaRes.alertIcon),
                        if (s.dietRestriction.isNotEmpty)
                          _buildIconItem(MediaRes.foodIcon2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(_MockStudent s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Details',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!s.isPhotoPermission)
              _buildIconDetail(MediaRes.cameraIcon, 'No Photo Permission'),
            if (s.medications.isNotEmpty)
              _buildIconDetail(MediaRes.healthIcon, s.medications),
            if (s.note.isNotEmpty)
              _buildIconDetail(MediaRes.docsIcon, s.note),
            if (s.allergies.isNotEmpty)
              _buildIconDetail(MediaRes.alertIcon, s.allergies),
            if (s.dietRestriction.isNotEmpty)
              _buildIconDetail(MediaRes.foodIcon2, s.dietRestriction),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconItem(String icon) {
    final isSvg = icon.toLowerCase().endsWith('.svg');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: isSvg
          ? SvgPicture.asset(icon, height: 20)
          : Image.asset(icon, height: 20),
    );
  }

  Widget _buildIconDetail(String iconPath, String detail) {
    final isSvg = iconPath.toLowerCase().endsWith('.svg');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          isSvg
              ? SvgPicture.asset(iconPath, height: 24)
              : Image.asset(iconPath, height: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              detail,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, height: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: valueColor, width: 1.5),
            ),
            child: Center(
              child: Text(
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

  Widget _buildStats() {
    final attendedHoursLabel =
        _mockReport.totalAttendedHours.isNotEmpty
            ? '${_mockReport.totalAttendedHours.split(' ').first}h'
            : '0h';

    return Column(
      children: [
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          label: 'Attended Days',
          value: '${_mockReport.attendedDays}',
          valueColor: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          icon: MediaRes.timerIcon,
          label: 'Attended Hours',
          value: attendedHoursLabel,
          valueColor: const Color(0xFF4285F4),
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          label: 'Absent Days',
          value: '${_mockReport.absentDays}',
          valueColor: Colors.red,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
        highlightColor: AppColors.primaryColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardCardHeader(
                title: 'Attendance',
                minimized: _minimized,
                onToggle: () => setState(() => _minimized = !_minimized),
                showRedirect: true,
                onRedirect: () {},
                trailing: _buildStudentRow(),
              ),
              if (!_minimized) ...[
                const SizedBox(height: 16),
                CustomDateTimeField(
                  hasLabel: false,
                  isRangePicker: true,
                  initialDate: _startDate,
                  label: 'Date Range',
                  onRangeSelected: _onDateRangeSelected,
                ),
                const SizedBox(height: 20),
                _buildStats(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
