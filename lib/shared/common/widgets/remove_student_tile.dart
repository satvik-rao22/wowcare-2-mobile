import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/media_res.dart';
import '../../../presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart';

class RemoveStudentTile extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onRemove;

  const RemoveStudentTile({
    super.key,
    required this.student,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromRGBO(249, 245, 250, 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                BlocProvider(
                  create: (context) => sl<DocumentBloc>(),
                  child: DocumentImageWidget(
                    fileUuid: student.photoUuid,
                    size: 30,
                    name: student.fullName,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    student.fullName.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: SvgPicture.asset(MediaRes.delete_icon),
          ),
        ],
      ),
    );
  }
}
