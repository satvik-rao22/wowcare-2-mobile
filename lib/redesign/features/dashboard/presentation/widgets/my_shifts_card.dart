import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// A staff member's week (3S2).
///
/// A day off is drawn rather than skipped, faded back, so the week reads as a
/// week and not as a list of the days that happen to have work in them.
class MyShiftsCard extends StatelessWidget {
  const MyShiftsCard({
    required this.days,
    required this.rangeLabel,
    super.key,
  });

  final List<ShiftDay> days;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.summaryTileGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.myShifts,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              Text(
                rangeLabel,
                style: AppTextStyles.sectionLink.copyWith(color: c.ink3),
              ),
            ],
          ),
          for (final day in days) _Row(day: day),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.day});

  final ShiftDay day;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final row = SurfaceBox(
      surface: day.isToday
          ? AppSurfaces.radioCard(c, selected: true)
          : AppSurfaces.altWell(c),
      padding: DashboardSizes.shiftRowPad,
      child: Row(
        spacing: DashboardSizes.shiftRowGap,
        children: <Widget>[
          SizedBox(
            width: DashboardSizes.shiftDayColumn,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  day.weekdayLabel,
                  style: DashboardTextStyles.shiftDayLabel.copyWith(
                    color: c.ink3,
                  ),
                ),
                Text(
                  '${day.dayNumber}',
                  style: DashboardTextStyles.shiftDayNumber.copyWith(
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: day.isDayOff
                ? Text(
                    DashboardStrings.dayOff,
                    style: DashboardTextStyles.shiftTitle.copyWith(
                      color: c.ink3,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        day.isCovering
                            ? DashboardStrings.coveringNoTime(
                                day.classroomName!,
                              )
                            : day.classroomName!,
                        style: DashboardTextStyles.shiftTitle.copyWith(
                          color: c.ink,
                        ),
                      ),
                      Text(
                        day.breakWindow == null
                            ? day.window!
                            : DashboardStrings.shiftLine(
                                day.window!,
                                day.breakWindow!,
                              ),
                        style: DashboardTextStyles.innerRowSub.copyWith(
                          color: c.ink3,
                        ),
                      ),
                    ],
                  ),
          ),
          if (day.isToday)
            const StatusPill(
              label: DashboardStrings.today,
              tone: PillTone.student,
              small: true,
            ),
        ],
      ),
    );

    if (!day.isDayOff) return row;
    return Opacity(opacity: DashboardSizes.dayOffOpacity, child: row);
  }
}
