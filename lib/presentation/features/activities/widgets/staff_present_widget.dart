import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/presentation/features/activities/widgets/checkbox_widget.dart';

class StaffPresentWidget extends StatefulWidget {
  const StaffPresentWidget({super.key, required this.staffName, this.isEditable = true, this.incidentActivity = false, this.onSigned, this.isAlreadySigned = false});
  final String staffName;
  final bool isEditable;
  final bool incidentActivity;
  final ValueChanged<bool>? onSigned;
  final bool isAlreadySigned;

  @override
  State<StaffPresentWidget> createState() => _StaffPresentWidgetState();
}

class _StaffPresentWidgetState extends State<StaffPresentWidget> {
 late List<String> staffList;
 late String? selectedStaff;
 bool clickToSign = false;


  void _showWarningMessage(String message) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isWarning: true,
    );
  }

  @override
  void initState(){
    super.initState();
    // Build staff list with the logged-in staff name (if provided) at the top,
    // followed by fallback demo names.
    const defaultStaff = ['Staff A', 'Staff B', 'Staff C'];
    final name = widget.staffName.trim();
    staffList = [
      if (name.isNotEmpty) name,
      ...defaultStaff.where((s) => s != name),
    ];

    selectedStaff = name.isNotEmpty ? name : staffList.first;
    clickToSign = widget.isAlreadySigned;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (widget.incidentActivity)
              CheckboxWidget(
                label: 'Click to sign',
                isEditable: widget.isEditable,
                isChecked: clickToSign,
                onChecked: widget.isEditable
                    ? (newValue) {
                        setState(() {
                          clickToSign = newValue;
                        });
                        widget.onSigned?.call(newValue);
                      }
                    : null,
              ),
          ],
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0 ),
        InkWell(
          onTap: !widget.isEditable ?(){
            _showWarningMessage("Can not be edited.");
          } : null,
          child: Opacity(
            opacity: widget.isEditable ? 1.0 : widget.incidentActivity ? 1.0 : 0.4,
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
        ),
        SizedBox(height: responsive.verticalSpacing,),
        if (widget.incidentActivity && clickToSign)
          Container(
            constraints: BoxConstraints(minHeight: 60),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFB1AFE9).withOpacity(0.102),
              //color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                selectedStaff!,
                style: TextStyle(
                  fontFamily: 'MervaleScript',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff573353),
                  //height: 19 / 14,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
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
