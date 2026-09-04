import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_toggle.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/features/notifications/notifications_sizes.dart';
import 'package:wowcare/redesign/features/notifications/notifications_strings.dart';

/// 12a's row under the chips: the one action on this screen, and the switch
/// that hides what has already been read.
///
/// Mark all as read is the screen's pink key, and it is the only pink here.
/// With nothing unread it takes the disabled recipe rather than the frame's
/// dimmed pink: a key that cannot be pressed looks like a key that cannot be
/// pressed everywhere else in this app.
class NotificationToolbar extends StatelessWidget {
  const NotificationToolbar({
    required this.canMarkAll,
    required this.onlyUnread,
    required this.onMarkAll,
    required this.onToggleUnread,
    super.key,
  });

  final bool canMarkAll;
  final bool onlyUnread;
  final VoidCallback onMarkAll;
  final ValueChanged<bool> onToggleUnread;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: NotificationsSizes.toolbarPad,
      child: Row(
        spacing: NotificationsSizes.toolbarGap,
        children: <Widget>[
          PrimaryKey(
            label: NotificationsStrings.markAllRead,
            onTap: onMarkAll,
            enabled: canMarkAll,
            expand: false,
            padding: NotificationsSizes.markKeyPad,
          ),
          // The label is part of the target: a 27px switch on its own is
          // under the 44px minimum. It takes what the key leaves, so a long
          // label gives way rather than pushing the switch off the screen.
          Expanded(
            child: Pressable.surface(
              onTap: () => onToggleUnread(!onlyUnread),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: NotificationsSizes.switchGap,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      NotificationsStrings.onlyShowUnread,
                      style: AppTextStyles.subLine.copyWith(color: c.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppToggle(
                    value: onlyUnread,
                    onChanged: (value) => onToggleUnread(value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
