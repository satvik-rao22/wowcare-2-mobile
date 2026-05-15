// import 'package:flutter/material.dart';
// import 'package:schoolerp/core/res/colors.dart';

// class GradientToggleButton extends StatelessWidget {
//   final bool minimized;
//   final VoidCallback onTap;

//   const GradientToggleButton({
//     Key? key,
//     required this.minimized,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: SizedBox(
//         width: 20,
//         height: 20,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             // Gradient border
//             Container(
//               width: 20,
//               height: 20,
//               decoration: BoxDecoration(
//                 gradient: AppColors.buildPrimaryGradient(),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//             // White inner background
//             Container(
//               width: 16,
//               height: 16,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//             // Icon
//             Icon(
//               minimized ? Icons.add : Icons.remove,
//               color: AppColors.primaryGradientColors.first,
//               size: 14,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
