import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// A read-only field: a label, an optional tag beside it, and the value in a
/// well. 13a's detail card, and 13b's two locked wells.
///
/// [isLocked] draws the deeper well and the muted ink the frames give a value
/// that cannot be changed, with the "Cannot be edited" tag over it. An empty
/// [value] falls back to the em dash 13f's failed state shows.
class ValueField extends StatelessWidget {
  const ValueField({
    required this.label,
    required this.value,
    this.isLocked = false,
    this.showLockTag = false,
    this.helpText,
    super.key,
  });

  final String label;
  final String value;

  /// The deeper well and the muted ink of a value the app will not change.
  final bool isLocked;

  /// The "Cannot be edited" tag beside the label.
  final bool showLockTag;

  /// A line under the well, in ink3.
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isMissing = value.isEmpty;
    final ink = isLocked || isMissing ? c.ink3 : c.ink;
    final well = AppSurfaces.well(c, radius: ProfileSizes.valueRadius);
    // A locked value keeps the well's recess and drops to the deep fill,
    // which is the one difference the frames draw between the two.
    final surface = isLocked
        ? well.copyWith(decoration: well.decoration.copyWith(color: c.deepWell))
        : well;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ProfileSizes.labelGap,
      children: <Widget>[
        Row(
          spacing: ProfileSizes.labelTagGap,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.fieldLabel.copyWith(color: c.ink2),
              ),
            ),
            if (showLockTag)
              SurfaceBox(
                surface: AppSurfaces.pill(fill: c.neutralBg),
                padding: ProfileSizes.tagPad,
                child: Text(
                  ProfileStrings.cannotBeEdited,
                  style: ProfileTextStyles.tinyTag.copyWith(color: c.ink2),
                ),
              ),
          ],
        ),
        SurfaceBox(
          surface: surface,
          padding: ProfileSizes.valueWellPad,
          width: double.infinity,
          child: Text(
            isMissing ? ProfileStrings.missingValue : value,
            style: ProfileTextStyles.valueText.copyWith(color: ink),
          ),
        ),
        if (helpText != null)
          Text(
            helpText!,
            style: AppTextStyles.fieldHelp.copyWith(color: c.ink3),
          ),
      ],
    );
  }
}
