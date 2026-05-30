import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// "My Attendance" dashboard card.
///
/// Preserves the original card layout exactly:
/// header → date-range picker → profile row + stat tiles.
///
/// Data is driven by [MyAttendanceCubit]; mock constants are replaced with
/// live values once loaded. Shimmer is shown only on the very first load.
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<MyAttendanceCubit>().load());
    });
  }

  void _onDateRangeSelected(DateTime? start, DateTime? end) {
    if (start == null || end == null) return;
    unawaited(context.read<MyAttendanceCubit>().changeDateRange(start, end));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyAttendanceCubit, MyAttendanceState>(
      // Rebuild only when aggregation values or load state change.
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.attendedDays != curr.attendedDays ||
          prev.attendedHours != curr.attendedHours ||
          prev.absentDays != curr.absentDays ||
          prev.staffName != curr.staffName,
      builder: (context, state) {
        // Show full-card shimmer on the very first load (before any data).
        if (state.isInitial || (state.isLoading && !state.attendanceLoaded)) {
          return _buildShimmer();
        }

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
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
                  onRangeSelected: _onDateRangeSelected,
                ),
                const SizedBox(height: 20),

                // Collapsible attendance report — same structure as before.
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _minimized
                      ? const SizedBox.shrink()
                      : _AttendanceReportColumn(
                          staffName: state.staffName,
                          attendedDays: state.attendedDays,
                          attendedHours: state.attendedHours,
                          absentDays: state.absentDays,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Shimmer — matches original card dimensions; shown only on first load.
  Widget _buildShimmer() {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(130, 18),
                  _shimmerBox(24, 24, radius: 6),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 48, radius: 8),
              const SizedBox(height: 20),
              // Profile row
              Row(
                children: [
                  _shimmerBox(80, 80, radius: 40),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(120, 18),
                      const SizedBox(height: 8),
                      _shimmerBox(80, 24, radius: 4),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stat tile placeholders
              _shimmerBox(double.infinity, 52, radius: 12),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 52, radius: 12),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 52, radius: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, {double radius = 4}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ---------------------------------------------------------------------------
// Profile row + attendance stat tiles
// ---------------------------------------------------------------------------

/// Identical layout to the original _AttendanceReportColumn, now receiving
/// real values instead of reading mock constants.
class _AttendanceReportColumn extends StatelessWidget {
  const _AttendanceReportColumn({
    required this.staffName,
    required this.attendedDays,
    required this.attendedHours,
    required this.absentDays,
  });

  final String staffName;
  final int attendedDays;
  final int attendedHours;
  final int absentDays;

  @override
  Widget build(BuildContext context) {
    final displayName = staffName.isNotEmpty ? staffName : '—';

    return Column(
      children: [
        // ── Profile row ──────────────────────────────────────────────────
        Row(
          children: [
            Stack(
              children: [
                DocumentImageWidget(
                  fileUuid: '',
                  name: displayName,
                  size: 80,
                  fontSize: 28,
                  disableProfileLookupFallback: true,
                  disableAttendanceStatusLookup: true,
                ),
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
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 22 * (-3 / 100),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Stat tiles ───────────────────────────────────────────────────
        _AttendanceInfoTile(
          icon: MediaRes.calenderClockIcon,
          label: 'Attended Days',
          text: attendedDays.toString(),
          valueColor: const Color.fromRGBO(52, 199, 89, 1),
        ),
        const SizedBox(height: 16),
        _AttendanceInfoTile(
          icon: MediaRes.timerIcon,
          label: 'Attended Hours',
          text: attendedHours.toString(),
          valueColor: AppColors.secondaryColor,
          hasSubscript: true,
        ),
        const SizedBox(height: 16),
        _AttendanceInfoTile(
          icon: MediaRes.calenderClockIcon,
          label: 'Absent Days',
          text: absentDays.toString(),
          valueColor: const Color.fromRGBO(255, 117, 110, 1),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat tile — unchanged from original design.
// ---------------------------------------------------------------------------

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
