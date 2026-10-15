import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_media_res.dart';
import 'ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';
import 'package:wowcare/core/theme/app_icon.dart';

class SelectedStudentTile extends StatelessWidget {
  const SelectedStudentTile({
    super.key,
    required this.name,
    this.avatarUrl,
    this.onTap,
    this.isViewActivityScreen = false,

    /// Full-width row with wrapped name (edit/view activity) — avoids truncation in grid cells.
    this.fillWidth = false,
  });
  final String name;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool isViewActivityScreen;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final textStyle = TextStyle(
      fontFamily: AppFonts.body,
      fontSize: isTablet ? 16 : 14,
      fontWeight: FontWeight.w500,
      color: AppColors.primaryColor,
      height: 19 / 14,
    );

    final useViewColors = isViewActivityScreen || fillWidth;
    final showRemove = onTap != null && !isViewActivityScreen;
    final preferLongPressTooltip = onTap != null;

    final row = Row(
      crossAxisAlignment: fillWidth
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: fillWidth
          ? MainAxisSize.max
          : (isViewActivityScreen ? MainAxisSize.min : MainAxisSize.max),
      mainAxisAlignment: isViewActivityScreen && !fillWidth
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        ProfileAvatar(
          name: name,

          // `avatarUrl` is either a resolved URL or a raw media-asset code
          // depending on the caller — `fileUuid` is never actually used to
          // resolve an image (only `imageUrl`/`mediaAssetCode` are), so
          // route to whichever matches the value's shape.
          imageUrl: (avatarUrl ?? '').startsWith('http') ? avatarUrl : null,
          assetCode: (avatarUrl ?? '').startsWith('http') ? null : avatarUrl,
          size: 35,
        ),
        SizedBox(width: useViewColors ? 8 : 4),
        if (fillWidth)
          Expanded(
            child: EllipsisTooltipText(
              text: name,
              style: textStyle,
              maxLines: 6,
              preferLongPress: preferLongPressTooltip,
            ),
          )
        else if (isViewActivityScreen)
          Flexible(
            child: EllipsisTooltipText(
              text: name,
              style: textStyle,
              maxLines: 1,
              preferLongPress: preferLongPressTooltip,
            ),
          )
        else
          Expanded(
            child: EllipsisTooltipText(
              text: name,
              style: textStyle,
              maxLines: 1,
              preferLongPress: preferLongPressTooltip,
            ),
          ),
        if (showRemove)
          IconButton(
            onPressed: onTap,
            icon: AppIcon(MediaRes.delete_icon, tone: IconTone.danger),
          ),
      ],
    );

    final decorated = Container(
      width: fillWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: useViewColors ? 14 : 12,
        vertical: useViewColors ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: useViewColors
            ? AppPalette.surfaceCard
            : AppPalette.surfaceSunken,
        borderRadius: BorderRadius.circular(useViewColors ? 24 : 12),
        border: Border.all(color: AppColors.themeColor, width: 1),
      ),
      child: row,
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: decorated,
      );
    }
    return decorated;
  }
}
