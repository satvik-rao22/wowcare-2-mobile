import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_action_row.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// What "More actions" offers on one student (5a).
///
/// Five doors, then the one pink key. Four of the five belong to other
/// modules, so this sheet resolves to which was chosen and the roster does
/// the going.
enum StudentAction { attendance, activity, message, edit, deactivate, profile }

/// The sheet itself.
class StudentActionsSheet extends StatelessWidget {
  const StudentActionsSheet({required this.student, super.key});

  final StudentSummary student;

  /// Resolves to the action chosen, or null when the sheet is dismissed.
  static Future<StudentAction?> show(
    BuildContext context, {
    required StudentSummary student,
  }) => showAppSheet<StudentAction>(
    context,
    builder: (_) => StudentActionsSheet(student: student),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final firstTag = student.tags.isEmpty
        ? StudentsStrings.noTags
        : student.tags.first.label;

    return AppBottomSheet(
      header: Row(
        spacing: StudentsSizes.sheetHeaderGap,
        children: <Widget>[
          AppAvatar(
            initials: student.initials,
            size: StudentsSizes.sheetAvatar,
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
                  StudentsStrings.sheetSub(student.classroomName, firstTag),
                  style: StudentsTextStyles.sheetSub.copyWith(color: c.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StudentsSizes.actionRowGap,
          children: <Widget>[
            StudentActionRow(
              glyph: StudentsStrings.glyphSignIn,
              label: StudentsStrings.actionSignInOut,
              note: StudentsStrings.actionSignInOutNote,
              tone: ActionTone.success,
              onTap: () => _pick(context, StudentAction.attendance),
            ),
            StudentActionRow(
              glyph: StudentsStrings.glyphActivity,
              label: StudentsStrings.actionActivity,
              note: StudentsStrings.actionActivityNote,
              tone: ActionTone.student,
              onTap: () => _pick(context, StudentAction.activity),
            ),
            StudentActionRow(
              glyph: StudentsStrings.glyphMessage,
              label: StudentsStrings.actionMessage,
              note: student.hasGuardian
                  ? student.guardianNames.join(', ')
                  : StudentsStrings.noGuardianOnRecord,
              onTap: student.hasGuardian
                  ? () => _pick(context, StudentAction.message)
                  : null,
            ),
            StudentActionRow(
              glyph: StudentsStrings.glyphEdit,
              label: StudentsStrings.actionEdit,
              note: StudentsStrings.actionEditNote,
              onTap: () => _pick(context, StudentAction.edit),
            ),
            StudentActionRow(
              glyph: StudentsStrings.glyphDeactivate,
              label: StudentsStrings.actionDeactivate,
              note: StudentsStrings.actionDeactivateNote,
              tone: ActionTone.danger,
              onTap: () => _pick(context, StudentAction.deactivate),
            ),
          ],
        ),
      ),
      footer: <Widget>[
        PrimaryKey(
          label: StudentsStrings.openProfile,
          onTap: () => _pick(context, StudentAction.profile),
        ),
      ],
    );
  }

  void _pick(BuildContext context, StudentAction action) =>
      Navigator.of(context).pop(action);
}
