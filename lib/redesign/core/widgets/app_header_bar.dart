import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// The header bar. Components page `.appbar`, on the tray rather than a bar
/// of its own, which is how every frame draws it.
///
/// Two shapes. The default is a title header: an optional [leading] key (a
/// `BackKey` on a drill-down), the title in `moduleTitle`, or `detailTitle`
/// when [isDetail], and trailing [actions]. [AppHeaderBar.dashboard] is the
/// greeting header from 3A1: a leading key, a `detailTitle` line with a
/// `subLine` under it, and trailing keys.
class AppHeaderBar extends StatelessWidget {
  const AppHeaderBar({
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.isDetail = false,
    super.key,
  }) : subline = null;

  const AppHeaderBar.dashboard({
    required this.title,
    required this.subline,
    this.leading,
    this.actions = const <Widget>[],
    super.key,
  }) : isDetail = true;

  final String title;

  /// The line under the title. Only the dashboard variant has one.
  final String? subline;

  final Widget? leading;
  final List<Widget> actions;

  /// A one-record screen, a form, a wizard: `detailTitle` rather than
  /// `moduleTitle`. Screen role decides this, never navigation depth.
  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isDashboard = subline != null;
    final titleStyle = isDetail
        ? AppTextStyles.detailTitle
        : AppTextStyles.moduleTitle;

    return Padding(
      padding: AppSizes.headerBarPad,
      child: Row(
        spacing: isDashboard ? AppSizes.headerDashboardGap : AppSizes.headerGap,
        children: <Widget>[
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.hairline,
              children: <Widget>[
                Text(
                  title,
                  style: titleStyle.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDashboard)
                  Text(
                    subline!,
                    style: AppTextStyles.subLine.copyWith(color: c.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
