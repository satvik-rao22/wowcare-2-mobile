import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_action_row.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// The three rows at the foot of 13a and 13c: the Sign-In PIN, notification
/// settings, and changing the password.
///
/// Logout and Switch Profile are not here. Both are account actions and both
/// live on the Account page with the sheets that confirm them; this screen is
/// the record, not the account.
class ProfileActionsCard extends StatelessWidget {
  const ProfileActionsCard({
    required this.pinLabel,
    required this.isPinVisible,
    required this.canHidePin,
    required this.onTogglePin,
    required this.onNotificationSettings,
    required this.onChangePassword,
    super.key,
  });

  /// The digits, or the mask.
  final String pinLabel;

  final bool isPinVisible;

  /// A guardian's PIN is simply shown: it is theirs to type on the kiosk and
  /// the app never asks them for it.
  final bool canHidePin;

  final VoidCallback onTogglePin;
  final VoidCallback onNotificationSettings;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: EdgeInsets.zero,
      clipContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProfileActionRow(
            icon: AppIcons.key,
            label: ProfileStrings.signInPin,
            // The Show key is the target, not the row: a whole row that
            // reveals a PIN is too easy to press by accident.
            showChevron: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: ProfileSizes.actionRowGap,
              children: <Widget>[
                Text(
                  pinLabel,
                  style: ProfileTextStyles.pinValue.copyWith(color: c.ink),
                ),
                if (canHidePin)
                  Pressable.surface(
                    onTap: onTogglePin,
                    child: SurfaceBox(
                      surface: AppSurfaces.pill(fill: c.neutralBg),
                      padding: ProfileSizes.pinKeyPad,
                      child: Text(
                        isPinVisible
                            ? ProfileStrings.hide
                            : ProfileStrings.show,
                        style: ProfileTextStyles.pinChip.copyWith(
                          color: c.ink2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ProfileActionRow(
            icon: AppIcons.bell,
            label: ProfileStrings.notificationSettings,
            onTap: onNotificationSettings,
          ),
          ProfileActionRow(
            icon: AppIcons.lock,
            label: ProfileStrings.changePassword,
            onTap: onChangePassword,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
