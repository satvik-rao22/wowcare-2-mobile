import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class SelectDropdownCard extends StatelessWidget {
  const SelectDropdownCard({
    super.key,
    required this.items,
    required this.onChanged,
    required this.placeholder,
    this.icon = Icons.home_outlined,
    this.initialValue,
  });

  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String placeholder;
  final IconData icon;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceField,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.transparentColor),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadowAmbient,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: initialValue,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primaryColor,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          hintText: placeholder,
          hintStyle: TextStyle(
            color: MaterialHues.grey700,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 1.2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MaterialHues.black87,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
