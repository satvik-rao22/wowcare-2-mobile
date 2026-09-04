import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/students/cubit/add_student_cubit.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/add_student_details_step.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/add_student_guardian_step.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/add_student_schedule_step.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/docked_bar.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/sibling_link_sheet.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/wizard_step_list.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// 5d. Adding a student, in three steps.
///
/// Full screen over the tab bar, because a wizard is a job you are in the
/// middle of and the five slots would offer a way out of it that loses the
/// answers. The close key is the way out, and it is the only one.
class AddStudentPage extends StatelessWidget {
  const AddStudentPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<AddStudentCubit>(
    create: (_) {
      final cubit = redesignLocator<AddStudentCubit>();
      unawaited(cubit.load());
      return cubit;
    },
    child: const _AddStudentView(),
  );
}

class _AddStudentView extends StatelessWidget {
  const _AddStudentView();

  static const List<WizardStep> _steps = <WizardStep>[
    WizardStep(
      title: StudentsStrings.stepStudent,
      note: StudentsStrings.stepStudentNote,
    ),
    WizardStep(
      title: StudentsStrings.stepGuardian,
      note: StudentsStrings.stepGuardianNote,
      isOptional: true,
    ),
    WizardStep(
      title: StudentsStrings.stepSchedule,
      note: StudentsStrings.stepScheduleNote,
      isOptional: true,
    ),
  ];

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AddStudentCubit, AddStudentState>(
        listenWhen: (previous, current) =>
            previous.siblings != current.siblings ||
            previous.status != current.status,
        listener: _onChange,
        builder: (context, state) {
          final cubit = context.read<AddStudentCubit>();

          return ScreenScaffold(
            header: AppHeaderBar(
              title: StudentsStrings.addTitle,
              isDetail: true,
              leading: IconKey(
                icon: AppIcons.close,
                size: AppSizes.backKey,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            bodyPadding: EdgeInsets.zero,
            bottomBar: _Footer(state: state),
            body: state.isLoadingOptions
                ? const LoadingState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: StudentsSizes.stepsPad,
                        child: WizardStepList(
                          steps: _steps,
                          current: state.step,
                          onSelect: cubit.goToStep,
                        ),
                      ),
                      Expanded(child: _step(state)),
                    ],
                  ),
          );
        },
      );

  Widget _step(AddStudentState state) => switch (state.step) {
    1 => AddStudentDetailsStep(state: state),
    2 => AddStudentGuardianStep(state: state),
    _ => AddStudentScheduleStep(state: state),
  };

  Future<void> _onChange(BuildContext context, AddStudentState state) async {
    final cubit = context.read<AddStudentCubit>();

    if (state.isSaved) {
      showAppToast(
        context,
        StudentsStrings.studentAdded(state.saved?.fullName ?? ''),
      );
      Navigator.of(context).pop();
      return;
    }
    if (state.hasFailed) {
      showAppToast(context, StudentsStrings.saveError, tone: ToastTone.error);
      cubit.clearFailure();
      return;
    }
    if (state.siblings.isEmpty) return;

    final sibling = await SiblingLinkSheet.show(
      context,
      candidates: state.siblings,
    );
    if (sibling == null) {
      cubit.dismissSiblings();
    } else {
      cubit.linkSibling(sibling);
    }
  }
}

/// Back, the one pink key, and the quiet way past an optional step.
class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final AddStudentState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddStudentCubit>();
    final c = context.colours;

    return DockedBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudentsSizes.footerGap,
        children: <Widget>[
          Row(
            spacing: StudentsSizes.footerGap,
            children: <Widget>[
              if (state.canGoBack)
                SecondaryKey(
                  label: AppStrings.back,
                  expand: false,
                  padding: StudentsSizes.dockSubKeyPad,
                  onTap: cubit.back,
                ),
              Expanded(
                child: PrimaryKey(
                  label: state.primaryLabel,
                  isLoading: state.isBusy,
                  padding: StudentsSizes.wizardPrimaryPad,
                  onTap: () => unawaited(cubit.next()),
                ),
              ),
            ],
          ),
          if (state.canSkip)
            Semantics(
              button: true,
              label: state.skipLabel,
              child: Pressable.surface(
                onTap: () => unawaited(cubit.skip()),
                child: Text(
                  state.skipLabel,
                  textAlign: TextAlign.center,
                  style: StudentsTextStyles.secondaryAction.copyWith(
                    color: c.ink2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
