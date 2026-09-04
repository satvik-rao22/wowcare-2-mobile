import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// One row of the actions card: a glyph, a label, whatever the row carries on
/// the right, and a chevron when it opens something.
class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.showDivider = true,
    super.key,
  });

  final IconData icon;
  final String label;

  /// A value or a small key: the PIN and its Show key.
  final Widget? trailing;

  final VoidCallback? onTap;

  /// Defaults to whether there is an [onTap]. The PIN row taps to reveal
  /// rather than to go somewhere, so it says no.
  final bool? showChevron;

  /// A hairline under the row. The last row in a card does without.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    Widget row = Padding(
      padding: ProfileSizes.actionRowPad,
      child: Row(
        spacing: ProfileSizes.actionRowGap,
        children: <Widget>[
          Icon(icon, size: ProfileSizes.actionGlyph, color: c.ink),
          Expanded(
            child: Text(
              label,
              style: ProfileTextStyles.actionRow.copyWith(color: c.ink),
            ),
          ),
          ?trailing,
          if (showChevron ?? onTap != null)
            Icon(
              AppIcons.chevronRight,
              size: ProfileSizes.actionChevron,
              color: c.ink3,
            ),
        ],
      ),
    );

    if (showDivider) {
      row = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: row,
      );
    }

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(onTap: onTap, child: row),
    );
  }
}
