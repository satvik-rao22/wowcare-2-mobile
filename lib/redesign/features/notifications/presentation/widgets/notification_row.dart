import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/notifications_formats.dart';
import 'package:wowcare/redesign/features/notifications/notifications_sizes.dart';
import 'package:wowcare/redesign/features/notifications/notifications_strings.dart';
import 'package:wowcare/redesign/features/notifications/notifications_text_styles.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/notification_tone_colors.dart';

/// One row of 12a: a bubble in the module's tint, the line that arrived, how
/// old it is, what it was about, and a pink dot while it is unread.
///
/// Read and unread are the same row in two materials. Unread is a card: it
/// sits up off the tray with the bevel and the shadow every card has. Read
/// drops to the quiet inner ground, loses the shadow and the dot, and its
/// bubble goes grey. Nothing moves, so a list that is half read still reads
/// as one list.
class NotificationRow extends StatelessWidget {
  const NotificationRow({
    required this.item,
    required this.now,
    this.onTap,
    super.key,
  });

  final NotificationItem item;

  /// The school's clock, so every row on the screen ages together.
  final DateTime now;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final tone = item.module.tone;

    return Semantics(
      button: onTap != null,
      label: item.isRead
          ? item.title
          : '${NotificationsStrings.unreadRow}. ${item.title}',
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: item.isRead
              ? AppSurfaces.subtle(c, radius: AppRadii.card)
              : AppSurfaces.card(c),
          padding: NotificationsSizes.rowPad,
          // The bubble sits at the top of the row and the chevron in the
          // middle of it, which needs the row's height before it is laid out.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: NotificationsSizes.rowGap,
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[_bubble(c, tone)],
                ),
                Expanded(child: _lines(c, tone)),
                _trailing(c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(Colourway c, NotificationTone tone) => SurfaceBox(
    surface: AppSurfaces.avatar(
      c,
      fill: item.isRead ? c.well : tone.fill(c),
      size: NotificationsSizes.avatar,
    ),
    width: NotificationsSizes.avatar,
    height: NotificationsSizes.avatar,
    alignment: Alignment.center,
    child: Text(
      item.initials,
      style: AppTextStyles.avatarInitials.copyWith(
        color: item.isRead ? c.ink3 : tone.ink(c),
      ),
    ),
  );

  Widget _lines(Colourway c, NotificationTone tone) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: NotificationsSizes.rowTextGap,
    children: <Widget>[
      Text(
        item.title,
        style: item.isRead
            ? NotificationsTextStyles.rowTitleRead.copyWith(color: c.ink2)
            : NotificationsTextStyles.rowTitle.copyWith(color: c.ink),
      ),
      if (item.body.isNotEmpty)
        Text(
          item.body,
          style: NotificationsTextStyles.rowBody.copyWith(color: c.ink2),
        ),
      Row(
        spacing: NotificationsSizes.metaGap,
        children: <Widget>[
          Text(
            NotificationsFormats.relativeTime(item.createdAt, now),
            style: NotificationsTextStyles.rowTime.copyWith(color: c.ink3),
          ),
          Flexible(
            child: StatusPill(
              label: item.module.label,
              tone: PillTone.custom,
              background: tone.fill(c),
              foreground: tone.ink(c),
              small: true,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _trailing(Colourway c) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: NotificationsSizes.trailingGap,
    children: <Widget>[
      Icon(
        AppIcons.chevronRight,
        size: NotificationsSizes.chevron,
        color: c.ink3,
      ),
      if (!item.isRead)
        Container(
          width: NotificationsSizes.unreadDot,
          height: NotificationsSizes.unreadDot,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.pink),
        ),
    ],
  );
}
