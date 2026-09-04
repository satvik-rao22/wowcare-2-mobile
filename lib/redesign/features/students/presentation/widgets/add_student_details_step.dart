import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/features/students/cubit/add_student_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/choice_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/date_field.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// Step one of 5d: the only step that has to be filled in, because it is the
/// one that writes the student.
class AddStudentDetailsStep extends StatelessWidget {
  const AddStudentDetailsStep({required this.state, super.key});

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
                const FieldLabel(text: StudentsStrings.fieldStatus),
                ChoiceRow<StudentStatus>(
                  value: draft.status,
                  onChanged: (status) =>
                      cubit.edit(draft.copyWith(status: status)),
                  choices: const <Choice<StudentStatus>>[
                    Choice<StudentStatus>(
                      value: StudentStatus.active,
                      label: StudentsStrings.statusActive,
                    ),
                    Choice<StudentStatus>(
                      value: StudentStatus.upcoming,
                      label: StudentsStrings.statusUpcoming,
                    ),
                  ],
                ),
              ],
            ),
            AppTextField(
              label: StudentsStrings.firstName,
              isRequired: true,
              textCapitalization: TextCapitalization.words,
              errorText: state.errorFor(StudentField.firstName),
              onChanged: (value) =>
                  cubit.edit(draft.copyWith(firstName: value)),
            ),
            AppTextField(
              label: StudentsStrings.lastName,
              isRequired: true,
              textCapitalization: TextCapitalization.words,
              errorText: state.errorFor(StudentField.lastName),
              onChanged: (value) => cubit.edit(draft.copyWith(lastName: value)),
            ),
            DropdownField(
              label: StudentsStrings.classroom,
              isRequired: true,
              value: draft.classroomName,
              placeholder: StudentsStrings.pickClassroom,
              errorText: state.errorFor(StudentField.classroom),
              onTap: () => unawaited(_pickClassroom(context)),
            ),
            DateField(
              label: StudentsStrings.birthDate,
              isRequired: draft.status == StudentStatus.active,
              value: draft.dateOfBirth,
              helpText: StudentsStrings.birthDateHint,
              errorText: state.errorFor(StudentField.birthDate),
              onChanged: (date) =>
                  cubit.edit(draft.copyWith(dateOfBirth: date)),
            ),
            if (draft.status == StudentStatus.upcoming)
              DateField(
                label: StudentsStrings.schoolStartDate,
                isRequired: true,
                value: draft.schoolStartDate,
                helpText: StudentsStrings.schoolStartHint,
                errorText: state.errorFor(StudentField.schoolStartDate),
                onChanged: (date) =>
                    cubit.edit(draft.copyWith(schoolStartDate: date)),
              ),
            DropdownField(
              label: StudentsStrings.linkSibling,
              value: draft.siblingLabel,
              placeholder: StudentsStrings.noSiblingYet,
              helpText: StudentsStrings.siblingHint,
              leadingIcon: AppIcons.users,
              onTap: () => unawaited(_pickSibling(context)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickClassroom(BuildContext context) async {
    final cubit = context.read<AddStudentCubit>();
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StudentsStrings.pickClassroom,
      selected: state.draft.classroomName,
      options: <SelectOption<String>>[
        for (final name in state.classrooms)
          SelectOption<String>(value: name, label: name),
      ],
    );
    if (picked != null) {
      cubit.edit(state.draft.copyWith(classroomName: picked));
    }
  }

  /// Only students who already share the last name are offered, which is the
  /// same rule the wizard's own check uses.
  Future<void> _pickSibling(BuildContext context) async {
    final cubit = context.read<AddStudentCubit>();
    final matches = state.siblings;
    if (matches.isEmpty) {
      cubit.edit(state.draft.copyWith(clearSibling: true));
      return;
    }

    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StudentsStrings.linkSibling,
      selected: state.draft.siblingId,
      options: <SelectOption<String>>[
        for (final sibling in matches)
          SelectOption<String>(
            value: sibling.id,
            label: sibling.fullName,
            subtitle: sibling.classroomName,
          ),
      ],
    );
    if (picked == null) return;

    final sibling = matches.firstWhere((s) => s.id == picked);
    cubit.edit(
      state.draft.copyWith(
        siblingId: sibling.id,
        siblingLabel: '${sibling.fullName} · ${sibling.classroomName}',
      ),
    );
  }
}
