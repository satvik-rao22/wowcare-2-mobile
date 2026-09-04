import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/dashed_outline_box.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// A student who is enrolled but has not started (5a "Starting soon").
///
/// Dashed rather than solid, and its avatar is grey rather than teal: they
/// are not in a room yet, so nothing about the row should read as present.
class UpcomingStudentRow extends StatelessWidget {
  const UpcomingStudentRow({required this.student, this.onTap, super.key});

  final StudentSummary student;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: onTap != null,
      label: student.fullName,
      child: DashedOutlineBox(
        padding: AppSizes.rowPad,
        onTap: onTap,
        child: Row(
          spacing: AppSizes.rowGap,
          children: <Widget>[
            AppAvatar(initials: student.initials, tone: AvatarTone.neutral),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSizes.rowTextGap,
                children: <Widget>[
                  Text(
                    student.fullName,
                    style: AppTextStyles.rowName.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    StudentsStrings.upcomingRowSub(student.classroomName),
                    style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                  ),
                ],
              ),
            ),
            const StatusPill(
              label: StudentsStrings.upcomingPill,
              tone: PillTone.staff,
              small: true,
            ),
          ],
        ),
      ),
    );
  }
}
