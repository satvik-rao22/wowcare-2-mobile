import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'custom_checkbox.dart';
import 'ellipsis_tooltip_text.dart';
import 'profile_show_widget.dart';

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
    final borderColor = isEnabled ? AppColors.themeColor : Colors.grey.shade300;
    final nameColor = isEnabled ? AppColors.primaryColor : Colors.grey[500];

    return InkWell(
      onTap: isEnabled ? () => onSelectionChanged(!isSelected) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          color: !isEnabled
              ? Colors.grey.shade100
              : (isSelected
                    ? const Color.fromARGB(255, 249, 245, 250)
                    : Colors.white),
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
                child: DocumentImageWidget(
                  fileUuid: '',
                  // `avatarUuid` is either a resolved URL or a raw media-asset
                  // code depending on the caller — `fileUuid` is never
                  // actually used to resolve an image (only
                  // `imageUrl`/`mediaAssetCode` are), so route to whichever
                  // matches the value's shape.
                  imageUrl: (avatarUuid ?? '').startsWith('http')
                      ? avatarUuid
                      : null,
                  mediaAssetCode: (avatarUuid ?? '').startsWith('http')
                      ? null
                      : avatarUuid,
                  name: name,
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
                        fontFamily: 'Manrope',
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
                            fontFamily: 'Manrope',
                            color: Colors.grey[500],
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
