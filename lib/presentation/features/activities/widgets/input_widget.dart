import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class InputWidget extends StatelessWidget {
  const InputWidget({
    super.key,
    required this.controller,
    this.isRequired = false,
    this.label = 'Description',
    this.hint,
    this.height,
    this.readOnly = false,
    this.maxLength,
  });
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isRequired;
  final double? height;
  final bool readOnly;

  /// When set, enforces character limit and shows a counter (e.g. 500 for activities).
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = AppTextStyles.activityInputFieldLabel(
      fontSize: responsive.labelFontSize,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: AppTextStyles.activityRequiredMarker,
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: height ?? responsive.inputFieldHeight,
          ),
          decoration: AppSurfaces.field(
            radius: responsive.isTablet ? 12.0 : 8.0,
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            enableInteractiveSelection: !readOnly,
            keyboardType: (height != null && height! > 48)
                ? TextInputType.multiline
                : TextInputType.text,
            textInputAction: (height != null && height! > 48)
                ? TextInputAction.newline
                : TextInputAction.done,
            minLines: (height != null && height! > 48) ? 3 : 1,
            maxLines: (height != null && height! > 48) ? 8 : 1,
            textAlignVertical: (height != null && height! > 48)
                ? TextAlignVertical.top
                : TextAlignVertical.center,
            maxLength: maxLength,
            buildCounter: maxLength == null
                ? null
                : (
                    BuildContext context, {
                    required int currentLength,
                    required bool isFocused,
                    required int? maxLength,
                  }) {
                    if (maxLength == null) return null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 6),
                      child: Text(
                        '$currentLength / $maxLength',
                        style: labelStyle.copyWith(
                          fontSize: 11,
                          color: AppColors.primaryColor.withValues(alpha: 0.55),
                        ),
                      ),
                    );
                  },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(
                color: AppColors.activityMutedGreyColor,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
            style: AppTextStyles.activityInputValueText(
              fontSize: responsive.inputFontSize,
            ),
          ),
        ),
      ],
    );
  }
}
