import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

import 'custom_checkbox.dart';
import 'profile_show_widget.dart';

class StudentTile extends StatelessWidget {
  const StudentTile({
    super.key,
    required this.name,
    this.avatarUrl,
    this.isSelected = false,
    this.onSelected,
  });

  final String name;
  final String? avatarUrl;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        onSelected?.call(!isSelected);
      },
      child: Container(
        //height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          //color: isSelected ? const Color(0xFFF8F7FA) : Colors.white,
          color: isSelected
              ? const Color(0xFFB1AFE9).withOpacity(0.102)
              : Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.themeColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            DocumentImageWidget(fileUuid: '', name: name, size: 35),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff573353),
                  height: 19 / 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CustomCheckbox(
              value: isSelected,
              usingInkwell: true,
              onChanged: null,
              scale: 1.2,
              borderColor: AppColors.themeColor,
              label: null,
            ),
          ],
        ),
      ),
    );
  }
}
