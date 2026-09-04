import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/multi_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/staff/cubit/create_staff_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/choice_row.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/shift_editor_card.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/wizard_steps.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6d, Add Admin or Staff. Three steps, the third of them optional, over the
/// tab bar rather than inside it.
///
/// Step two has no PIN field. The Sign-In PIN is issued with the record and
/// read back on 6c; the endpoint that serves it is a read, so the app never
/// offers to set or change one.
class AddStaffPage extends StatelessWidget {
  const AddStaffPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<CreateStaffCubit>(
    create: (_) {
      final cubit = redesignLocator<CreateStaffCubit>();
      unawaited(cubit.load());
      return cubit;
    },
    child: const _AddStaffView(),
  );
}

class _AddStaffView extends StatelessWidget {
  const _AddStaffView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateStaffCubit>();

    return BlocListener<CreateStaffCubit, CreateStaffState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.isFailed) {
          showAppToast(
            context,
            AppStrings.somethingWentWrong,
            tone: ToastTone.error,
          );
          return;
        }
        if (!state.isSaved) return;
        showAppToast(context, StaffStrings.added(state.created?.name ?? ''));
        Navigator.of(context).pop(state.created);
      },
      child: BlocBuilder<CreateStaffCubit, CreateStaffState>(
        builder: (context, state) => ScreenScaffold(
          header: AppHeaderBar(
            title: StaffStrings.addStaff,
            isDetail: true,
            leading: IconKey(
              icon: AppIcons.close,
              size: AppSizes.backKey,
              semanticLabel: AppStrings.close,
              onTap: Navigator.of(context).pop,
            ),
          ),
          bottomBar: _Footer(state: state, cubit: cubit),
          scrollable: true,
          bodyPadding: StaffSizes.wizardBodyPad,
          body: state.isLoading
              ? const LoadingState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: StaffSizes.sectionGap,
                  children: <Widget>[
                    WizardSteps(
                      currentStep: state.step,
                      onSelect: cubit.goToStep,
                    ),
                    _Step(state: state, cubit: cubit),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Whichever of the three steps is showing.
class _Step extends StatelessWidget {
  const _Step({required this.state, required this.cubit});

  final CreateStaffState state;
  final CreateStaffCubit cubit;

  @override
  Widget build(BuildContext context) => switch (state.step) {
    1 => _NameAndContact(state: state, cubit: cubit),
    2 => _WhatTheyCanDo(state: state, cubit: cubit),
    _ => _TheirShifts(state: state, cubit: cubit),
  };
}

/// Step one: who they are and how the invitation reaches them.
class _NameAndContact extends StatelessWidget {
  const _NameAndContact({required this.state, required this.cubit});

  final CreateStaffState state;
  final CreateStaffCubit cubit;

  static const List<StaffStatus> _statuses = <StaffStatus>[
    StaffStatus.active,
    StaffStatus.upcoming,
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StaffSizes.wizardFieldGap,
    children: <Widget>[
      _Labelled(
        label: StaffStrings.status,
        child: ChoiceRow(
          labels: <String>[
            for (final status in _statuses) StaffStrings.statusLabel(status),
          ],
          selectedIndex: _statuses.indexOf(state.draft.status),
          onSelect: (index) => cubit.setStatus(_statuses[index]),
        ),
      ),
      AppTextField(
        label: StaffStrings.firstName,
        isRequired: true,
        textCapitalization: TextCapitalization.words,
        errorText: state.errorFor(StaffField.firstName),
        onChanged: cubit.setFirstName,
      ),
      AppTextField(
        label: StaffStrings.lastName,
        isRequired: true,
        textCapitalization: TextCapitalization.words,
        errorText: state.errorFor(StaffField.lastName),
        onChanged: cubit.setLastName,
      ),
      AppTextField(
        label: StaffStrings.workEmail,
        isRequired: true,
        helpText: StaffStrings.workEmailHint,
        keyboardType: TextInputType.emailAddress,
        errorText: state.errorFor(StaffField.email),
        onChanged: cubit.setEmail,
      ),
      AppTextField(
        label: StaffStrings.phone,
        isRequired: true,
        keyboardType: TextInputType.phone,
        errorText: state.errorFor(StaffField.phone),
        onChanged: cubit.setPhone,
      ),
    ],
  );
}

/// Step two: the designation, the role, and the classrooms that follow from
/// it. An Admin covers every classroom, so the two classroom fields are a
/// staff member's only.
class _WhatTheyCanDo extends StatelessWidget {
  const _WhatTheyCanDo({required this.state, required this.cubit});

  final CreateStaffState state;
  final CreateStaffCubit cubit;

  static const List<StaffRole> _roles = <StaffRole>[
    StaffRole.staff,
    StaffRole.admin,
  ];

  Future<void> _pickDesignation(BuildContext context) async {
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StaffStrings.pickDesignation,
      selected: state.draft.designation,
      options: <SelectOption<String>>[
        for (final designation in state.designations)
          SelectOption<String>(value: designation, label: designation),
      ],
    );
    if (picked != null) cubit.setDesignation(picked);
  }

  Future<void> _pickPrimary(BuildContext context) async {
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StaffStrings.pickClassroom,
      selected: state.draft.primaryClassroom,
      options: <SelectOption<String>>[
        for (final classroom in state.options.classrooms)
          SelectOption<String>(value: classroom, label: classroom),
      ],
    );
    if (picked != null) cubit.setPrimaryClassroom(picked);
  }

  Future<void> _pickAllowed(BuildContext context) async {
    final picked = await MultiSelectSheet.show<String>(
      context,
      title: StaffStrings.pickClassrooms,
      subtitle: StaffStrings.allowedHint,
      selected: state.draft.effectiveAllowed,
      options: <SelectOption<String>>[
        for (final classroom in state.options.classrooms)
          SelectOption<String>(value: classroom, label: classroom),
      ],
    );
    if (picked != null) cubit.setAllowedClassrooms(picked);
  }

  Future<void> _pickTags(BuildContext context) async {
    final picked = await MultiSelectSheet.show<String>(
      context,
      title: StaffStrings.pickJobTags,
      selected: state.draft.jobTags,
      options: <SelectOption<String>>[
        for (final tag in state.options.jobTags)
          SelectOption<String>(value: tag, label: tag),
      ],
    );
    if (picked != null) cubit.setJobTags(picked);
  }

  @override
  Widget build(BuildContext context) {
    final allowed = state.draft.effectiveAllowed;
    final tags = state.draft.jobTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.wizardFieldGap,
      children: <Widget>[
        DropdownField(
          label: StaffStrings.designation,
          isRequired: true,
          value: state.draft.designation,
          placeholder: StaffStrings.pickDesignation,
          errorText: state.errorFor(StaffField.designation),
          onTap: () => unawaited(_pickDesignation(context)),
        ),
        _Labelled(
          label: StaffStrings.role,
          hint: StaffStrings.roleHint,
          child: ChoiceRow(
            labels: <String>[
              for (final role in _roles) StaffStrings.roleLabel(role),
            ],
            selectedIndex: _roles.indexOf(state.draft.role),
            onSelect: (index) => cubit.setRole(_roles[index]),
          ),
        ),
        if (state.needsClassrooms) ...<Widget>[
          DropdownField(
            label: StaffStrings.primaryClassroom,
            isRequired: true,
            value: state.draft.primaryClassroom,
            placeholder: StaffStrings.pickClassroom,
            errorText: state.errorFor(StaffField.primaryClassroom),
            onTap: () => unawaited(_pickPrimary(context)),
          ),
          DropdownField(
            label: StaffStrings.allowedClassrooms,
            isRequired: true,
            value: allowed.isEmpty ? null : allowed.join(', '),
            placeholder: StaffStrings.pickClassrooms,
            helpText: StaffStrings.allowedHint,
            errorText: state.errorFor(StaffField.allowedClassrooms),
            onTap: () => unawaited(_pickAllowed(context)),
          ),
        ],
        DropdownField(
          label: StaffStrings.jobTag,
          value: tags.isEmpty ? null : tags.join(', '),
          placeholder: StaffStrings.pickJobTags,
          onTap: () => unawaited(_pickTags(context)),
        ),
      ],
    );
  }
}

/// Step three: the week. Skippable, because a record without a schedule is a
/// perfectly good record and the shifts can be set later.
class _TheirShifts extends StatelessWidget {
  const _TheirShifts({required this.state, required this.cubit});

  final CreateStaffState state;
  final CreateStaffCubit cubit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StaffSizes.wizardFieldGap,
    children: <Widget>[
      _Labelled(
        label: StaffStrings.sameShiftEveryDay,
        child: ChoiceRow(
          labels: const <String>[StaffStrings.yes, StaffStrings.no],
          selectedIndex: state.draft.sameShiftEveryDay ? 0 : 1,
          onSelect: (index) => cubit.setSameShiftEveryDay(value: index == 0),
        ),
      ),
      ShiftEditorCard(
        week: state.draft.week,
        errorText: state.errorFor(StaffField.shifts),
        onChanged: cubit.setShift,
        onCopyToAllDays: cubit.copyToAllDays,
      ),
    ],
  );
}

/// A label over something that is not a field: the two-up pick-one rows.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child, this.hint});

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.fieldGap,
      children: <Widget>[
        FieldLabel(text: label),
        child,
        if (hint != null)
          Text(hint!, style: StaffTextStyles.sheetNote.copyWith(color: c.ink3)),
      ],
    );
  }
}

/// The wizard's docked keys: Back where there is one, the one pink key, and
/// on the last step the skip and the line saying what saving does.
class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.cubit});

  final CreateStaffState state;
  final CreateStaffCubit cubit;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    // The bottom slot hands its child a loose height as tall as the screen,
    // and a key centres its face with an `Align`, which would take all of it.
    // `IntrinsicHeight` holds the column to the height its keys actually need.
    return IntrinsicHeight(
      child: Container(
        padding: StaffSizes.wizardFooterPad.copyWith(
          bottom: StaffSizes.wizardFooterPad.bottom + context.safeArea.bottom,
        ),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.barLine)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StaffSizes.wizardFooterGap,
          children: <Widget>[
            Row(
              spacing: StaffSizes.wizardFooterGap,
              children: <Widget>[
                if (state.hasBack)
                  SecondaryKey(
                    label: AppStrings.back,
                    expand: false,
                    padding: StaffSizes.backKeyPad,
                    onTap: cubit.back,
                  ),
                Expanded(
                  child: PrimaryKey(
                    label: _primaryLabel(),
                    isLoading: state.isSaving,
                    onTap: () => unawaited(cubit.next()),
                  ),
                ),
              ],
            ),
            if (state.canSkip)
              Center(
                child: TextLink(
                  label: StaffStrings.skipShifts,
                  color: c.ink2,
                  style: StaffTextStyles.wizardSkip,
                  onTap: () => unawaited(cubit.skipShifts()),
                ),
              ),
            if (state.isLastStep)
              Text(
                StaffStrings.inviteNote,
                style: StaffTextStyles.sheetNote.copyWith(color: c.ink3),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  String _primaryLabel() => switch (state.step) {
    1 => StaffStrings.nextWhatTheyCanDo,
    2 => StaffStrings.nextTheirShifts,
    _ => StaffStrings.saveAndInvite(state.draft.firstName.trim()),
  };
}
