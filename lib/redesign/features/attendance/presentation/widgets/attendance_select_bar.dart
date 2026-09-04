import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_docked_bar.dart';

/// The row that docks under the list while people are being picked (4a).
///
/// With nobody picked the key is off and says what it wants, rather than
/// being pink and doing nothing. It sits above the tab bar, so the five slots
/// are still reachable mid-selection.
class AttendanceSelectBar extends StatelessWidget {
  const AttendanceSelectBar({
    required this.audience,
    required this.selectedCount,
    required this.onClear,
    required this.onSignIn,
    super.key,
  });

  final AttendanceAudience audience;
  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    // No safe-area pad of its own: the tab bar sits under this and carries
    // the inset for both.
    return AttendanceDockedBar(
      child: Row(
        spacing: AttendanceSizes.selectBarGap,
        children: <Widget>[
          SecondaryKey(
            label: AppStrings.clear,
            expand: false,
            padding: AttendanceSizes.selectClearPad,
            onTap: onClear,
          ),
          Expanded(
            child: PrimaryKey(
              label: hasSelection ? _label : AttendanceStrings.pickWhoArrived,
              enabled: hasSelection,
              onTap: onSignIn,
            ),
          ),
        ],
      ),
    );
  }

  String get _label => audience.isStudents
      ? AttendanceStrings.signInCount(selectedCount)
      : AttendanceStrings.signInStaffCount(selectedCount);
}
