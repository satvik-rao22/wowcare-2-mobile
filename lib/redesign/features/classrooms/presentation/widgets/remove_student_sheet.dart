import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/destructive_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// The second refusal (7i): taking a student out of the classroom.
///
/// It is not a deletion, and the sheet says so twice — what it costs in red,
/// and what is kept in green. Resolves to true when the caller confirmed.
class RemoveStudentSheet extends StatelessWidget {
  const RemoveStudentSheet({
    required this.student,
    required this.classroom,
    super.key,
  });

  final RosterStudent student;
  final ClassroomSummary classroom;

  static Future<bool?> show(
    BuildContext context, {
    required RosterStudent student,
    required ClassroomSummary classroom,
  }) => showAppSheet<bool>(
    context,
    builder: (_) => RemoveStudentSheet(student: student, classroom: classroom),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppBottomSheet(
      title: ClassroomsStrings.takeOutOf(student.firstName, classroom.name),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.refusalGap,
        children: <Widget>[
          Text(
            ClassroomsStrings.removeBody,
            style: ClassroomsTextStyles.sheetBody.copyWith(color: c.ink2),
          ),
          AppCard(
            padding: ClassroomsSizes.refusalCardPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: ClassroomsSizes.costRowGap,
              children: <Widget>[
                const SectionEyebrow(label: ClassroomsStrings.whatThisCosts),
                _Cost(
                  isLoss: true,
                  text: ClassroomsStrings.dropsTo(
                    classroom.name,
                    classroom.enrolled - 1,
                    classroom.capacity,
                  ),
                ),
                const _Cost(isLoss: true, text: ClassroomsStrings.leavesNotes),
                const _Cost(isLoss: false, text: ClassroomsStrings.keptRecord),
              ],
            ),
          ),
        ],
      ),
      footer: <Widget>[
        SecondaryKey(
          label: ClassroomsStrings.keepThemHere,
          onTap: () => Navigator.of(context).pop(false),
          padding: ClassroomsSizes.footerKeyPad,
        ),
        DestructiveKey(
          label: ClassroomsStrings.takeThemOut,
          onTap: () => Navigator.of(context).pop(true),
          padding: ClassroomsSizes.footerKeyPad,
        ),
      ],
    );
  }
}

/// One consequence: a red dot for what goes, a green one for what stays.
class _Cost extends StatelessWidget {
  const _Cost({required this.isLoss, required this.text});

  final bool isLoss;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ClassroomsSizes.costGap,
      children: <Widget>[
        Container(
          width: ClassroomsSizes.costDot,
          height: ClassroomsSizes.costDot,
          margin: const EdgeInsets.only(top: ClassroomsSizes.costDot),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLoss ? c.danger : c.success,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: ClassroomsTextStyles.costLine.copyWith(color: c.ink2),
          ),
        ),
      ],
    );
  }
}
