import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';

/// Why the screen is not showing what it usually shows.
enum BannerTone {
  /// Read-only, or a scope you did not choose. Quiet.
  neutral,

  /// No signal, so this is what the phone had. Sun, not red: nothing is
  /// broken.
  caution,
}

/// The strip above the header on 5g: a dot, then one sentence.
///
/// Core's `OfflineBanner` is the navy strip a signed-out screen wears. This
/// one sits inside a working screen and has to stay quieter than the roster
/// under it.
class StudentsBanner extends StatelessWidget {
  const StudentsBanner({
    required this.message,
    this.tone = BannerTone.neutral,
    super.key,
  });

  final String message;
  final BannerTone tone;

  Color _fill(Colourway c) =>
      tone == BannerTone.caution ? c.staffBg : c.altWell;

  Color _line(Colourway c) =>
      tone == BannerTone.caution ? c.staffLine : c.cardBorder;

  Color _ink(Colourway c) => tone == BannerTone.caution ? c.staffFg : c.ink2;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = _ink(c);

    return Semantics(
      liveRegion: true,
      child: SurfaceBox(
        surface: AppSurfaces.tile(c, fill: _fill(c), line: _line(c)),
        padding: StudentsSizes.bannerPad,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: StudentsSizes.bannerGap,
          children: <Widget>[
            Container(
              width: StudentsSizes.bannerDot,
              height: StudentsSizes.bannerDot,
              decoration: AppSurfaces.pill(fill: ink).decoration,
            ),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.noteText.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
