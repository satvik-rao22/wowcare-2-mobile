import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';

/// What a pill says by its colour. Components page `.pill--*`.
enum PillTone {
  /// In Ratio, Signed In, Active, On file.
  success,

  /// Not in Ratio, Absent, overdue.
  danger,

  /// Not Marked, view-only, a neutral tag.
  neutral,

  /// Upcoming, a shift, anything about staff.
  staff,

  /// A student tag, an age group.
  student,

  /// Colours passed in by hand. Rare, and it should stay rare.
  custom;

  Color fill(Colourway c) => switch (this) {
    PillTone.success => c.successBg,
    PillTone.danger => c.dangerBg,
    PillTone.neutral => c.neutralBg,
    PillTone.staff => c.staffBg,
    PillTone.student => c.studentBg,
    PillTone.custom => c.neutralBg,
  };

  Color ink(Colourway c) => switch (this) {
    PillTone.success => c.successFg,
    PillTone.danger => c.dangerFg,
    PillTone.neutral => c.neutralFg,
    PillTone.staff => c.staffFg,
    PillTone.student => c.student,
    PillTone.custom => c.neutralFg,
  };
}

/// A status pill: a tinted capsule with a short label in its tone's ink.
///
/// [small] is the size a row's trailing flag uses (5a "Upcoming").
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.tone = PillTone.neutral,
    this.foreground,
    this.background,
    this.line,
    this.small = false,
    super.key,
  });

  final String label;
  final PillTone tone;

  /// Override the tone's ink. Meant for [PillTone.custom].
  final Color? foreground;

  /// Override the tone's fill. Meant for [PillTone.custom].
  final Color? background;

  /// An optional hairline (4a's ratio pills).
  final Color? line;

  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final style = small ? AppTextStyles.tileLabel : AppTextStyles.pillLabel;

    return Container(
      padding: small ? AppSizes.pillSmallPad : AppSizes.pillPad,
      decoration: AppSurfaces.pill(
        fill: background ?? tone.fill(c),
        line: line,
      ).decoration,
      child: Text(
        label,
        style: style.copyWith(color: foreground ?? tone.ink(c)),
      ),
    );
  }
}
