import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_row_details.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// One student on the roster (5a): a card that opens where it stands.
///
/// The dot on the avatar is today's attendance, ringed in the card it sits
/// on. Tapping the row opens it rather than leaving the list, because the
/// answer most of the time is "when did they get in", not "show me the file".
class StudentRosterRow extends StatelessWidget {
  const StudentRosterRow({
    required this.student,
    required this.isExpanded,
    required this.onTap,
    this.canWrite = false,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onOpenProfile,
    this.onMoreActions,
    super.key,
  });

  final StudentSummary student;
  final bool isExpanded;
  final VoidCallback onTap;

  final bool canWrite;
  final bool isSelectMode;
  final bool isSelected;

  final VoidCallback? onOpenProfile;
  final VoidCallback? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: EdgeInsets.zero,
      clipContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            selected: isSelectMode ? isSelected : null,
            label: student.fullName,
            child: Pressable.surface(
              onTap: onTap,
              child: Padding(
                padding: AppSizes.rowPad,
                child: Row(
                  spacing: AppSizes.rowGap,
                  children: <Widget>[
                    if (isSelectMode) AppCheckbox(checked: isSelected),
                    AppAvatar(
                      initials: student.initials,
                      attendance: student.attendance,
                      ringColor: c.card,
                    ),
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
                            StudentsStrings.rowSub(
                              student.classroomName,
                              student.age,
                            ),
                            style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!student.hasGuardian)
                      const StatusPill(
                        label: StudentsStrings.noParentFlag,
                        small: true,
                      ),
                    AnimatedRotation(
                      duration: AppMotion.fast,
                      curve: AppMotion.ease,
                      turns: isExpanded ? .5 : 0,
                      child: Icon(
                        AppIcons.chevronDown,
                        size: AppSizes.rowChevron,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded && !isSelectMode)
            Padding(
              padding: StudentsSizes.detailPad,
              child: StudentRowDetails(
                student: student,
                canWrite: canWrite,
                onOpenProfile: onOpenProfile,
                onMoreActions: onMoreActions,
              ),
            ),
        ],
      ),
    );
  }
}
