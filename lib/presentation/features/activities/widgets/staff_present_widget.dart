import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';

class StaffPresentWidget extends StatefulWidget {
  const StaffPresentWidget({super.key, required this.staffName, this.isEditable = true});
  final String staffName;
  final bool isEditable;

  @override
  State<StaffPresentWidget> createState() => _StaffPresentWidgetState();
}

class _StaffPresentWidgetState extends State<StaffPresentWidget> {
 final List<String> staffList =['Staff A', 'Staff B', 'Staff C'];
 late String? selectedStaff;

  void _showWarningMessage(String message) {
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

  @override
  void initState(){
    super.initState();
    selectedStaff = widget.staffName;
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
              fontSize:  13,
              fontWeight: FontWeight.w400,
              fontFamily: 'Manrope',
            ),
            children: [
              TextSpan(text: 'Staff Present'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0 ),
        InkWell(
          onTap: !widget.isEditable ?(){
            _showWarningMessage("Can not be edited.");
          } : null,
          child: Opacity(
            opacity: widget.isEditable ? 1.0 : 0.4,
            child: CustomDropdown(
              hintText: 'Select present staff',
              items: staffList,
              selectedItem: selectedStaff,
              isEnabled: widget.isEditable,
              onSelect: widget.isEditable?
              (String? value) {
                setState(() {
                  selectedStaff = value;
                });
              }: null,
            ),
          ),
        )
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
