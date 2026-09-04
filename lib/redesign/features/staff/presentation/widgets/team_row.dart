import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// A colleague, as a staff member sees them (6e): the name, where they are,
/// and a key that calls them.
///
/// No attendance dot and no chevron. Whether a colleague is on the clock is
/// not a teacher's business, and there is no record behind the row to open.
class TeamRow extends StatelessWidget {
  const TeamRow({required this.member, required this.onCall, super.key});

  final StaffMember member;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: StaffSizes.teamRowPad,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          AppAvatar(initials: member.initials, tone: AvatarTone.staff),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  member.name,
                  style: StaffTextStyles.teamName.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  StaffStrings.memberSubline(member),
                  style: StaffTextStyles.teamSub.copyWith(color: c.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: StaffStrings.callName(member.firstName),
            child: Pressable.surface(
              onTap: onCall,
              child: SurfaceBox(
                surface: AppSurfaces.subtle(c),
                padding: StaffSizes.callKeyPad,
                child: Icon(
                  AppIcons.phone,
                  size: AppSizes.rowChevron,
                  color: c.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
