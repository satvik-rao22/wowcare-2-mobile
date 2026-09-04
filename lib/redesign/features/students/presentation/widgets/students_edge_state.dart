import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// Which of 5g's four states this is, which is the only thing that decides
/// the tile's colour.
enum EdgeTone {
  /// Nothing matched, or nothing is shared with you: quiet.
  quiet,

  /// Nothing here yet, and adding the first one is the invitation.
  invite,

  /// No signal. Sun, not red.
  caution,
}

/// The whole body of 5g: a big tinted glyph, a title, a paragraph, one pink
/// key at most, and a quiet second line under it.
///
/// Core's `EmptyState` is the card-sized version of this. A roster with
/// nothing on it is a screen rather than a card, which is why this one is
/// bigger and carries a second action.
class StudentsEdgeState extends StatelessWidget {
  const StudentsEdgeState({
    required this.glyph,
    required this.title,
    required this.body,
    this.tone = EdgeTone.quiet,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An action needs both a label and a handler.',
       );

  /// The one character the design puts in the tile: 0, +, an em dash, a bang.
  final String glyph;

  final String title;
  final String body;
  final EdgeTone tone;

  final String? actionLabel;
  final VoidCallback? onAction;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  Color _fill(Colourway c) => switch (tone) {
    EdgeTone.quiet => c.well,
    EdgeTone.invite => c.studentBg,
    EdgeTone.caution => c.staffBg,
  };

  Color _ink(Colourway c) => switch (tone) {
    EdgeTone.quiet => c.ink3,
    EdgeTone.invite => c.student,
    EdgeTone.caution => c.staffFg,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Center(
      child: Padding(
        padding: StudentsSizes.edgePad,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: StudentsSizes.edgeGap,
          children: <Widget>[
            SurfaceBox(
              surface: AppSurfaces.glyphTile(
                c,
                fill: _fill(c),
                radius: StudentsSizes.edgeIconRadius,
              ),
              width: StudentsSizes.edgeIcon,
              height: StudentsSizes.edgeIcon,
              alignment: Alignment.center,
              child: Text(
                glyph,
                style: StudentsTextStyles.edgeGlyph.copyWith(color: _ink(c)),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: StudentsSizes.edgeTextGap,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.detailTitle.copyWith(color: c.ink),
                ),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: StudentsTextStyles.edgeBody.copyWith(color: c.ink2),
                ),
              ],
            ),
            if (actionLabel != null)
              PrimaryKey(
                label: actionLabel!,
                onTap: onAction,
                expand: false,
                padding: StudentsSizes.edgeKeyPad,
              ),
            if (secondaryLabel != null)
              Semantics(
                button: true,
                label: secondaryLabel,
                child: Pressable.surface(
                  onTap: onSecondary,
                  child: Text(
                    secondaryLabel!,
                    textAlign: TextAlign.center,
                    style: StudentsTextStyles.secondaryAction.copyWith(
                      color: c.ink2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
