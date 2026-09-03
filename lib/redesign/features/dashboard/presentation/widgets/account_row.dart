import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// One row on the Account page (3M2).
///
/// Most rows open something and wear a chevron; the Sign-In PIN row is a fact
/// and wears its four digits instead, which is why the trailing slot is a
/// widget rather than a flag.
class AccountRow extends StatelessWidget {
  const AccountRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// A pill, a value, or nothing. A row with an [onTap] and no trailing gets
  /// the chevron.
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final row = SurfaceBox(
      surface: AppSurfaces.card(c),
      padding: DashboardSizes.accountRowPad,
      child: Row(
        spacing: DashboardSizes.accountRowGap,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: DashboardTextStyles.accountRowTitle.copyWith(
                    color: c.ink,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: DashboardTextStyles.accountRowSub.copyWith(
                      color: c.ink3,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(
              AppIcons.chevronRight,
              size: DashboardSizes.accountRowChevron,
              color: c.ink3,
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: title,
      child: Pressable.surface(onTap: onTap, child: row),
    );
  }
}
