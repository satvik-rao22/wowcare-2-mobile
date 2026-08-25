import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class InputWidget extends StatefulWidget {
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
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: widget.label),
              if (widget.isRequired)
                TextSpan(
                  text: ' *',
                  style: AppTextStyles.body.copyWith(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: widget.height ?? responsive.inputFieldHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            readOnly: widget.readOnly,
            enableInteractiveSelection: !widget.readOnly,
            keyboardType: (widget.height != null && widget.height! > 48)
                ? TextInputType.multiline
                : TextInputType.text,
            textInputAction: (widget.height != null && widget.height! > 48)
                ? TextInputAction.newline
                : TextInputAction.done,
            minLines: (widget.height != null && widget.height! > 48) ? 3 : 1,
            maxLines: (widget.height != null && widget.height! > 48) ? 8 : 1,
            textAlignVertical: (widget.height != null && widget.height! > 48)
                ? TextAlignVertical.top
                : TextAlignVertical.center,
            maxLength: widget.maxLength,
            buildCounter: widget.maxLength == null
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
                          color: const Color(
                            0xff573353,
                          ).withValues(alpha: 0.55),
                        ),
                      ),
                    );
                  },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
          ),
        ),
      ],
    );
  }
}
