import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/tone_colors.dart';

/// One staff member in a classroom (7c's Staff tab): who they are, what they
/// do, where they are on today's clock, and the classrooms they cover.
///
/// No sign-in PIN anywhere on the row. That is on the module's costly list.
class StaffRow extends StatelessWidget {
  const StaffRow({required this.person, this.onCall, super.key});

  final ClassroomStaffMember person;

  /// The call key at the end of the row. Absent when there is no number.
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: ClassroomsSizes.staffRowPad,
      child: Row(
        spacing: ClassroomsSizes.rosterGapInner,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.avatar(
              c,
              fill: c.staffBg,
              size: ClassroomsSizes.staffAvatar,
            ),
            width: ClassroomsSizes.staffAvatar,
            height: ClassroomsSizes.staffAvatar,
            alignment: Alignment.center,
            child: Text(
              person.initials,
              style: ClassroomsTextStyles.rosterInitials.copyWith(
                color: c.staffFg,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ClassroomsSizes.staffRowTextGap,
              children: <Widget>[
                Text(
                  person.name,
                  style: AppTextStyles.rowName.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  person.designation,
                  style: ClassroomsTextStyles.staffRole.copyWith(
                    color: c.staffFg,
                  ),
                ),
                if (person.timesLabel.isNotEmpty)
                  Text(
                    person.timesLabel,
                    style: ClassroomsTextStyles.staffMeta.copyWith(
                      color: c.ink3,
                    ),
                  ),
                if (person.classroomsLabel.isNotEmpty)
                  Text(
                    person.classroomsLabel,
                    style: ClassroomsTextStyles.staffMeta.copyWith(
                      color: c.ink3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: ClassroomsSizes.staffTrailingGap,
            children: <Widget>[
              StatusPill(
                label: _stateLabel(person.state),
                tone: person.state.pillTone,
                small: true,
              ),
              if (onCall != null)
                IconKey(
                  icon: AppIcons.phone,
                  size: AppSizes.backKey,
                  semanticLabel: person.name,
                  onTap: onCall,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _stateLabel(StaffDutyState state) => switch (state) {
    StaffDutyState.onDuty => ClassroomsStrings.onDuty,
    StaffDutyState.onBreak => ClassroomsStrings.onBreak,
    StaffDutyState.notMarked => AppStrings.notMarked,
    StaffDutyState.absent => AppStrings.absent,
    StaffDutyState.signedOut => AppStrings.signedOut,
  };
}
