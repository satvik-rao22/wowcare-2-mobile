import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/redesign/core/constants/app_assets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';

/// The kiosk's own chrome: the mark, the app's name, a hairline under it.
///
/// The door screen (2b) writes the name in ink and hangs an action off the
/// end; the screens behind it (2d, 2e) write it in pink and carry nothing
/// else, because in kiosk lockdown there is nowhere to go.
class KioskTopBar extends StatelessWidget {
  const KioskTopBar({this.action, super.key})
    : _isBrand = false,
      _logo = AuthSizes.kioskLogo;

  const KioskTopBar.brand({super.key})
    : action = null,
      _isBrand = true,
      _logo = AuthSizes.brandLogo;

  /// A key at the end of the bar. The door's menu, and nothing else.
  final Widget? action;

  final bool _isBrand;
  final double _logo;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: AuthSizes.kioskHeaderPad,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.barLine),
        ),
      ),
      child: Row(
        spacing: AuthSizes.kioskHeaderGap,
        children: <Widget>[
          SvgPicture.asset(AppAssets.logoMark, width: _logo, height: _logo),
          Expanded(
            child: Text(
              AppStrings.appName,
              style: _isBrand
                  ? AppTextStyles.detailTitle.copyWith(color: c.pink)
                  : AppTextStyles.moduleTitle.copyWith(color: c.ink),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
