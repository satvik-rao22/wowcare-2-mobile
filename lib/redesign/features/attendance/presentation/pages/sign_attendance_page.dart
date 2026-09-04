import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/inline_alert.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/cubit/sign_attendance_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_date_field.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_docked_bar.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_time_field.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/sign_person_tile.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/unexpected_sign_in_card.dart';

/// Sign In and Sign Out. The one way an attendance record is created, and the
/// one way it is closed.
///
/// Two fields and nothing else: Date, and Time. Everything above them is the
/// people it is about, each with a cross that takes them off. Who signed them
/// is never typed; it comes off whoever is signed in on this device.
class SignAttendancePage extends StatelessWidget {
  const SignAttendancePage({required this.args, super.key});

  final SignAttendanceArgs args;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;

    return BlocProvider<SignAttendanceCubit>(
      create: (_) {
        final cubit = redesignLocator<SignAttendanceCubit>(
          param1: args,
          param2: session.persona,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _SignView(),
    );
  }
}

class _SignView extends StatelessWidget {
  const _SignView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SignAttendanceCubit>();

    return BlocBuilder<SignAttendanceCubit, SignAttendanceState>(
      builder: (context, state) => ScreenScaffold(
        header: AppHeaderBar(
          title: state.kind.isSignIn
              ? AttendanceStrings.signInTitle
              : AttendanceStrings.signOutTitle,
          isDetail: true,
          leading: BackKey(onTap: () => context.pop()),
        ),
        bottomBar: state.isEmpty
            ? null
            : AttendanceDockedBar(
                child: PrimaryKey(
                  label: _confirmLabel(state),
                  enabled: state.canSubmit,
                  isLoading: state.isSubmitting,
                  onTap: () => unawaited(_submit(context, cubit)),
                ),
              ),
        scrollable: true,
        body: _body(context, state, cubit),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    SignAttendanceState state,
    SignAttendanceCubit cubit,
  ) {
    if (state.isLoading) return const LoadingState();
    if (state.isEmpty) {
      return Center(
        child: EmptyState(
          icon: AppIcons.users,
          title: AttendanceStrings.nobodyPicked,
          subtitle: AttendanceStrings.emptyDayBody,
          actionLabel: AppStrings.back,
          onAction: () => context.pop(),
        ),
      );
    }

    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AttendanceSizes.formGap,
      children: <Widget>[
        for (final person in state.people)
          SignPersonTile(
            record: person,
            onRemove: state.people.length > 1
                ? () => cubit.removePerson(person.id)
                : null,
          ),
        if (!state.isInsideGeofence)
          const InlineAlert(message: AttendanceStrings.geofenceBlocked),
        if (state.needsAcknowledgement)
          UnexpectedSignInCard(
            names: AttendanceFormats.names(<String>[
              for (final r in state.unexpected) r.fullName,
            ]),
            onAcknowledge: cubit.acknowledgeUnexpected,
          ),
        AttendanceDateField(
          label: AttendanceStrings.dateLabel,
          value: state.at,
          today: state.at,
          onChanged: cubit.setDate,
        ),
        AttendanceTimeField(
          label: AttendanceStrings.timeLabel,
          value: ClockTime.fromDateTime(state.at),
          onChanged: (picked) =>
              cubit.setTime(hour: picked.hour, minute: picked.minute),
        ),
        if (state.isInsideGeofence && !state.needsAcknowledgement)
          const InlineAlert(
            message: AttendanceStrings.geofenceInside,
            tone: AlertTone.success,
            icon: AppIcons.mapPin,
          ),
        Text(
          state.kind.isSignIn
              ? AttendanceStrings.signedInByNote
              : AttendanceStrings.signedOutByNote,
          style: AttendanceTextStyles.footnote.copyWith(color: c.ink3),
        ),
      ],
    );
  }

  String _confirmLabel(SignAttendanceState state) {
    final n = state.people.length;
    if (state.audience.isStudents) {
      return state.kind.isSignIn
          ? AttendanceStrings.signInConfirm(n)
          : AttendanceStrings.signOutConfirm(n);
    }
    return state.kind.isSignIn
        ? AttendanceStrings.signInStaffConfirm(n)
        : AttendanceStrings.signOutStaffConfirm(n);
  }

  Future<void> _submit(BuildContext context, SignAttendanceCubit cubit) async {
    final state = cubit.state;
    if (state.needsAcknowledgement) {
      showAppToast(context, AttendanceStrings.unexpectedNeeded);
      return;
    }

    final count = state.people.length;
    final done = await cubit.submit();
    if (!context.mounted) return;

    if (!done) {
      showAppToast(context, AttendanceStrings.saveError, tone: ToastTone.error);
      return;
    }
    showAppToast(
      context,
      state.kind.isSignIn
          ? AttendanceStrings.signedInToast(count)
          : AttendanceStrings.signedOutToast(count),
    );
    context.pop(true);
  }
}
