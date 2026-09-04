import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';

/// A quiet explanation set into the page: 13c's "a guardian holds one role
/// here", 13f's offline note, the version line, and 13e's two legend notes.
///
/// [leading] is drawn beside the text: a dot by default, or the greige box
/// the preference legend uses. [ProfileNote.warning] is the sun-tinted one
/// 13e gives the note about saving.
class ProfileNote extends StatelessWidget {
  const ProfileNote({required this.text, this.leading, super.key})
    : isWarning = false;

  const ProfileNote.warning({required this.text, this.leading, super.key})
    : isWarning = true;

  final String text;
  final Widget? leading;

  /// Sun rather than the neutral alt-well.
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = isWarning ? c.staffFg : c.ink2;

    return SurfaceBox(
      surface: isWarning
          ? Surface(
              borderRadius: AppRadii.innerR,
              decoration: BoxDecoration(
                color: c.staffBg,
                borderRadius: AppRadii.innerR,
              ),
            )
          : AppSurfaces.altWell(c),
      padding: ProfileSizes.notePad,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ProfileSizes.noteGap,
        children: <Widget>[
          leading ?? _Dot(color: isWarning ? c.staff : c.ink2),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.noteText.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small round mark that leads a note, sat on the text's first line.
class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: ProfileSizes.noteDot,
    height: ProfileSizes.noteDot,
    margin: const EdgeInsets.only(top: ProfileSizes.noteDot),
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
