import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/features/students/cubit/add_student_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/choice_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/schedule_week_card.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// Step three of 5d: the days and the hours.
///
/// Optional, because a schedule can be set once the family has settled on
/// one. "Same times every day" is asked first because it is true most of the
/// time, and answering it fills the week in one move.
class AddStudentScheduleStep extends StatelessWidget {
  const AddStudentScheduleStep({required this.state, super.key});

  final AddStudentState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddStudentCubit>();
    final draft = state.draft;

    return ListView(
      padding: StudentsSizes.formPad,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StudentsSizes.formGap,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: StudentsSizes.fieldGap,
              children: <Widget>[
                const FieldLabel(text: StudentsStrings.sameTimes),
                ChoiceRow<bool>(
                  value: draft.sameTimesEveryDay,
                  onChanged: (same) {
                    cubit.edit(draft.copyWith(sameTimesEveryDay: same));
                    if (same) cubit.copyTimesToAllDays();
                  },
                  choices: const <Choice<bool>>[
                    Choice<bool>(value: true, label: StudentsStrings.yes),
                    Choice<bool>(value: false, label: StudentsStrings.no),
                  ],
                ),
              ],
            ),
            ScheduleWeekCard(
              week: draft.week,
              onCopyToAllDays: cubit.copyTimesToAllDays,
              onChanged: (entry) => cubit.edit(
                draft.copyWith(
                  week: <ScheduleEntry>[
                    for (final day in draft.week)
                      if (day.dayIndex == entry.dayIndex) entry else day,
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
