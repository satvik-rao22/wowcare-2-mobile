import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6c's Attendance tab: the month's total, then a row a day.
///
/// It reports and totals nothing more. Timesheets are on the module's costly
/// list, so there is no export, no approval and no pay here.
class AttendanceTab extends StatelessWidget {
  const AttendanceTab({required this.profile, super.key});

  final StaffProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final summary = profile.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.cardGap,
      children: <Widget>[
        if (summary != null)
          SectionEyebrow(
            label: StaffStrings.longMonths[summary.month.month - 1],
            color: c.staffFg,
            meta: StaffStrings.attendanceSummary(
              summary.daysAttended,
              summary.daysAbsent,
              StaffStrings.duration(summary.workedMinutes),
            ),
          ),
        for (final day in profile.days)
          _DayRow(day: day, initials: profile.member.initials),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.initials});

  final StaffAttendanceDay day;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: StaffSizes.documentRowPad,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          Container(
            width: StaffSizes.dayAvatar,
            height: StaffSizes.dayAvatar,
            padding: const EdgeInsets.all(StaffSizes.avatarRingPad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: day.status.colour(c),
                width: StaffSizes.avatarRing,
              ),
            ),
            child: AppAvatar(
              initials: initials,
              size: StaffSizes.dayAvatarInner,
              tone: AvatarTone.staff,
              textStyle: StaffTextStyles.dayInitials,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  StaffStrings.weekdayDate(day.date),
                  style: StaffTextStyles.rowTitle.copyWith(color: c.ink),
                ),
                Text(
                  _detail(),
                  style: StaffTextStyles.rowDetail.copyWith(color: c.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: AppSizes.rowTextGap,
            children: <Widget>[
              Text(
                StaffStrings.attendanceLabel(day.status),
                style: StaffTextStyles.rowStatus.copyWith(color: _ink(c)),
              ),
              Text(
                day.workedMinutes == null
                    ? StaffStrings.dash
                    : StaffStrings.duration(day.workedMinutes!),
                style: StaffTextStyles.rowHours.copyWith(color: c.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _detail() {
    if (day.note.isNotEmpty) return day.note;
    final start = day.startMinutes;
    if (start == null) return StaffStrings.expectedToday;
    final end = day.endMinutes;
    final line = end == null
        ? StaffStrings.signedInDetail(StaffStrings.clock(start))
        : StaffStrings.signedRange(
            StaffStrings.clock(start),
            StaffStrings.clock(end),
          );
    return day.classroom.isEmpty
        ? line
        : StaffStrings.shiftDetail(line, day.classroom);
  }

  Color _ink(Colourway c) => switch (day.status) {
    AttendanceStatus.signedIn => c.successFg,
    AttendanceStatus.signedOut => c.ink,
    AttendanceStatus.absent => c.dangerFg,
    AttendanceStatus.notMarked => c.ink2,
  };
}
