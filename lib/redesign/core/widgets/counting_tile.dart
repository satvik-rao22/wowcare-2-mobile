import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Whose figure a counting tile carries. Components page `.tile`.
enum TileTone {
  student,
  staff,

  /// A card face with ink number and ink3 label (5a "Starting soon").
  neutral,
  danger,
  success;

  Surface surface(Colourway c) => switch (this) {
    TileTone.student => AppSurfaces.tile(
      c,
      fill: c.studentBg,
      line: c.studentLine,
    ),
    TileTone.staff => AppSurfaces.tile(c, fill: c.staffBg, line: c.staffLine),
    TileTone.neutral => AppSurfaces.tileNeutral(c),
    TileTone.danger => AppSurfaces.tile(
      c,
      fill: c.dangerBg,
      line: c.dangerLine,
    ),
    TileTone.success => AppSurfaces.tile(
      c,
      fill: c.successBg,
      line: c.successLine,
    ),
  };

  Color number(Colourway c) => switch (this) {
    TileTone.student => c.student,
    TileTone.staff => c.staffFg,
    TileTone.neutral => c.ink,
    TileTone.danger => c.dangerFg,
    TileTone.success => c.successFg,
  };

  Color label(Colourway c) => switch (this) {
    TileTone.neutral => c.ink3,
    _ => number(c),
  };
}

/// A figure with its caption, in a domain tint. The domain figure leads.
///
/// It fills whatever width it is given; a row of tiles wraps each in
/// `Expanded`.
class CountingTile extends StatelessWidget {
  const CountingTile({
    required this.value,
    required this.label,
    this.tone = TileTone.neutral,
    super.key,
  });

  final String value;
  final String label;
  final TileTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: tone.surface(c),
      padding: AppSizes.tilePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSizes.tileTextGap,
        children: <Widget>[
          Text(
            value,
            style: AppTextStyles.tileNumber.copyWith(color: tone.number(c)),
          ),
          Text(
            label,
            style: AppTextStyles.tileLabel.copyWith(color: tone.label(c)),
          ),
        ],
      ),
    );
  }
}
