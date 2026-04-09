import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_date_time_field.dart';

enum PublishType { untilDate, publishAll }

class PublishOptionCard extends StatelessWidget {
  final PublishType selectedValue;
  final ValueChanged<PublishType> onChanged;

  final String untilDateTitle;
  final String publishAllTitle;
  final String? dateLabel;

  /// Controls layout: `false` = horizontal row (default, like screenshot), `true` = vertical column
  final bool isVertical;

  /// Controls whether to show the date field when "Publish Until Date" is selected
  final bool showDateField;

  const PublishOptionCard({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    required this.untilDateTitle,
    required this.publishAllTitle,
    this.dateLabel,
    this.isVertical = false, // Default: horizontal like screenshot
    this.showDateField = true, // Default: show date field
  });

  @override
  Widget build(BuildContext context) {
    final bool isUntilDateSelected = selectedValue == PublishType.untilDate;

    return Card(
      elevation: 0,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Layout: Horizontal Row or Vertical Column
            if (isVertical)
              // Vertical Layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _radioItem(
                    title: untilDateTitle,
                    value: PublishType.untilDate,
                  ),
                  const SizedBox(height: 12),
                  _radioItem(
                    title: publishAllTitle,
                    value: PublishType.publishAll,
                  ),
                ],
              )
            else
              // Horizontal Single Row (Default - like your screenshot)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _radioItem(
                      title: untilDateTitle,
                      value: PublishType.untilDate,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _radioItem(
                      title: publishAllTitle,
                      value: PublishType.publishAll,
                    ),
                  ),
                ],
              ),

            // Date field - only shown when both conditions are true
            if (showDateField && isUntilDateSelected) ...[
              const SizedBox(height: 24),
              CustomDateTimeField(
                label: dateLabel ?? 'Until Date',
                initialDate: DateTime(2024, 12, 31),
                isRequired: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _radioItem({required String title, required PublishType value}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 0.95,
            child: Radio<PublishType>(
              value: value,
              groupValue: selectedValue,
              onChanged: (val) => onChanged(val!),
              activeColor: AppColors.themeColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppText.body(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.4,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
