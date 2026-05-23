import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Mock data — replaces the cubit-driven attendance report.
// ---------------------------------------------------------------------------
const String _mockStaffName = 'Sarah Johnson';
const String _mockRoomName = 'Sunflower Room';
const int _mockAttendedDays = 18;
const String _mockAttendedHours = '126';
const int _mockAbsentDays = 2;

/// "My Attendance" dashboard card.
///
/// UI-only port of the reference card: header (title + redirect + collapse),
/// a date-range field, then the staff attendance report (profile + day/hour
/// stat tiles — the reference's `StaffAttendanceProfileCard` body).
class MyAttendanceCard extends StatefulWidget {
  const MyAttendanceCard({super.key});

  @override
  State<MyAttendanceCard> createState() => _MyAttendanceCardState();
}

class _MyAttendanceCardState extends State<MyAttendanceCard> {
  bool _minimized = false;
  late final DateTime _startDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardHeader(
              title: 'My Attendance',
              minimized: _minimized,
              onToggle: () => setState(() => _minimized = !_minimized),
              showRedirect: true,
              onRedirect: () {},
            ),
            const SizedBox(height: 16),

            // Date-range filter (always visible).
            CustomDateTimeField(
              hasLabel: false,
              isRangePicker: true,
              initialDate: _startDate,
              label: 'Date Range',
              onRangeSelected: (start, end) {},
            ),
            const SizedBox(height: 20),

            // Collapsible attendance report.
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _minimized
                  ? const SizedBox.shrink()
                  : const _AttendanceReportColumn(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile row + attendance stat tiles (port of the reference's
/// `StaffAttendanceProfileCard._buildReportColumn`).
class _AttendanceReportColumn extends StatelessWidget {
  const _AttendanceReportColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Profile row ──────────────────────────────────────────────────
        Row(
          children: [
            Stack(
              children: [
                const DocumentImageWidget(
                  fileUuid: '',
                  name: _mockStaffName,
                  size: 80,
                  fontSize: 28,
                  disableProfileLookupFallback: true,
                  disableAttendanceStatusLookup: true,
                ),
                // Signed-in status indicator.
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 177, 21, 1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    _mockStaffName,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 22 * (-3 / 100),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      _mockRoomName,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Stat tiles ───────────────────────────────────────────────────
        const _AttendanceInfoTile(
          icon: MediaRes.calenderClockIcon,
          label: 'Attended Days',
          text: '$_mockAttendedDays',
          valueColor: Color.fromRGBO(52, 199, 89, 1),
        ),
        const SizedBox(height: 16),
        const _AttendanceInfoTile(
          icon: MediaRes.timerIcon,
          label: 'Attended Hours',
          text: _mockAttendedHours,
          valueColor: AppColors.secondaryColor,
          hasSubscript: true,
        ),
        const SizedBox(height: 16),
        const _AttendanceInfoTile(
          icon: MediaRes.calenderClockIcon,
          label: 'Absent Days',
          text: '$_mockAbsentDays',
          valueColor: Color.fromRGBO(255, 117, 110, 1),
        ),
      ],
    );
  }
}

/// Port of `StaffAttendanceProfileCardInfoTile` — a bordered row with an icon,
/// a label, and a circular value badge.
class _AttendanceInfoTile extends StatelessWidget {
  const _AttendanceInfoTile({
    required this.icon,
    required this.label,
    required this.text,
    required this.valueColor,
    this.hasSubscript = false,
  });

  final String icon;
  final String label;
  final String text;
  final Color valueColor;
  final bool hasSubscript;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SvgPicture.asset(icon, height: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: valueColor, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Text.rich(
              TextSpan(
                text: text,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                children: hasSubscript
                    ? [
                        WidgetSpan(
                          child: Transform.translate(
                            offset: const Offset(0, -1),
                            child: Text(
                              'h',
                              textScaler: const TextScaler.linear(0.6),
                              style: TextStyle(
                                color: valueColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
