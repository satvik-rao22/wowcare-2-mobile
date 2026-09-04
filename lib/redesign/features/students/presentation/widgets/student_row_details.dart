import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/attendance_label.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_tag_chip.dart';
import 'package:wowcare/redesign/features/students/students_formats.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// What an opened roster row shows (5a): today, the tags, the week, the two
/// dates, and the two keys.
///
/// Everything here is already on the roster row's own record, so opening a
/// row costs no fetch.
class StudentRowDetails extends StatelessWidget {
  const StudentRowDetails({
    required this.student,
    this.canWrite = false,
    this.onOpenProfile,
    this.onMoreActions,
    super.key,
  });

  final StudentSummary student;
  final bool canWrite;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StudentsSizes.detailGap,
      children: <Widget>[
        Container(height: AppSizes.hairline, color: c.divider),
        _line(
          c,
          StudentsStrings.attendanceToday,
          AttendanceLabel(
            status: student.attendance,
            timeLabel: student.attendanceTimeLabel,
          ),
        ),
        _tags(c),
        _schedule(c),
        _line(c, StudentsStrings.birthDate, _value(c, _dateOfBirth)),
        _line(
          c,
          StudentsStrings.movesClassroom,
          _value(c, student.movementLabel ?? StudentsStrings.noMovement),
        ),
        _keys(),
      ],
    );
  }

  String get _dateOfBirth => StudentsFormats.date(student.dateOfBirth);

  Widget _label(Colourway c, String text, {double? width}) => SizedBox(
    width: width,
    child: Text(
      text,
      style: StudentsTextStyles.fieldKey.copyWith(color: c.ink3),
    ),
  );

  Widget _value(Colourway c, String text) => Text(
    text,
    textAlign: TextAlign.end,
    style: StudentsTextStyles.detailValue.copyWith(color: c.ink),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  /// The label is measured first and the value takes what is left, so a long
  /// movement date shortens rather than running past the card.
  Widget _line(Colourway c, String label, Widget value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    spacing: AppSizes.rowGap,
    children: <Widget>[
      _label(c, label),
      Flexible(child: value),
    ],
  );

  Widget _tags(Colourway c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSizes.eyebrowMetaGap,
    children: <Widget>[
      _label(c, StudentsStrings.tags, width: StudentsSizes.detailLabelWidth),
      Expanded(
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: StudentsSizes.tagGap,
          runSpacing: StudentsSizes.tagGap,
          children: <Widget>[
            if (student.tags.isEmpty)
              const StudentTagChip(
                tag: StudentTag(label: StudentsStrings.noTags),
              )
            else
              for (final tag in student.tags) StudentTagChip(tag: tag),
          ],
        ),
      ),
    ],
  );

  Widget _schedule(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: StudentsSizes.tagGap,
    children: <Widget>[
      _label(c, StudentsStrings.schedule),
      Row(
        spacing: StudentsSizes.tagGap,
        children: <Widget>[
          for (final (i, day) in StudentsStrings.weekdays.indexed)
            Expanded(
              child: _DayChip(label: day, isOn: student.weekdays[i]),
            ),
        ],
      ),
      Text(
        student.scheduleLabel,
        style: StudentsTextStyles.footnote.copyWith(color: c.ink3),
      ),
    ],
  );

  Widget _keys() => Row(
    spacing: StudentsSizes.detailKeyGap,
    children: <Widget>[
      if (canWrite)
        Expanded(
          child: SecondaryKey(
            label: StudentsStrings.moreActions,
            onTap: onMoreActions,
          ),
        ),
      Expanded(
        child: PrimaryKey(
          label: StudentsStrings.openProfile,
          onTap: onOpenProfile,
        ),
      ),
    ],
  );
}

/// One weekday of the regular schedule, tinted on the days they come.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.isOn});

  final String label;
  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Opacity(
      opacity: isOn ? 1 : StudentsSizes.dayOffOpacity,
      child: SurfaceBox(
        surface: AppSurfaces.pill(fill: isOn ? c.studentBg : c.sub),
        padding: StudentsSizes.dayPad,
        alignment: Alignment.center,
        child: Text(
          label,
          style: StudentsTextStyles.tag.copyWith(
            color: isOn ? c.student : c.ink3,
          ),
        ),
      ),
    );
  }
}
