import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// 13f's failed state. Not an empty screen: it says what is still true, which
/// is that the name, email and role were kept from sign-in and only the
/// fuller record is missing.
class ProfileFailedCard extends StatelessWidget {
  const ProfileFailedCard({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      lineColor: c.dangerLine,
      padding: ProfileSizes.failedCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ProfileSizes.failedGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.glyphTile(
              c,
              fill: c.dangerBg,
              radius: AppRadii.card,
            ),
            width: ProfileSizes.failedIcon,
            height: ProfileSizes.failedIcon,
            alignment: Alignment.center,
            child: Icon(
              AppIcons.alertCircle,
              size: ProfileSizes.failedGlyph,
              color: c.danger,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ProfileSizes.failedTextGap,
            children: <Widget>[
              Text(
                ProfileStrings.loadFailedTitle,
                style: ProfileTextStyles.failedTitle.copyWith(color: c.ink),
              ),
              Text(
                ProfileStrings.loadFailedBody,
                style: ProfileTextStyles.failedBody.copyWith(color: c.ink2),
              ),
            ],
          ),
          PrimaryKey(
            label: AppStrings.retry,
            expand: false,
            padding: ProfileSizes.retryKeyPad,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
