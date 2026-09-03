import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_cubit.dart';

/// The line under the kiosk's PIN dots.
///
/// Three tones and no more: red refuses a PIN, sun says the entry was
/// cancelled, green is a staff member's receipt. Each is the tint, the
/// hairline and the ink of one of the colourway's own status families, so a
/// notice never invents a colour.
class KioskNotice extends StatelessWidget {
  const KioskNotice({required this.message, required this.tone, super.key});

  final String message;
  final KioskNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: AuthSizes.pinNoticePad,
        decoration: BoxDecoration(
          color: _fill(c),
          borderRadius: AppRadii.innerR,
          border: Border.all(color: _line(c)),
        ),
        child: Row(
          spacing: AppSizes.alertGap,
          children: <Widget>[
            _mark(c),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.alertText.copyWith(color: _ink(c)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mark(Colourway c) => tone == KioskNoticeTone.success
      ? Icon(AppIcons.checkCircle, size: AppSizes.alertBubble, color: _ink(c))
      : Container(
          width: AppSizes.alertBubble,
          height: AppSizes.alertBubble,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _dot(c)),
          child: Text(
            AppStrings.alertMark,
            style: AppTextStyles.alertBubble.copyWith(color: c.onPink),
          ),
        );

  Color _fill(Colourway c) => switch (tone) {
    KioskNoticeTone.danger => c.dangerBg,
    KioskNoticeTone.warn => c.staffBg,
    KioskNoticeTone.success => c.successBg,
  };

  Color _line(Colourway c) => switch (tone) {
    KioskNoticeTone.danger => c.dangerLine,
    KioskNoticeTone.warn => c.staffLine,
    KioskNoticeTone.success => c.successLine,
  };

  Color _ink(Colourway c) => switch (tone) {
    KioskNoticeTone.danger => c.dangerFg,
    KioskNoticeTone.warn => c.staffFg,
    KioskNoticeTone.success => c.successFg,
  };

  Color _dot(Colourway c) => switch (tone) {
    KioskNoticeTone.danger => c.danger,
    KioskNoticeTone.warn => c.staff,
    KioskNoticeTone.success => c.success,
  };
}
