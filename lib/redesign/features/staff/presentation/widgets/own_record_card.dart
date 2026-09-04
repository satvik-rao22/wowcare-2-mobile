import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/impact_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6e's navy card: the viewer's own record, which is the one record they can
/// read whole.
///
/// The impact surface is the screen's single most important fact. On a screen
/// where a staff member can change almost nothing, the thing they can change
/// is their own record, so it earns the navy.
class OwnRecordCard extends StatelessWidget {
  const OwnRecordCard({required this.member, required this.onOpen, super.key});

  final StaffMember member;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return ImpactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StaffSizes.sheetSectionGap,
        children: <Widget>[
          Row(
            spacing: StaffSizes.sheetSectionGap,
            children: <Widget>[
              AppAvatar(
                initials: member.initials,
                size: StaffSizes.ownAvatar,
                tone: AvatarTone.impact,
                attendance: member.attendance,
                ringColor: c.impact,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      StaffStrings.yourRecord,
                      style: StaffTextStyles.ownTitle.copyWith(
                        color: c.onImpact,
                      ),
                    ),
                    Text(
                      StaffStrings.ownRecordSub(
                        member.designation,
                        StaffStrings.scopeOf(member),
                        member.signInPin,
                      ),
                      style: StaffTextStyles.ownSub.copyWith(
                        color: c.onImpactSub,
                      ),
                    ),
                  ],
                ),
              ),
              _OpenKey(onTap: onOpen),
            ],
          ),
          Text(
            StaffStrings.ownRecordNote,
            style: StaffTextStyles.ownNote.copyWith(color: c.onImpactSoft),
          ),
        ],
      ),
    );
  }
}

/// The quiet key on the navy card. It is a tint of the warm white rather than
/// a pink key: pink is the one action on a screen, and here that is nothing.
class _OpenKey extends StatelessWidget {
  const _OpenKey({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: StaffStrings.open,
      child: Pressable.surface(
        onTap: onTap,
        child: Container(
          padding: StaffSizes.openKeyPad,
          decoration: BoxDecoration(
            color: c.impactBevel,
            borderRadius: AppRadii.innerR,
          ),
          child: Text(
            StaffStrings.open,
            style: StaffTextStyles.ownKey.copyWith(color: c.onImpact),
          ),
        ),
      ),
    );
  }
}
