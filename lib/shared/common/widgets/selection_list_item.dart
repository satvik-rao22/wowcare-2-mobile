import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import '../../../../core/theme/app_colors.dart';
import 'custom_checkbox.dart';
import 'ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

class CommonSelectionItem extends StatelessWidget {
  final String name;
  final String? avatarUuid;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final double size;
  final double fontSize;

  /// When false, the row can't be tapped/checked and renders greyed out —
  /// e.g. a student with no guardian linked can't be messaged (no one to
  /// receive it), matching web's disabled-row behavior for that case.
  final bool isEnabled;

  /// Short reason shown under the name when [isEnabled] is false (e.g. "No
  /// parent linked"). Ignored when [isEnabled] is true.
  final String? disabledReason;

  const CommonSelectionItem({
    super.key,
    required this.name,
    required this.isSelected,
    required this.onSelectionChanged,
    this.avatarUuid,
    this.size = 32,
    this.fontSize = 13,
    this.isEnabled = true,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isEnabled ? AppColors.themeColor : MaterialHues.grey300;
    final nameColor = isEnabled ? AppColors.primaryColor : MaterialHues.grey500;

    return InkWell(
      onTap: isEnabled ? () => onSelectionChanged(!isSelected) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          color: !isEnabled
              ? AppPalette.surfaceMuted
              : (isSelected
                    ? AppPalette.surfaceSelected
                    : AppPalette.surfaceCard),
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  borderColor: borderColor,
                  value: isSelected,
                  onChanged: isEnabled ? onSelectionChanged : null,
                ),
              ),
              Opacity(
                opacity: isEnabled ? 1 : 0.5,
                child: ProfileAvatar(
                  name: name,

                  // `avatarUuid` is either a resolved URL or a raw media-asset
                  // code depending on the caller — `fileUuid` is never
                  // actually used to resolve an image (only
                  // `imageUrl`/`mediaAssetCode` are), so route to whichever
                  // matches the value's shape.
                  imageUrl: (avatarUuid ?? '').startsWith('http')
                      ? avatarUuid
                      : null,
                  assetCode: (avatarUuid ?? '').startsWith('http')
                      ? null
                      : avatarUuid,
                  size: size,
                  fontSize: fontSize,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EllipsisTooltipText(
                      text: name.trim().isEmpty ? 'Student' : name.trim(),
                      maxLines: 2,
                      preferLongPress: true,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        color: nameColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isEnabled && (disabledReason ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          disabledReason!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            color: MaterialHues.grey500,
                            fontSize: fontSize - 2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
