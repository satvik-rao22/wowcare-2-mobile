import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/note_well.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6c's Schedule tab: the working week, and the note that says why a break is
/// the classroom's business as well as the person's.
class ScheduleTab extends StatelessWidget {
  const ScheduleTab({required this.profile, this.onEdit, super.key});

  final StaffProfile profile;

  /// Null for anyone but an Admin: a work schedule is Admin-only.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final today = profile.asOf;
    final firstBreak = profile.firstBreak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.sectionGap,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: StaffSizes.weekRowGap,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      StaffStrings.thisWeek,
                      style: StaffTextStyles.cardHeading.copyWith(color: c.ink),
                    ),
                  ),
                  Text(
                    StaffStrings.contracted(
                      StaffStrings.duration(profile.contractedMinutes),
                    ),
                    style: StaffTextStyles.smallKey.copyWith(color: c.staffFg),
                  ),
                ],
              ),
              for (final shift in profile.week)
                _DayRow(shift: shift, isToday: _isSameDay(shift.date, today)),
              if (onEdit != null)
                SecondaryKey(
                  label: StaffStrings.editTheWeek,
                  padding: StaffSizes.dockedKeyPad,
                  onTap: onEdit,
                ),
            ],
          ),
        ),
        if (firstBreak != null)
          NoteWell(
            title: StaffStrings.breaksTitle,
            body: StaffStrings.breaksBody(
              profile.firstName,
              StaffStrings.clock(firstBreak.breakStartMinutes!),
              firstBreak.classroom.isEmpty
                  ? StaffStrings.scopeOf(profile.member)
                  : firstBreak.classroom,
            ),
          ),
      ],
    );
  }

  static bool _isSameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

/// One day of the week: the date, the shift, and what it is worth.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.shift, required this.isToday});

  final StaffShift shift;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isOff = shift.isDayOff;

    return Container(
      padding: StaffSizes.weekRowPad,
      decoration: BoxDecoration(
        // Today is the one day tinted, and it takes the student teal because
        // what it is saying is which classroom is covered right now.
        color: isToday ? c.studentBg : c.sub,
        borderRadius: AppRadii.innerR,
        border: isToday ? Border.all(color: c.studentLine) : null,
      ),
      child: Row(
        spacing: StaffSizes.weekRowGap,
        children: <Widget>[
          SizedBox(
            width: StaffSizes.dayColumnWidth,
            child: Column(
              children: <Widget>[
                Text(
                  StaffStrings.weekdayShort(shift.weekday),
                  style: StaffTextStyles.weekDay.copyWith(
                    color: isToday ? c.student : c.ink3,
                  ),
                ),
                Text(
                  shift.date == null ? StaffStrings.dash : '${shift.date!.day}',
                  style: StaffTextStyles.weekDate.copyWith(
                    color: isOff ? c.ink3 : c.ink,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isOff
                      ? StaffStrings.notScheduled
                      : StaffStrings.signedRange(
                          StaffStrings.clock(shift.startMinutes!),
                          StaffStrings.clock(shift.endMinutes!),
                        ),
                  style: StaffTextStyles.weekShift.copyWith(color: c.ink),
                ),
                Text(
                  _detail(),
                  style: StaffTextStyles.weekDetail.copyWith(color: c.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusPill(
            label: _pillLabel(),
            tone: isToday ? PillTone.success : PillTone.neutral,
            small: true,
          ),
        ],
      ),
    );
  }

  String _detail() {
    if (shift.isDayOff) return StaffStrings.dayOff;
    final breakLine = shift.hasBreak
        ? StaffStrings.breakRange(
            StaffStrings.clock(shift.breakStartMinutes!),
            StaffStrings.clock(shift.breakEndMinutes!),
          )
        : StaffStrings.noBreakSet;
    return shift.classroom.isEmpty
        ? breakLine
        : StaffStrings.shiftDetail(shift.classroom, breakLine);
  }

  String _pillLabel() {
    if (isToday) return StaffStrings.today;
    if (shift.isDayOff) return StaffStrings.dash;
    return StaffStrings.duration(shift.workedMinutes);
  }
}
