import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/media_res.dart';
import 'ellipsis_tooltip_text.dart';
import 'profile_show_widget.dart';

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
      fontFamily: 'Manrope',
      fontSize: isTablet ? 16 : 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xff573353),
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
        DocumentImageWidget(fileUuid: '', name: name, size: 35),
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
            icon: SvgPicture.asset(MediaRes.delete_icon),
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
            ? Colors.white
            : const Color(0xFFB1AFE9).withValues(alpha: 0.102),
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
