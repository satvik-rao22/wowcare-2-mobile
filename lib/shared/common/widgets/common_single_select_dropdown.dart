import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

class CommonSingleSelectDropdown extends StatelessWidget {
  const CommonSingleSelectDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    this.isRequired = true,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: MaterialHues.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppSurfaces.well(radius: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryColor,
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: AppFonts.body),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onSelected(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
