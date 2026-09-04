import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/alt_well_tile.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_formats.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The week of a student's regular schedule (5d step three).
///
/// Five rows because a center's week is five days. A closed day says
/// "Closed" in both slots rather than showing times nobody will keep.
class ScheduleWeekCard extends StatelessWidget {
  const ScheduleWeekCard({
    required this.week,
    required this.onChanged,
    required this.onCopyToAllDays,
    super.key,
  });

  final List<ScheduleEntry> week;
  final ValueChanged<ScheduleEntry> onChanged;
  final VoidCallback onCopyToAllDays;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: StudentsSizes.personCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudentsSizes.scheduleRowGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  StudentsStrings.week,
                  style: StudentsTextStyles.itemTitle.copyWith(color: c.ink),
                ),
              ),
              AltWellTile(
                radius: AppRadii.chip,
                padding: StudentsSizes.smallKeyPad,
                onTap: onCopyToAllDays,
                child: Text(
                  StudentsStrings.copyToAllDays,
                  style: StudentsTextStyles.tag.copyWith(color: c.ink2),
                ),
              ),
            ],
          ),
          for (final day in week)
            Row(
              spacing: StudentsSizes.scheduleGap,
              children: <Widget>[
                SizedBox(
                  width: StudentsSizes.scheduleDayWidth,
                  child: Text(
                    day.dayLabel,
                    style: StudentsTextStyles.scheduleDay.copyWith(
                      color: day.isOpen ? c.ink : c.ink3,
                    ),
                  ),
                ),
                Expanded(
                  child: _TimeWell(
                    entry: day,
                    isStart: true,
                    onChanged: onChanged,
                  ),
                ),
                Expanded(
                  child: _TimeWell(
                    entry: day,
                    isStart: false,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One end of one day. Tapping it opens the platform time picker; a long
/// press closes the day, which is the only way to say "not this day" without
/// a control the frame does not draw.
class _TimeWell extends StatelessWidget {
  const _TimeWell({
    required this.entry,
    required this.isStart,
    required this.onChanged,
  });

  final ScheduleEntry entry;
  final bool isStart;
  final ValueChanged<ScheduleEntry> onChanged;

  int get _minutes => isStart ? entry.startMinutes : entry.endMinutes;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      helpText: StudentsStrings.dayTimeTitle(
        entry.dayLabel,
        isStart ? StudentsStrings.startTime : StudentsStrings.endTime,
      ),
    );
    if (picked == null) return;
    final value = picked.hour * 60 + picked.minute;
    onChanged(
      isStart
          ? entry.copyWith(startMinutes: value, isOpen: true)
          : entry.copyWith(endMinutes: value, isOpen: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: entry.dayLabel,
      child: Pressable.surface(
        onTap: entry.isOpen ? () => unawaited(_pick(context)) : null,
        onLongPress: () => onChanged(entry.copyWith(isOpen: !entry.isOpen)),
        child: AppWell(
          padding: StudentsSizes.timeWellPad,
          alignment: Alignment.center,
          child: Text(
            entry.isOpen
                ? StudentsFormats.clock(_minutes)
                : StudentsStrings.closed,
            style: StudentsTextStyles.scheduleTime.copyWith(
              color: entry.isOpen ? c.ink : c.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
