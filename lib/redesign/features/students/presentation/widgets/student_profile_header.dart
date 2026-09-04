import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/ringed_avatar.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The top of 5c: back, the student, and where they stand.
///
/// The status pill is the enrollment status, not today's attendance; today is
/// the ring around the avatar, so the two never fight for the same slot.
class StudentProfileHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const StudentProfileHeader({required this.student, super.key});

  final StudentSummary student;

  @override
  Size get preferredSize =>
      const Size.fromHeight(StudentsSizes.profileAvatar + 24);

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: StudentsSizes.profileHeaderPad,
      child: Row(
        spacing: StudentsSizes.profileHeaderGap,
        children: <Widget>[
          const BackKey(),
          RingedAvatar(
            initials: student.initials,
            status: student.attendance,
            textStyle: StudentsTextStyles.headerInitials,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  student.fullName,
                  style: AppTextStyles.detailTitle.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  StudentsStrings.rowSub(student.classroomName, student.age),
                  style: StudentsTextStyles.headerSub.copyWith(color: c.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusPill(
            label: student.status.label,
            tone: switch (student.status) {
              StudentStatus.active => PillTone.success,
              StudentStatus.upcoming => PillTone.staff,
              StudentStatus.inactive => PillTone.neutral,
            },
            small: true,
          ),
        ],
      ),
    );
  }
}
