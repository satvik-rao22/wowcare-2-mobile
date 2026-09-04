import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// What an action row's little tile says about it. Pink is deliberately not
/// here: the sheet's one pink thing is the key at the bottom.
enum ActionTone { neutral, success, student, danger }

/// One door out of the actions sheet (5a): a monogram tile, a label and the
/// line that says what happens next.
///
/// Null [onTap] draws the row inert rather than hiding it, because "you
/// cannot message this family" is the answer, and hiding the row would leave
/// the question.
class StudentActionRow extends StatelessWidget {
  const StudentActionRow({
    required this.glyph,
    required this.label,
    required this.note,
    this.tone = ActionTone.neutral,
    this.onTap,
    super.key,
  });

  /// The two or three letters the design puts in the tile.
  final String glyph;

  final String label;
  final String note;
  final ActionTone tone;
  final VoidCallback? onTap;

  Color _tileFill(Colourway c) => switch (tone) {
    ActionTone.neutral => c.altWell,
    ActionTone.success => c.successBg,
    ActionTone.student => c.studentBg,
    ActionTone.danger => c.dangerBg,
  };

  Color _tileInk(Colourway c) => switch (tone) {
    ActionTone.neutral => c.ink2,
    ActionTone.success => c.successFg,
    ActionTone.student => c.student,
    ActionTone.danger => c.dangerFg,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isEnabled = onTap != null;
    final labelInk = tone == ActionTone.danger ? c.dangerFg : c.ink;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: Opacity(
          opacity: isEnabled ? 1 : StudentsSizes.dayOffOpacity,
          child: SurfaceBox(
            surface: AppSurfaces.keySecondary(c),
            padding: StudentsSizes.actionRowPad,
            child: Row(
              spacing: AppSizes.rowGap,
              children: <Widget>[
                SurfaceBox(
                  surface: AppSurfaces.glyphTile(
                    c,
                    fill: _tileFill(c),
                    radius: AppRadii.chip,
                  ),
                  width: StudentsSizes.actionGlyphTile,
                  height: StudentsSizes.actionGlyphTile,
                  alignment: Alignment.center,
                  child: Text(
                    glyph,
                    style: StudentsTextStyles.actionGlyph.copyWith(
                      color: _tileInk(c),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: StudentsTextStyles.actionLabel.copyWith(
                          color: labelInk,
                        ),
                      ),
                      Text(
                        note,
                        style: StudentsTextStyles.footnote.copyWith(
                          color: c.ink3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
