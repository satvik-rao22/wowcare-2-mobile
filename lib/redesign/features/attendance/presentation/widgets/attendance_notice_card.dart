import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// Whether the card is reassuring or warning.
enum NoticeTone { success, danger }

/// A card that reports the state of the day rather than a person (4e).
///
/// Two of them are drawn: "Nobody absent today", which is a reassurance with
/// a tick beside it, and "Today could not load", which is offline with the
/// two ways out under it.
class AttendanceNoticeCard extends StatelessWidget {
  const AttendanceNoticeCard({
    required this.eyebrow,
    required this.body,
    this.tone = NoticeTone.danger,
    this.icon,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.footnote,
    super.key,
  });

  final String eyebrow;
  final String body;
  final NoticeTone tone;

  /// A tinted tile before the body. Null draws the body on its own.
  final IconData? icon;

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final accent = tone == NoticeTone.success ? c.successFg : c.dangerFg;

    return AppCard(
      padding: AttendanceSizes.edgeCardPad,
      lineColor: tone == NoticeTone.danger ? c.dangerLine : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AttendanceSizes.edgeCardGap,
        children: <Widget>[
          SectionEyebrow(label: eyebrow, color: accent),
          _body(c),
          if (primaryLabel != null || secondaryLabel != null) _keys(),
          if (footnote != null)
            Text(
              footnote!,
              style: AttendanceTextStyles.footnote.copyWith(color: c.ink3),
            ),
        ],
      ),
    );
  }

  Widget _body(Colourway c) {
    final text = Text(
      body,
      style: AttendanceTextStyles.edgeBody.copyWith(color: c.ink2),
    );
    final glyph = icon;
    if (glyph == null) return text;

    return Row(
      spacing: AttendanceSizes.sheetHeaderGap,
      children: <Widget>[
        SurfaceBox(
          surface: AppSurfaces.glyphTile(
            c,
            fill: tone == NoticeTone.success ? c.successBg : c.dangerBg,
            radius: AppRadii.inner,
          ),
          width: AttendanceSizes.edgeTile,
          height: AttendanceSizes.edgeTile,
          alignment: Alignment.center,
          child: Icon(
            glyph,
            size: AttendanceSizes.edgeTileGlyph,
            color: tone == NoticeTone.success ? c.successFg : c.dangerFg,
          ),
        ),
        Expanded(child: text),
      ],
    );
  }

  Widget _keys() => Row(
    spacing: AttendanceSizes.edgeKeyGap,
    children: <Widget>[
      if (primaryLabel != null)
        Expanded(
          child: PrimaryKey(label: primaryLabel!, onTap: onPrimary),
        ),
      if (secondaryLabel != null)
        Expanded(
          child: SecondaryKey(label: secondaryLabel!, onTap: onSecondary),
        ),
    ],
  );
}
