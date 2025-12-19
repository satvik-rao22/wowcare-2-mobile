import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';

class ActivityDropdownWidget extends StatefulWidget {
  const ActivityDropdownWidget({
    super.key,
    required this.options,
    required this.dropDownName,
    this.selectedValue,
    this.isRequired = false,
    this.isEnabled = true,
    this.onSelect

  });
  final List<String> options;
  final String dropDownName;
  final bool isRequired;
  final bool isEnabled;
  final ValueChanged<String?>? onSelect;
  final String? selectedValue;

  @override
  State<ActivityDropdownWidget> createState() => _ActivityDropdownWidgetState();
}

class _ActivityDropdownWidgetState extends State<ActivityDropdownWidget> {
  late String? _internalSelected;
  String? get _effectiveSelected => widget.selectedValue ?? _internalSelected;

  @override
  void initState() {
    super.initState();
    _internalSelected = widget.selectedValue; // Sync initial value
  }
  @override
  void didUpdateWidget(covariant ActivityDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent now controls the value, sync internal state
    if (widget.selectedValue != oldWidget.selectedValue) {
      _internalSelected = widget.selectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontFamily: 'Manrope',
            ),
            children: [
              TextSpan(text: widget.dropDownName),
              if (widget.isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),

        CustomDropdown(
          hintText: 'Select',
          items: widget.options,
          selectedItem: _effectiveSelected,
          isEnabled: widget.isEnabled,
          onSelect: (String? value) {
                  if (widget.selectedValue == null) {
                    setState(() {
                      _internalSelected = value;
                    });
                  }
                  widget.onSelect?.call(value);
                }

        ),
      ],
    );
  }

  // Widget _buildCustomDropdown(
  //     String hintText,
  //     List<String> items,
  //     String? selectedItem,
  //     ValueChanged<String?> onSelect, {
  //       bool isRequired = false,
  //       double? height = null
  //     }) {
  //   final responsive = ResponsiveHelper(context);
  //   return CustomDropdown(
  //     label: null,
  //     hintText: hintText,
  //     items: items,
  //     height: height,
  //     selectedItem: selectedItem,
  //     onSelect: onSelect,
  //     showAsterisk: isRequired,
  //     labelStyle: TextStyle(
  //       fontSize: responsive.labelFontSize,
  //       fontFamily: "Manrope",
  //       fontWeight: FontWeight.w400,
  //       color: const Color(0xff573353),
  //     ),
  //     labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
  //     fieldHeight: responsive.isTablet ? 64.0 : 56.0,
  //     selectedTextStyle: TextStyle(
  //       fontFamily: 'Manrope',
  //       fontSize: responsive.inputFontSize,
  //       fontWeight: FontWeight.w600,
  //       color: const Color(0xff573353),
  //       height: 19 / 14,
  //     ),
  //     popupItemTextStyle: TextStyle(
  //       fontFamily: 'Manrope',
  //       fontSize: responsive.inputFontSize,
  //       fontWeight: FontWeight.w400,
  //       color: const Color(0xff573353),
  //     ),
  //     contentPadding: EdgeInsets.symmetric(
  //       horizontal: responsive.isTablet ? 16.0 : 12.0,
  //       vertical: responsive.isTablet ? 16.0 : 12.0,
  //     ),
  //   );
  // }
}
