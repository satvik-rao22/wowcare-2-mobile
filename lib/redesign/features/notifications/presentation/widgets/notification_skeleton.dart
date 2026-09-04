import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/features/notifications/notifications_sizes.dart';
import 'package:wowcare/redesign/features/notifications/notifications_strings.dart';

/// 12b's first load: three rows of the shape the rows will be, so the page
/// keeps its height and nothing jumps when the answer lands.
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: NotificationsSizes.listGap,
    children: <Widget>[
      for (var i = 0; i < NotificationsSizes.skeletonRows; i++)
        const _SkeletonRow(),
      Text(
        NotificationsStrings.loadingFeed,
        textAlign: TextAlign.center,
        style: AppTextStyles.subLine.copyWith(color: context.colours.ink3),
      ),
    ],
  );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: NotificationsSizes.rowPad,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: NotificationsSizes.rowGap,
        children: <Widget>[
          Container(
            width: NotificationsSizes.avatar,
            height: NotificationsSizes.avatar,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.well),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: NotificationsSizes.skeletonGap,
              children: <Widget>[
                _Bar(width: 0, height: NotificationsSizes.skeletonTitle),
                _Bar(width: 1, height: NotificationsSizes.skeletonLine),
                _Bar(width: 2, height: NotificationsSizes.skeletonLine),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One bar, [width] indexing the three widths the frame draws.
class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final int width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: NotificationsSizes.skeletonWidths[width],
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: width == 0 ? c.well : c.altWell,
          borderRadius: BorderRadius.circular(
            NotificationsSizes.skeletonBarRadius,
          ),
        ),
      ),
    );
  }
}
