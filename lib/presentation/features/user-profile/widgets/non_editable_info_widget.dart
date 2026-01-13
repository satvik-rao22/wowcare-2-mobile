import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';

class NonEditableInfoWidget extends StatelessWidget {
  const NonEditableInfoWidget({
    super.key,
    required this.label,
    this.isEditable = true,
    this.value,
    this.isRequired = false,
  });
  final String label;
  final bool isEditable;
  final String? value;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    void showWarningMessage(String message) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade50,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.orange.shade100),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: responsive.labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        InkWell(
          onTap: !isEditable
              ? () {
                  showWarningMessage("Can not be edited.");
                }
              : null,
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.6,
            child: Container(
              constraints: BoxConstraints(
                minHeight: responsive.isTablet ? 64.0 : 56.0,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFB1AFE9).withOpacity(0.102),
                //color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.isTablet ? 16.0 : 12.0,
                  vertical: responsive.isTablet ? 16.0 : 12.0,
                ),
                child: Text(
                  value!,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.inputFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff573353),
                    height: 19 / 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
