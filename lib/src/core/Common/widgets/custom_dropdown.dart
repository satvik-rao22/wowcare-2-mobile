// // import 'package:flutter/material.dart';
// // import 'package:schoolerp/core/res/colors.dart';

// // class CustomDropdown extends StatefulWidget {
// //   const CustomDropdown({
// //     super.key,
// //     this.label,
// //     required this.hintText,
// //     required this.items,
// //     this.isField = true,
// //     this.isEnabled = true,
// //     this.border,
// //     this.onSelect,
// //     this.selectedItem, // New parameter for the selected item
// //       this.controller,
// //       this.value,
// //   });

// //   final String? label;
// //   final String hintText;
// //   final List<String> items;
// //   final bool isField;
// //   final bool isEnabled;
// //   final InputBorder? border;
// //   final ValueChanged<String?>? onSelect;
// //   final String? selectedItem; // New parameter for the selected item
// //    final TextEditingController? controller;
// //     final String? value;

// //   @override
// //   State<CustomDropdown> createState() => _CustomDropdownState();
// // }

// // class _CustomDropdownState extends State<CustomDropdown> {
// //   String? selectedItem; // Local state for the selected item

// //   @override
// //   void initState() {
// //     super.initState();
// //     selectedItem = widget.selectedItem; // Initialize with the selected item
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         if (widget.label != null)
// //           Text(
// //             widget.label!,
// //             style: TextStyle(
// //               color: AppColors.primaryColor.withValues(alpha: 0.5),
// //               fontSize: 13,
// //               fontWeight: FontWeight.w400,
// //             ),
// //           ),
// //         if (widget.label != null) const SizedBox(height: 12),
// //         Container(
// //           constraints: BoxConstraints(minHeight: widget.isField ? 40 : 30),
// //           width: double.infinity,
// //           decoration: BoxDecoration(
// //             color: const Color(0xFFF8F7FA),
// //             borderRadius: BorderRadius.circular(10),
// //           ),
// //           child: PopupMenuButton<String>(
// //             enabled: widget.isEnabled,
// //             onSelected: (value) {
// //               setState(() {
// //                 selectedItem = value; // Update the selected item
// //               });
// //               // Call the onSelect callback if it's provided
// //               if (widget.onSelect != null) {
// //                 widget.onSelect!(value);
// //               }
// //             },
// //             itemBuilder: (BuildContext context) {
// //               return widget.items.map((String item) {
// //                 return PopupMenuItem<String>(
// //                   value: item,
// //                   child: Text(
// //                     item,
// //                     style: TextStyle(
// //                       color: AppColors.primaryColor,
// //                       fontSize: widget.isField ? 15 : 13,
// //                       fontWeight: FontWeight.w400,
// //                     ),
// //                   ),
// //                 );
// //               }).toList();
// //             },
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Flexible(
// //                     child: Text(
// //                       selectedItem ?? widget.hintText,
// //                       style: TextStyle(
// //                         color: widget.isEnabled
// //                             ? AppColors.primaryColor.withValues(alpha: 0.6)
// //                             : AppColors.primaryColor,
// //                         fontSize: widget.isField ? 14 : 12,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                       overflow: TextOverflow.ellipsis,
// //                     ),
// //                   ),
// //                   const SizedBox(width: 4),
// //                   if (widget.isEnabled)
// //                     const Icon(
// //                       Icons.keyboard_arrow_down,
// //                       color: AppColors.primaryColor,
// //                       size: 24,
// //                     ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:schoolerp/core/res/colors.dart';

// class CustomDropdown extends StatefulWidget {
//   const CustomDropdown({
//     super.key,
//     this.label,
//     required this.hintText,
//     required this.items,
//     this.initialValue,
//     this.isField = true,
//     this.isEnabled = true,
//     this.border,
//     this.onSelect,
//     this.selectedItem, // New parameter for the selected item
//     this.controller,
//   });

//   final String? label;
//   final String hintText;
//   final List<String> items;
//   final bool isField;
//   final bool isEnabled;
//   final InputBorder? border;
//   final ValueChanged<String?>? onSelect;
//   final String? selectedItem; // New parameter for the selected item
//   final String? initialValue;
//   final TextEditingController? controller;

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
//   void didUpdateWidget(CustomDropdown oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Update the selectedItem if the widget's selectedItem changes
//     if (oldWidget.selectedItem != widget.selectedItem) {
//       setState(() {
//         selectedItem = widget.selectedItem;
//       });
//     }
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
//               color: AppColors.primaryColor.withOpacity(0.5),
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
//                 final isSelected = item == selectedItem;
//                 return PopupMenuItem<String>(
//                   value: item,
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           item,
//                           style: TextStyle(
//                             color: isSelected
//                                 ? AppColors.primaryColor
//                                 : AppColors.primaryColor.withOpacity(0.7),
//                             fontSize: widget.isField ? 15 : 13,
//                             fontWeight:
//                                 isSelected ? FontWeight.w600 : FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       if (isSelected)
//                         const Icon(
//                           Icons.check,
//                           color: AppColors.primaryColor,
//                           size: 16,
//                         ),
//                     ],
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
//                             ? AppColors.primaryColor.withOpacity(0.6)
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
