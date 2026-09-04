import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_schedule_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/note_well.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/shift_editor_card.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_state_view.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

/// The work schedule behind 6c's "Edit the week" key.
///
/// **Admin only.** A work schedule is what a staff member is contracted to,
/// not something they set for themselves, so a staff member reading their own
/// record gets the refusal here rather than the editor. The cubit refuses
/// before it fetches, so reaching the route by hand is refused too.
class StaffSchedulePage extends StatelessWidget {
  const StaffSchedulePage({required this.staffId, super.key});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final lens = StaffLens(
      persona: session.persona,
      viewerId: session.user?.id ?? '',
      viewerClassroom: session.user?.classroomName,
    );

    return BlocProvider<StaffScheduleCubit>(
      create: (_) {
        final cubit = redesignLocator<StaffScheduleCubit>(
          param1: staffId,
          param2: lens,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _StaffScheduleView(),
    );
  }
}

class _StaffScheduleView extends StatelessWidget {
  const _StaffScheduleView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StaffScheduleCubit>();

    return BlocListener<StaffScheduleCubit, StaffScheduleState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (!state.isSaved) return;
        showAppToast(context, StaffStrings.scheduleSaved);
        Navigator.of(context).pop();
      },
      child: BlocBuilder<StaffScheduleCubit, StaffScheduleState>(
        builder: (context, state) => ScreenScaffold(
          header: const AppHeaderBar(
            title: StaffStrings.scheduleTitle,
            isDetail: true,
            leading: BackKey(),
          ),
          bottomBar: state.isLoading || state.isDenied || state.isFailed
              ? null
              : _Footer(state: state, cubit: cubit),
          scrollable: true,
          body: _body(state, cubit),
        ),
      ),
    );
  }

  Widget _body(StaffScheduleState state, StaffScheduleCubit cubit) {
    if (state.isDenied) {
      return const Center(
        child: StaffStateView(
          mark: StaffStrings.dash,
          title: StaffStrings.scheduleDeniedTitle,
          message: StaffStrings.scheduleDeniedBody,
          tone: StaffStateTone.denied,
        ),
      );
    }
    if (state.isLoading) return const LoadingState();
    if (state.week.isEmpty) {
      return Center(
        child: ErrorState(
          title: StaffStrings.couldNotReachTitle,
          message: StaffStrings.couldNotReachBody,
          onRetry: () => unawaited(cubit.load()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.sectionGap,
      children: <Widget>[
        ShiftEditorCard(
          week: state.week,
          errorText: state.error,
          onChanged: cubit.setShift,
          onCopyToAllDays: cubit.copyToAllDays,
        ),
        NoteWell(
          title: StaffStrings.scheduleFor(state.name),
          body: StaffStrings.weekTotal(
            StaffStrings.duration(state.workedMinutes),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.cubit});

  final StaffScheduleState state;
  final StaffScheduleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    // The bottom slot hands its child a loose height as tall as the screen,
    // and a key centres its face with an `Align`, which would take all of it.
    // `IntrinsicHeight` holds the row to the height its key actually needs.
    return IntrinsicHeight(
      child: Container(
        padding: StaffSizes.dockedBarPad.copyWith(
          bottom: StaffSizes.dockedBarPad.bottom + context.safeArea.bottom,
        ),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.barLine)),
        ),
        child: PrimaryKey(
          label: StaffStrings.saveSchedule,
          isLoading: state.isSaving,
          onTap: () => unawaited(cubit.submit()),
        ),
      ),
    );
  }
}
