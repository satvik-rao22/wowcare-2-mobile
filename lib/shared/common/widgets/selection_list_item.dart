import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import 'custom_checkbox.dart';
import 'profile_show_widget.dart';

class CommonSelectionItem extends StatelessWidget {
  final String name;
  final String? avatarUuid;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final double size;
  final double fontSize;

  const CommonSelectionItem({
    super.key,
    required this.name,
    required this.isSelected,
    required this.onSelectionChanged,
    this.avatarUuid,
    this.size = 32,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelectionChanged(!isSelected),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color.fromARGB(255, 249, 245, 250)
              : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  borderColor: AppColors.themeColor,
                  value: isSelected,
                  onChanged: onSelectionChanged,
                ),
              ),
              DocumentImageWidget(
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.trim().isEmpty ? 'Student' : name.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.primaryColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
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
