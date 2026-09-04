import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_row.dart';

/// One classroom of the list, under its own eyebrow (4a).
///
/// The eyebrow's meta is counts and never a ratio figure: how many are in,
/// out of how many on the roll, with how many staff, and the verdict. It
/// turns red when the classroom is short.
class AttendanceGroupSection extends StatelessWidget {
  const AttendanceGroupSection({
    required this.group,
    required this.expandedId,
    required this.onToggle,
    this.isSelectMode = false,
    this.selectedIds = const <String>{},
    this.onMoreActions,
    super.key,
  });

  final AttendanceGroup group;
  final String? expandedId;
  final ValueChanged<AttendanceRecord> onToggle;

  final bool isSelectMode;
  final Set<String> selectedIds;

  /// Null while the day is read only or the classroom is locked.
  final ValueChanged<AttendanceRecord>? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final moreActions = onMoreActions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.sectionGap,
      children: <Widget>[
        SectionEyebrow(
          label: group.title,
          color: group.isStaffGroup ? c.staffFg : c.student,
          meta: _meta,
          metaColor: group.isShort ? c.dangerFg : c.ink2,
        ),
        for (final record in group.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AttendanceSizes.rowGap),
            child: AttendanceRow(
              record: record,
              isExpanded: expandedId == record.id,
              isSelectMode: isSelectMode,
              isSelected: selectedIds.contains(record.id),
              onTap: () => onToggle(record),
              onMoreActions: moreActions == null
                  ? null
                  : () => moreActions(record),
            ),
          ),
      ],
    );
  }

  String get _meta {
    if (group.isStaffGroup) {
      return AttendanceStrings.staffGroupMeta(
        group.presentCount,
        group.enrolled,
      );
    }
    return AttendanceStrings.groupMeta(
      signedIn: group.presentCount,
      enrolled: group.enrolled,
      staffPresent: group.staffPresent,
      verdict: _verdict,
    );
  }

  String get _verdict {
    if (group.hasNoStaff) return AttendanceStrings.noStaffInRoom;
    if (group.staffNeeded > 0) {
      return AttendanceStrings.staffShort(group.staffNeeded);
    }
    return AppStrings.inRatio;
  }
}
