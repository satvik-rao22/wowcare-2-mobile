import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/core/widgets/inline_alert.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/features/students/cubit/edit_student_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/choice_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/date_field.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/docked_bar.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/tag_editor_field.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// 5e. Fixing a record that is already on the roster.
///
/// The form opens on the record as it stands. Save checks it, and once it has
/// been checked the messages stay live, so a field goes quiet the moment it
/// is right rather than on the next attempt.
class EditStudentPage extends StatelessWidget {
  const EditStudentPage({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context) => BlocProvider<EditStudentCubit>(
    create: (_) {
      final cubit = redesignLocator<EditStudentCubit>(param1: studentId);
      unawaited(cubit.load());
      return cubit;
    },
    child: const _EditStudentView(),
  );
}

class _EditStudentView extends StatelessWidget {
  const _EditStudentView();

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<EditStudentCubit, EditStudentState>(
    listenWhen: (previous, current) =>
        previous.isSaved != current.isSaved ||
        previous.hasSaveFailed != current.hasSaveFailed,
    listener: (context, state) {
      if (state.isSaved) {
        showAppToast(context, StudentsStrings.changesSaved(state.firstName));
        Navigator.of(context).pop();
      } else if (state.hasSaveFailed) {
        showAppToast(context, StudentsStrings.saveError, tone: ToastTone.error);
        context.read<EditStudentCubit>().clearFailure();
      }
    },
    builder: (context, state) {
      if (state.isFailed) {
        return ScreenScaffold(
          body: Center(
            child: ErrorState(
              message: StudentsStrings.profileLoadError,
              onRetry: () => unawaited(context.read<EditStudentCubit>().load()),
            ),
          ),
        );
      }

      return ScreenScaffold(
        header: AppHeaderBar(
          title: StudentsStrings.editTitle(state.firstName),
          isDetail: true,
          leading: const BackKey(),
        ),
        bodyPadding: EdgeInsets.zero,
        bottomBar: _Footer(state: state),
        body: state.isLoading ? const LoadingState() : _Form(state: state),
      );
    },
  );
}

/// Every field 5e edits, with the summary alert above them once Save has
/// found something wrong.
class _Form extends StatefulWidget {
  const _Form({required this.state});

  final EditStudentState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _notes;

  EditStudentState get state => widget.state;

  @override
  void initState() {
    super.initState();
    // The form is seeded once, from the record as it was loaded. After that
    // the fields are the source of truth and the cubit follows them.
    final draft = state.draft;
    _firstName = TextEditingController(text: draft.firstName);
    _lastName = TextEditingController(text: draft.lastName);
    _notes = TextEditingController(text: draft.notes);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditStudentCubit>();
    final draft = state.draft;

    return ListView(
      padding: StudentsSizes.formPad,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StudentsSizes.editFieldGap,
          children: <Widget>[
            if (state.hasProblems)
              InlineAlert(
                message: StudentsStrings.problemsSummary(state.errors.length),
              ),
            AppTextField(
              label: StudentsStrings.firstName,
              isRequired: true,
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              hintText: StudentsStrings.empty,
              errorText: state.errorFor(StudentField.firstName),
              onChanged: (value) =>
                  cubit.edit(draft.copyWith(firstName: value)),
            ),
            AppTextField(
              label: StudentsStrings.lastName,
              isRequired: true,
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              errorText: state.errorFor(StudentField.lastName),
              onChanged: (value) => cubit.edit(draft.copyWith(lastName: value)),
            ),
            DateField(
              label: StudentsStrings.birthDate,
              isRequired: draft.status == StudentStatus.active,
              value: draft.dateOfBirth,
              errorText: state.errorFor(StudentField.birthDate),
              onChanged: (date) =>
                  cubit.edit(draft.copyWith(dateOfBirth: date)),
            ),
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
                    Choice<StudentStatus>(
                      value: StudentStatus.inactive,
                      label: StudentsStrings.statusInactive,
                    ),
                  ],
                ),
              ],
            ),
            DropdownField(
              label: StudentsStrings.classroom,
              isRequired: true,
              value: draft.classroomName,
              placeholder: StudentsStrings.pickClassroom,
              helpText: StudentsStrings.classroomMoveHint,
              errorText: state.errorFor(StudentField.classroom),
              onTap: () => unawaited(_pickClassroom(context)),
            ),
            TagEditorField(
              tags: draft.tags,
              options: state.tagNames,
              onChanged: (tags) => cubit.edit(draft.copyWith(tags: tags)),
            ),
            AppTextField(
              label: StudentsStrings.notes,
              controller: _notes,
              hintText: StudentsStrings.notesHint,
              maxLines: _notesLines,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) => cubit.edit(draft.copyWith(notes: value)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickClassroom(BuildContext context) async {
    final cubit = context.read<EditStudentCubit>();
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

  static const int _notesLines = 3;
}

/// Cancel, and the one pink key. Save is off while anything is wrong, which
/// is the frame's own state.
class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final EditStudentState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditStudentCubit>();

    return DockedBar(
      child: Row(
        spacing: StudentsSizes.footerGap,
        children: <Widget>[
          SecondaryKey(
            label: AppStrings.cancel,
            expand: false,
            padding: StudentsSizes.dockSubKeyPad,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: PrimaryKey(
              label: StudentsStrings.saveChanges,
              enabled: state.canSave,
              isLoading: state.isSaving,
              padding: StudentsSizes.wizardPrimaryPad,
              onTap: () => unawaited(cubit.save()),
            ),
          ),
        ],
      ),
    );
  }
}
