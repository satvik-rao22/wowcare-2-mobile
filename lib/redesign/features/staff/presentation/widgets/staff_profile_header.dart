import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6c's header: back, the person, and where they stand today.
///
/// The avatar wears a ring in today's attendance colour rather than the 13px
/// dot a list row uses, because at 52px the ring is the readable shape and
/// there is only one person on this screen to read.
class StaffProfileHeader extends StatelessWidget {
  const StaffProfileHeader({required this.member, super.key});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: AppSizes.headerBarPad,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          const BackKey(),
          Container(
            width: StaffSizes.profileAvatar,
            height: StaffSizes.profileAvatar,
            padding: const EdgeInsets.all(StaffSizes.avatarRingPad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: member.isActive
                    ? member.attendance.colour(c)
                    : c.cardBorder,
                width: StaffSizes.avatarRing,
              ),
            ),
            child: AppAvatar(
              initials: member.initials,
              size: StaffSizes.profileAvatarInner,
              tone: AvatarTone.staff,
              textStyle: StaffTextStyles.headInitials,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  member.name,
                  style: AppTextStyles.detailTitle.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  StaffStrings.designationScope(
                    member.designation,
                    StaffStrings.attendanceLine(
                      member.attendance,
                      member.attendanceTime,
                    ),
                  ),
                  style: StaffTextStyles.headSub.copyWith(color: c.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusPill(
            label: StaffStrings.statusLabel(member.status),
            tone: switch (member.status) {
              StaffStatus.active => PillTone.success,
              StaffStatus.upcoming => PillTone.staff,
              StaffStatus.inactive => PillTone.neutral,
            },
          ),
        ],
      ),
    );
  }
}
