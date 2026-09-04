import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/destructive_key.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// 5h. Taking a student off the roster, and what that costs.
///
/// The sheet says the price before it asks: what changes today, what is kept,
/// and that nothing is deleted. The quiet key is the safe one, and it is the
/// one that reads like a sentence.
class DeactivateStudentSheet extends StatelessWidget {
  const DeactivateStudentSheet({
    required this.student,
    required this.enrolledLabel,
    super.key,
  });

  final StudentSummary student;

  /// "4 Sep 2025".
  final String enrolledLabel;

  /// Resolves to true when the student is to be deactivated.
  static Future<bool?> show(
    BuildContext context, {
    required StudentSummary student,
    required String enrolledLabel,
  }) => showAppSheet<bool>(
    context,
    builder: (_) =>
        DeactivateStudentSheet(student: student, enrolledLabel: enrolledLabel),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

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
                  StudentsStrings.deactivateTitle(student.firstName),
                  style: AppTextStyles.detailTitle.copyWith(color: c.ink),
                ),
                Text(
                  StudentsStrings.deactivateSub(
                    student.classroomName,
                    enrolledLabel,
                  ),
                  style: StudentsTextStyles.sheetSub.copyWith(color: c.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StudentsSizes.filterSectionGap,
          children: <Widget>[_costs(c), _warning(c)],
        ),
      ),
      footer: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSizes.sheetFooterGap,
          children: <Widget>[
            DestructiveKey(
              label: StudentsStrings.deactivateKey(student.firstName),
              padding: StudentsSizes.deactivateKeyPad,
              onTap: () => Navigator.of(context).pop(true),
            ),
            Semantics(
              button: true,
              label: StudentsStrings.keepActive,
              child: Pressable.surface(
                onTap: () => Navigator.of(context).pop(false),
                child: Text(
                  StudentsStrings.keepActive,
                  textAlign: TextAlign.center,
                  style: StudentsTextStyles.quietAction.copyWith(color: c.ink2),
                ),
              ),
            ),
            Text(
              StudentsStrings.deleteFootnote,
              textAlign: TextAlign.center,
              style: StudentsTextStyles.footnote.copyWith(color: c.ink3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _costs(Colourway c) => AppCard(
    padding: StudentsSizes.costCardPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StudentsSizes.costRowGap,
      children: <Widget>[
        const SectionEyebrow(label: StudentsStrings.whatChanges),
        _cost(c, StudentsStrings.costRoster, StudentsStrings.costRosterValue),
        _cost(
          c,
          StudentsStrings.costActivities,
          StudentsStrings.costActivitiesValue,
        ),
        _cost(
          c,
          StudentsStrings.costKept,
          StudentsStrings.costKeptValue,
          isKept: true,
        ),
      ],
    ),
  );

  Widget _cost(
    Colourway c,
    String label,
    String value, {
    bool isKept = false,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSizes.rowGap,
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          style: StudentsTextStyles.detailValue.copyWith(color: c.ink2),
        ),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: StudentsTextStyles.costValue.copyWith(
            color: isKept ? c.successFg : c.ink,
          ),
        ),
      ),
    ],
  );

  /// A caution rather than a danger: nothing here is destructive yet.
  Widget _warning(Colourway c) => SurfaceBox(
    surface: AppSurfaces.tile(c, fill: c.staffBg, line: c.staffLine),
    padding: StudentsSizes.notePad,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: StudentsSizes.noteGap,
      children: <Widget>[
        Icon(
          AppIcons.alertTriangle,
          size: StudentsSizes.noteGlyph,
          color: c.staffFg,
        ),
        Expanded(
          child: Text(
            StudentsStrings.deactivateWarning,
            style: AppTextStyles.noteText.copyWith(color: c.staffFg),
          ),
        ),
      ],
    ),
  );
}
