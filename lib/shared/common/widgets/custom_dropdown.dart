// import 'package:flutter/material.dart';
// import 'package:schoolerp/core/res/colors.dart';

// class CustomDropdown extends StatefulWidget {
//   const CustomDropdown({
//     super.key,
//     this.label,
//     required this.hintText,
//     required this.items,
//     this.isField = true,
//     this.isEnabled = true,
//     this.border,
//     this.onSelect,
//     this.selectedItem, // New parameter for the selected item
//       this.controller,
//       this.value,
//   });

//   final String? label;
//   final String hintText;
//   final List<String> items;
//   final bool isField;
//   final bool isEnabled;
//   final InputBorder? border;
//   final ValueChanged<String?>? onSelect;
//   final String? selectedItem; // New parameter for the selected item
//    final TextEditingController? controller;
//     final String? value;

//   @override
//   State<CustomDropdown> createState() => _CustomDropdownState();
// }

// class _CustomDropdownState extends State<CustomDropdown> {
//   String? selectedItem; // Local state for the selected item

//   @override
//   void initState() {
//     super.initState();
//     selectedItem = widget.selectedItem; // Initialize with the selected item
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (widget.label != null)
//           Text(
//             widget.label!,
//             style: TextStyle(
//               color: AppColors.primaryColor.withValues(alpha: 0.5),
//               fontSize: 13,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         if (widget.label != null) const SizedBox(height: 12),
//         Container(
//           constraints: BoxConstraints(minHeight: widget.isField ? 40 : 30),
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF8F7FA),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: PopupMenuButton<String>(
//             enabled: widget.isEnabled,
//             onSelected: (value) {
//               setState(() {
//                 selectedItem = value; // Update the selected item
//               });
//               // Call the onSelect callback if it's provided
//               if (widget.onSelect != null) {
//                 widget.onSelect!(value);
//               }
//             },
//             itemBuilder: (BuildContext context) {
//               return widget.items.map((String item) {
//                 return PopupMenuItem<String>(
//                   value: item,
//                   child: Text(
//                     item,
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: widget.isField ? 15 : 13,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 );
//               }).toList();
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Flexible(
//                     child: Text(
//                       selectedItem ?? widget.hintText,
//                       style: TextStyle(
//                         color: widget.isEnabled
//                             ? AppColors.primaryColor.withValues(alpha: 0.6)
//                             : AppColors.primaryColor,
//                         fontSize: widget.isField ? 14 : 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   if (widget.isEnabled)
//                     const Icon(
//                       Icons.keyboard_arrow_down,
//                       color: AppColors.primaryColor,
//                       size: 24,
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({
    super.key,
    this.label,
    required this.hintText,
    required this.items,
    this.initialValue,
    this.isField = true,
    this.isEnabled = true,
    this.border,
    this.onSelect,
    this.selectedItem, // New parameter for the selected item
    this.controller,
    this.labelStyle,
    this.showAsterisk = true,
    this.labelBottomSpacing,
    this.fieldHeight,
    this.selectedTextStyle,
    this.popupItemTextStyle,
    this.contentPadding,
    this.height = null,
    this.leadingIcon,
  });

  final String? label;
  final String hintText;
  final List<String> items;
  final bool isField;
  final bool isEnabled;
  final InputBorder? border;
  final ValueChanged<String?>? onSelect;
  final String? selectedItem; // New parameter for the selected item
  final String? initialValue;
  final TextEditingController? controller;
  final TextStyle? labelStyle;
  final bool showAsterisk;
  final double? labelBottomSpacing;
  final double? fieldHeight;
  final TextStyle? selectedTextStyle;
  final TextStyle? popupItemTextStyle;
  final EdgeInsets? contentPadding;
  final double? height;
  /// Optional leading widget (e.g. an icon) shown before the text.
  final Widget? leadingIcon;

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? selectedItem; // Local state for the selected item

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedItem; // Initialize with the selected item
  }

  @override
  void didUpdateWidget(CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the selectedItem if the widget's selectedItem changes
    if (oldWidget.selectedItem != widget.selectedItem) {
      setState(() {
        selectedItem = widget.selectedItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build a list where the first option is always the hint text.
    // Selecting it will clear the current selection.
    final List<String> displayItems = <String>[
      widget.hintText,
      ...widget.items,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: (widget.labelStyle?.color ?? AppColors.primaryColor),
                fontSize: widget.labelStyle?.fontSize ?? 13,
                fontWeight: widget.labelStyle?.fontWeight ?? FontWeight.w400,
                fontFamily: widget.labelStyle?.fontFamily ?? 'Manrope',


              ),
              children: [
                TextSpan(text: widget.label!),
                if (widget.showAsterisk)
                  const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        if (widget.label != null)
          SizedBox(height: widget.labelBottomSpacing ?? 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints: BoxConstraints(minHeight: widget.height ?? widget.fieldHeight ?? (widget.isField ? 40 : 30)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFB1AFE9).withOpacity(0.102),
                //color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: PopupMenuButton<String>(
                enabled: widget.isEnabled,
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                onSelected: (value) {
                  setState(() {
                    // Treat selecting the hint text as "clear selection".
                    if (value == widget.hintText) {
                      selectedItem = null;
                    } else {
                      selectedItem = value; // Update the selected item
                    }
                  });
                  // Call the onSelect callback if it's provided
                  if (widget.onSelect != null) {
                    widget.onSelect!(selectedItem);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return displayItems.map((String item) {
                    return PopupMenuItem<String>(
                      value: item,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: widget.popupItemTextStyle ?? TextStyle(
                                color: AppColors.primaryColor.withOpacity(0.9),
                                fontSize: widget.isField ? 17 : 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Padding(
                  padding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        widget.leadingIcon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          selectedItem ?? widget.hintText,
                          style: widget.selectedTextStyle ?? TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: selectedItem != null ? FontWeight.w600 : FontWeight.w500,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (widget.isEnabled)
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}