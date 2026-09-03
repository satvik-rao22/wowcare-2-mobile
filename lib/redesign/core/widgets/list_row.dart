import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';

/// A list row. Components page `.row`: leading, a name over a sub-line,
/// trailing, and a chevron when it goes somewhere.
///
/// It is a bare row. Put it in an `AppCard` with zero padding to get the
/// roster card from 5a, or stack several with [showDivider] inside one card.
class ListRow extends StatelessWidget {
  const ListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.showDivider = false,
    this.padding = AppSizes.rowPad,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Defaults to whether there is an [onTap].
  final bool? showChevron;

  /// A hairline under the row, for rows stacked inside one card.
  final bool showDivider;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final chevron = showChevron ?? onTap != null;

    Widget row = Padding(
      padding: padding,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.rowName.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ?trailing,
          if (chevron)
            Icon(
              AppIcons.chevronRight,
              size: AppSizes.rowChevron,
              color: c.ink3,
            ),
        ],
      ),
    );

    if (onTap != null) row = Pressable.surface(onTap: onTap, child: row);

    if (!showDivider) return row;
    return Column(
      children: <Widget>[
        row,
        Container(height: AppSizes.hairline, color: c.divider),
      ],
    );
  }
}
