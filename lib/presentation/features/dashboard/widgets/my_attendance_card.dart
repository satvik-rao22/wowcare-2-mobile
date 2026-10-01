import 'dart:async';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/presentation/features/dashboard/model/dashboard_route_args.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_collapsible.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_error_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// "My Attendance" dashboard card: header, date-range picker, profile row and
/// stat tiles, driven by [MyAttendanceCubit]. Shimmer on first load only.
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
    final now = AppTime.now();
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
          prev.staffName != curr.staffName ||
          prev.staffCode != curr.staffCode,
      builder: (context, state) {
        // Show full-card shimmer on the very first load (before any data).
        if (state.isInitial || (state.isLoading && !state.attendanceLoaded)) {
          return _buildShimmer();
        }

        return DashboardCardErrorOverlay(
          show: state.isError,
          onRetry: () => context.read<MyAttendanceCubit>().load(),
          child: Card(
            elevation: 0,
            color: AppColors.whiteColor,
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
                    onRedirect: () => context.push(
                      StaffAttendanceProfile.routeName,
                      extra: StaffAttendanceProfileArgs(
                        staffCode: state.staffCode,
                        staffName: state.staffName,
                      ),
                    ),
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

                  DashboardCollapsible(
                    collapsed: _minimized,
                    child: _AttendanceReportColumn(
                      staffCode: state.staffCode,
                      staffName: state.staffName,
                      attendedDays: state.attendedDays,
                      attendedHours: state.attendedHours,
                      attendedMinutes: state.attendedMinutes,
                      absentDays: state.absentDays,
                    ),
                  ),
                ],
              ),
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
      color: AppColors.whiteColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: MaterialHues.grey300,
          highlightColor: MaterialHues.grey100,
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
      color: AppColors.whiteColor,
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
    required this.staffCode,
    required this.staffName,
    required this.attendedDays,
    required this.attendedHours,
    required this.attendedMinutes,
    required this.absentDays,
  });

  final String staffCode;
  final String staffName;
  final int attendedDays;
  final int attendedHours;
  final int attendedMinutes;
  final int absentDays;

  @override
  Widget build(BuildContext context) {
    final displayName = staffName.isNotEmpty ? staffName : '—';

    return Column(
      children: [
        // ── Profile row ──────────────────────────────────────────────────
        Row(
          children: [
            DocumentImageWidget(
              fileUuid: '',
              staffCode: staffCode.isNotEmpty ? staffCode : null,
              name: displayName,
              size: 80,
              fontSize: 28,
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
          valueColor: AppPalette.statusSuccess,
        ),
        const SizedBox(height: 16),
        _AttendanceHoursTile(hours: attendedHours, minutes: attendedMinutes),
        const SizedBox(height: 16),
        _AttendanceInfoTile(
          icon: MediaRes.calenderClockIcon,
          label: 'Absent Days',
          text: absentDays.toString(),
          valueColor: AppPalette.statusError,
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
  });

  final String icon;
  final String label;
  final String text;
  final Color valueColor;

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
          AppIcon(icon, height: 30),
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
            child: Text(
              text,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHoursTile extends StatelessWidget {
  const _AttendanceHoursTile({required this.hours, required this.minutes});

  final int hours;
  final int minutes;

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
          AppIcon(MediaRes.timerIcon, height: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Attended Hours',
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              _ValueCircle(text: '${hours}h'),
              const SizedBox(width: 8),
              _ValueCircle(text: '${minutes}m'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueCircle extends StatelessWidget {
  const _ValueCircle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.statusInfo, width: 1.5),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppPalette.statusInfo,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
