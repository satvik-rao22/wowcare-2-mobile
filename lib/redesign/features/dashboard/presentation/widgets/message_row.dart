import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// The one conversation a dashboard surfaces (3A1, 3S1).
///
/// One row, not a list: the dashboard points at Messages rather than trying
/// to be it, so tapping goes to the conversation and nowhere else.
class MessageRow extends StatelessWidget {
  const MessageRow({
    required this.message,
    required this.onTap,
    this.isCard = false,
    super.key,
  });

  final MessagePreview message;
  final VoidCallback onTap;

  /// On a Staff dashboard the row is a card of its own; on an Admin's it sits
  /// inside My day as a well.
  final bool isCard;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: message.name,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isCard ? AppSurfaces.card(c) : AppSurfaces.well(c),
          padding: DashboardSizes.messageRowPad,
          child: Row(
            spacing: DashboardSizes.messageRowGap,
            children: <Widget>[
              AppAvatar(
                initials: message.initials,
                size: DashboardSizes.messageAvatar,
                tone: message.isFromStaff
                    ? AvatarTone.staff
                    : AvatarTone.student,
                textStyle: DashboardTextStyles.chipAvatarText,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      message.name,
                      style: DashboardTextStyles.messageName.copyWith(
                        color: c.ink,
                      ),
                    ),
                    Text(
                      message.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DashboardTextStyles.messagePreview.copyWith(
                        color: c.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              if (message.unreadCount > 0)
                Container(
                  constraints: const BoxConstraints(
                    minWidth: DashboardSizes.messageBadge,
                  ),
                  height: DashboardSizes.messageBadge,
                  padding: DashboardSizes.messageBadgePad,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.pink,
                    borderRadius: AppRadii.pillR,
                  ),
                  child: Text(
                    '${message.unreadCount}',
                    style: DashboardTextStyles.messageBadge.copyWith(
                      color: c.onPink,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
