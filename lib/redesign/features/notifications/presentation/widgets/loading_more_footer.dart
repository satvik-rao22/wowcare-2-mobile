import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/loading_ring.dart';
import 'package:wowcare/redesign/features/notifications/notifications_sizes.dart';
import 'package:wowcare/redesign/features/notifications/notifications_strings.dart';
import 'package:wowcare/redesign/features/notifications/notifications_text_styles.dart';

/// The foot of the list while the next ten are on their way.
///
/// The shipped center pages as you scroll and says so nowhere, which is the
/// module's one free finding: the fetch was already happening, and this is
/// the line that admits it.
class LoadingMoreFooter extends StatelessWidget {
  const LoadingMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: NotificationsSizes.footerPad,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: NotificationsSizes.footerGap,
        children: <Widget>[
          const LoadingRing(),
          Text(
            NotificationsStrings.loadingMore,
            style: NotificationsTextStyles.footerLabel.copyWith(color: c.ink3),
          ),
        ],
      ),
    );
  }
}
