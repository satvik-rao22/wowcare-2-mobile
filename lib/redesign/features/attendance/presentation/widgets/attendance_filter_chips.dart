import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/chip_row.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// The run of status chips over the list (4a, 4c).
///
/// One at a time, each with its own count, and tapping the live one clears
/// it back to All.
class AttendanceFilterChips extends StatelessWidget {
  const AttendanceFilterChips({
    required this.selected,
    required this.countFor,
    required this.onSelected,
    super.key,
  });

  final AttendanceFilter selected;
  final int Function(AttendanceFilter) countFor;
  final ValueChanged<AttendanceFilter> onSelected;

  @override
  Widget build(BuildContext context) => ChipRow(
    children: <Widget>[
      for (final chip in AttendanceFilter.values)
        AppChip(
          label: chip.label,
          count: '${countFor(chip)}',
          selected: chip == selected,
          onTap: () => onSelected(chip),
        ),
    ],
  );
}
