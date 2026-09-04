import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

/// A hire whose start date has not arrived (6a).
///
/// Drawn on a dashed rim with a grey avatar rather than the sun one, because
/// they are not part of the team yet: the rim says the place is reserved and
/// nothing is in it.
class UpcomingRow extends StatelessWidget {
  const UpcomingRow({required this.member, required this.onTap, super.key});

  final StaffMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: member.name,
      child: Pressable.surface(
        onTap: onTap,
        child: Container(
          padding: AppSizes.rowPad,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: AppRadii.cardR,
            border: Border.all(color: c.dashedLine),
          ),
          child: Row(
            spacing: AppSizes.rowGap,
            children: <Widget>[
              AppAvatar(initials: member.initials, tone: AvatarTone.neutral),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      member.name,
                      style: AppTextStyles.rowName.copyWith(color: c.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      StaffStrings.upcomingSub(
                        member.designation,
                        StaffStrings.scopeOf(member),
                      ),
                      style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: StaffStrings.statusLabel(StaffStatus.upcoming),
                tone: PillTone.staff,
                small: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
