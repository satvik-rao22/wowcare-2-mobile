import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/redesign/core/constants/app_assets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';

/// 1a's hero: the mark, the greeting, and the line under it.
class AuthHero extends StatelessWidget {
  const AuthHero({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      spacing: AuthSizes.heroGap,
      children: <Widget>[
        SvgPicture.asset(
          AppAssets.logoMark,
          width: AuthSizes.heroLogo,
          height: AuthSizes.heroLogo,
        ),
        Text(title, style: AppTextStyles.moduleTitle.copyWith(color: c.ink)),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: c.ink2),
        ),
      ],
    );
  }
}
