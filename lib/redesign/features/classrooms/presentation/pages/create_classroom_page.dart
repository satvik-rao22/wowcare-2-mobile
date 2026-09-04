import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/create_classroom_cubit.dart';

/// Added. The frames stop at "Create a classroom" on 7a and 7b, so this is
/// the smallest step that key can lead to: the four fields the classroom
/// record needs, validated, then back to the floor.
///
/// Students per staff is a number, and it is the only place in the module a
/// ratio is typed: everywhere it is read back it is counts and a two-state
/// pill.
class CreateClassroomPage extends StatelessWidget {
  const CreateClassroomPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<CreateClassroomCubit>(
    create: (_) => redesignLocator<CreateClassroomCubit>(),
    child: const _CreateClassroomView(),
  );
}

class _CreateClassroomView extends StatelessWidget {
  const _CreateClassroomView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateClassroomCubit>();

    return BlocListener<CreateClassroomCubit, CreateClassroomState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (!state.isSaved) return;
        showAppToast(
          context,
          ClassroomsStrings.classroomCreated(state.created?.name ?? ''),
        );
        Navigator.of(context).pop();
      },
      child: BlocBuilder<CreateClassroomCubit, CreateClassroomState>(
        builder: (context, state) => ScreenScaffold(
          header: const AppHeaderBar(
            title: ClassroomsStrings.newClassroomTitle,
            isDetail: true,
            leading: BackKey(),
          ),
          bottomBar: _footer(context, state, cubit),
          scrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ClassroomsSizes.formGap,
            children: <Widget>[
              AppTextField(
                label: ClassroomsStrings.fieldName,
                hintText: ClassroomsStrings.fieldNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                errorText: state.errorFor(ClassroomField.name),
                onChanged: cubit.setName,
              ),
              Row(
                spacing: ClassroomsSizes.formRowGap,
                children: <Widget>[
                  Expanded(
                    child: _NumberField(
                      label: ClassroomsStrings.fieldAgeFrom,
                      hintText: ClassroomsStrings.fieldAgeHint,
                      errorText: state.errorFor(ClassroomField.ageFrom),
                      onChanged: cubit.setAgeFrom,
                    ),
                  ),
                  Expanded(
                    child: _NumberField(
                      label: ClassroomsStrings.fieldAgeTo,
                      hintText: ClassroomsStrings.fieldAgeHint,
                      errorText: state.errorFor(ClassroomField.ageTo),
                      onChanged: cubit.setAgeTo,
                    ),
                  ),
                ],
              ),
              _NumberField(
                label: ClassroomsStrings.fieldCapacity,
                hintText: ClassroomsStrings.fieldCapacityHint,
                isRequired: true,
                errorText: state.errorFor(ClassroomField.capacity),
                onChanged: cubit.setCapacity,
              ),
              _NumberField(
                label: ClassroomsStrings.fieldRatio,
                hintText: ClassroomsStrings.fieldRatioHint,
                isRequired: true,
                helpText: ClassroomsStrings.fieldRatioHelp,
                errorText: state.errorFor(ClassroomField.studentsPerStaff),
                onChanged: cubit.setStudentsPerStaff,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(
    BuildContext context,
    CreateClassroomState state,
    CreateClassroomCubit cubit,
  ) {
    final c = context.colours;

    // The bottom slot hands its child a loose height as tall as the screen,
    // and a key centres its face with an `Align`, which would take all of it.
    // `IntrinsicHeight` holds the row to the height its keys actually need.
    return IntrinsicHeight(
      child: Container(
        padding: ClassroomsSizes.footerPad.copyWith(
          bottom: ClassroomsSizes.footerPad.bottom + context.safeArea.bottom,
        ),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.barLine)),
        ),
        child: PrimaryKey(
          label: ClassroomsStrings.saveClassroom,
          isLoading: state.isSaving,
          padding: ClassroomsSizes.footerKeyPad,
          onTap: () => unawaited(cubit.submit()),
        ),
      ),
    );
  }
}

/// A field that only takes whole numbers: an age bound, a capacity, a ratio.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.onChanged,
    this.hintText,
    this.helpText,
    this.errorText,
    this.isRequired = false,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? helpText;
  final String? errorText;
  final bool isRequired;

  @override
  Widget build(BuildContext context) => AppTextField(
    label: label,
    hintText: hintText,
    helpText: helpText,
    errorText: errorText,
    isRequired: isRequired,
    keyboardType: TextInputType.number,
    inputFormatters: <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
    ],
    onChanged: onChanged,
  );
}
