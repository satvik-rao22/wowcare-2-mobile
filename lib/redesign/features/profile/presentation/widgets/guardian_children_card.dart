import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_child_row.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// 13c's "Your children": the students this guardian is on the record for,
/// with today's attendance and the way into each record.
class GuardianChildrenCard extends StatelessWidget {
  const GuardianChildrenCard({
    required this.children,
    required this.onOpen,
    super.key,
  });

  final List<ProfileChild> children;
  final void Function(ProfileChild child) onOpen;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: ProfileSizes.detailCardPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ProfileSizes.scheduleGap,
      children: <Widget>[
        Text(
          ProfileStrings.yourChildren,
          style: ProfileTextStyles.cardHeading.copyWith(
            color: context.colours.ink,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ProfileSizes.childListGap,
          children: <Widget>[
            for (final child in children)
              ProfileChildRow(child: child, onOpen: () => onOpen(child)),
          ],
        ),
      ],
    ),
  );
}
