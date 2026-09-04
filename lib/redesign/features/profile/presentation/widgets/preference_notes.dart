import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_note.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// The two notes under 13e's table: what a greige box means, and what happens
/// when you tick.
class PreferenceNotes extends StatelessWidget {
  const PreferenceNotes({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: ProfileSizes.legendGap,
    children: <Widget>[
      ProfileNote(text: ProfileStrings.notOfferedNote, leading: _LegendBox()),
      ProfileNote.warning(text: ProfileStrings.savesNote),
    ],
  );
}

/// A miniature of the box a channel gets when its group does not offer it.
class _LegendBox extends StatelessWidget {
  const _LegendBox();

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Container(
      width: ProfileSizes.legendBox,
      height: ProfileSizes.legendBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.deepWell,
        borderRadius: BorderRadius.circular(ProfileSizes.legendRadius),
        border: Border.all(color: c.cardBorder),
      ),
      child: Text(
        ProfileStrings.notOfferedMark,
        style: ProfileTextStyles.notOfferedMark.copyWith(color: c.ink3),
      ),
    );
  }
}
