import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';

class NotificationSettingRow extends StatelessWidget {
  final String title;
  final bool inAppValue;
  final bool emailValue;
  final bool pushValue;
  final ValueChanged<bool?>? onInAppChanged;
  final ValueChanged<bool?>? onEmailChanged;
  final ValueChanged<bool?>? onPushChanged;

  const NotificationSettingRow({
    super.key,
    required this.title,
    required this.inAppValue,
    required this.emailValue,
    required this.pushValue,
    this.onInAppChanged,
    this.onEmailChanged,
    this.onPushChanged,
  });

  @override
  Widget build(BuildContext context) {
    const columnWidth = 60.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE9ECEF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          SizedBox(
            width: columnWidth,
            child: Center(
              child: CustomCheckbox(
                value: inAppValue,
                borderColor: AppColors.themeColor,
                onChanged: onInAppChanged,
              ),
            ),
          ),
          SizedBox(
            width: columnWidth,
            child: Center(
              child: CustomCheckbox(
                value: emailValue,
                borderColor: AppColors.themeColor,
                onChanged: onEmailChanged,
              ),
            ),
          ),
          SizedBox(
            width: columnWidth,
            child: Center(
              child: CustomCheckbox(
                value: pushValue,
                borderColor: AppColors.themeColor,
                onChanged: onPushChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}