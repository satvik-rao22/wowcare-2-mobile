// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/app_media_res.dart';
// import '../../../presentation/features/attendance/view/student_attendance_forms/student_sign_in_form.dart';
// import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

// class RemoveStudentTile extends StatelessWidget {
//   final StudentEntity student;
//   final VoidCallback onRemove;

//   const RemoveStudentTile({
//     super.key,
//     required this.student,
//     required this.onRemove,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.themeColor),
//         borderRadius: BorderRadius.circular(10),
//         color: AppPalette.surfaceSunken,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Row(
//               children: [
//                 BlocProvider(
//                   create: (context) => sl<DocumentBloc>(),
//                   child: ProfileAvatar(
//                     fileUuid: student.photoUuid,
//                     size: 30,
//                     name: student.fullName,
//                     fontSize: 12,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     student.fullName.split(' ').first,
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     softWrap: false,
//                     style: const TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: onRemove,
//             child: AppIcon(MediaRes.delete_icon, tone: IconTone.danger),
//           ),
//         ],
//       ),
//     );
//   }
// }
