import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/app/theme/colors.dart';

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

    return SkeuPanel(
      radius: SkeuRadius.xxl,

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
            color: Colors.grey.shade700,
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
                    color: Colors.black87,
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
