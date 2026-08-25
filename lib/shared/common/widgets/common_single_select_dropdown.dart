import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
            style: AppTextStyles.body.copyWith(color: AppColors.primaryColor),
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: AppTextStyles.body.copyWith(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
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
                        style: AppTextStyles.body,
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
