import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/features/students/cubit/add_student_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/choice_row.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// Step two of 5d: linking a parent, or creating one.
///
/// Optional, because a student can be on the roster before the paperwork
/// catches up. Legal custody is asked here because it is the one answer that
/// changes what happens at the door.
class AddStudentGuardianStep extends StatelessWidget {
  const AddStudentGuardianStep({required this.state, super.key});

  final AddStudentState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddStudentCubit>();
    final draft = state.draft;
    final isExisting = draft.guardianSource == GuardianSource.existing;

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
                const FieldLabel(text: StudentsStrings.guardianFrom),
                ChoiceRow<GuardianSource>(
                  value: draft.guardianSource,
                  onChanged: (source) =>
                      cubit.edit(draft.copyWith(guardianSource: source)),
                  choices: const <Choice<GuardianSource>>[
                    Choice<GuardianSource>(
                      value: GuardianSource.existing,
                      label: StudentsStrings.existingGuardian,
                    ),
                    Choice<GuardianSource>(
                      value: GuardianSource.create,
                      label: StudentsStrings.createGuardian,
                    ),
                  ],
                ),
              ],
            ),
            if (isExisting)
              DropdownField(
                label: StudentsStrings.guardianField,
                isRequired: true,
                value: draft.guardianLabel,
                placeholder: StudentsStrings.pickGuardian,
                errorText: state.errorFor(StudentField.guardian),
                leadingIcon: AppIcons.user,
                onTap: () => unawaited(_pickGuardian(context)),
              )
            else ...<Widget>[
              AppTextField(
                label: StudentsStrings.guardianField,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                errorText: state.errorFor(StudentField.guardianName),
                onChanged: (value) =>
                    cubit.edit(draft.copyWith(guardianName: value)),
              ),
              AppTextField(
                label: StudentsStrings.email,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
                errorText: state.errorFor(StudentField.guardianEmail),
                onChanged: (value) =>
                    cubit.edit(draft.copyWith(guardianEmail: value)),
              ),
              AppTextField(
                label: StudentsStrings.phone,
                isRequired: true,
                keyboardType: TextInputType.phone,
                errorText: state.errorFor(StudentField.guardianPhone),
                onChanged: (value) =>
                    cubit.edit(draft.copyWith(guardianPhone: value)),
              ),
            ],
            DropdownField(
              label: StudentsStrings.relation,
              isRequired: true,
              value: draft.relation,
              placeholder: StudentsStrings.pickRelation,
              errorText: state.errorFor(StudentField.relation),
              onTap: () => unawaited(_pickRelation(context)),
            ),
            _yesNo(
              context,
              label: StudentsStrings.emergencyContact,
              value: draft.isEmergencyContact,
              onChanged: (yes) =>
                  cubit.edit(draft.copyWith(isEmergencyContact: yes)),
            ),
            _yesNo(
              context,
              label: StudentsStrings.legalCustody,
              value: draft.hasLegalCustody,
              helpText: StudentsStrings.custodyHint,
              onChanged: (yes) =>
                  cubit.edit(draft.copyWith(hasLegalCustody: yes)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _yesNo(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? helpText,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StudentsSizes.fieldGap,
    children: <Widget>[
      FieldLabel(text: label),
      ChoiceRow<bool>(
        value: value,
        onChanged: onChanged,
        choices: const <Choice<bool>>[
          Choice<bool>(value: true, label: StudentsStrings.yes),
          Choice<bool>(value: false, label: StudentsStrings.no),
        ],
      ),
      if (helpText != null) _Help(text: helpText),
    ],
  );

  Future<void> _pickGuardian(BuildContext context) async {
    final cubit = context.read<AddStudentCubit>();
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StudentsStrings.pickGuardian,
      searchable: true,
      selected: state.draft.guardianId,
      options: <SelectOption<String>>[
        for (final guardian in state.guardians)
          SelectOption<String>(
            value: guardian.id,
            label: guardian.name,
            subtitle: guardian.email,
          ),
      ],
    );
    if (picked == null) return;

    final guardian = state.guardians.firstWhere((g) => g.id == picked);
    cubit.edit(
      state.draft.copyWith(
        guardianId: guardian.id,
        guardianLabel: StudentsStrings.guardianOption(
          guardian.name,
          guardian.email,
        ),
      ),
    );
  }

  Future<void> _pickRelation(BuildContext context) async {
    final cubit = context.read<AddStudentCubit>();
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StudentsStrings.pickRelation,
      selected: state.draft.relation,
      options: <SelectOption<String>>[
        for (final relation in StudentsStrings.relations)
          SelectOption<String>(value: relation, label: relation),
      ],
    );
    if (picked != null) cubit.edit(state.draft.copyWith(relation: picked));
  }
}

/// The help line a `ChoiceRow` has no room for.
class _Help extends StatelessWidget {
  const _Help({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.fieldHelp.copyWith(color: context.colours.ink3),
  );
}
