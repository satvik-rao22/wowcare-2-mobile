import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/inline_alert.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_family_cubit.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/student_pick_card.dart';

/// 2c. Which of a guardian's students are arriving, or leaving.
///
/// Both verbs sit in the footer, because a family that arrives together
/// sometimes leaves one behind. Whichever key is pressed records the time, the
/// method and who did it against the guardian whose PIN opened this screen.
class KioskFamilyPage extends StatelessWidget {
  const KioskFamilyPage({required this.args, super.key});

  final KioskFamilyArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider<KioskFamilyCubit>(
    create: (_) => redesignLocator<KioskFamilyCubit>(param1: args),
    child: const _KioskFamilyView(),
  );
}

class _KioskFamilyView extends StatelessWidget {
  const _KioskFamilyView();

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final cubit = context.read<KioskFamilyCubit>();

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: BlocConsumer<KioskFamilyCubit, KioskFamilyState>(
          listenWhen: (previous, current) =>
              previous.status != current.status && current.isRecorded,
          listener: (context, state) {
            showAppToast(
              context,
              state.isSigningIn
                  ? AuthStrings.studentsSignedIn(state.recordedCount)
                  : AuthStrings.studentsSignedOut(state.recordedCount),
            );
            context.pop();
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeaderBar.dashboard(
                title: state.isSigningIn
                    ? AuthStrings.whoIsArriving
                    : AuthStrings.whoIsLeaving,
                subline: AuthStrings.codeAcceptedAt(
                  state.result.acceptedAtLabel,
                ),
                leading: const BackKey(),
              ),
              Expanded(child: _body(context, state, cubit)),
              _footer(context, state, cubit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    KioskFamilyState state,
    KioskFamilyCubit cubit,
  ) => ListView(
    padding: AuthSizes.familyBodyPad,
    physics: const BouncingScrollPhysics(),
    children: <Widget>[
      const InlineAlert(
        message: AuthStrings.insideGeofence,
        tone: AlertTone.success,
        icon: AppIcons.mapPin,
      ),
      for (final student in state.students) ...<Widget>[
        const SizedBox(height: AuthSizes.familyGap),
        StudentPickCard(
          name: student.name,
          initials: student.initials,
          subline: _subline(student),
          attendance: student.attendance,
          selected: state.isSelected(student),
          enabled: state.canMove(student),
          onTap: () => cubit.toggle(student),
        ),
      ],
      const SizedBox(height: AuthSizes.familyGap),
      _recordedAgainst(context, state),
    ],
  );

  Widget _recordedAgainst(BuildContext context, KioskFamilyState state) {
    final c = context.colours;

    return AppWell(
      padding: AuthSizes.recordedPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AuthSizes.recordedGap,
        children: <Widget>[
          SectionEyebrow(
            label: AuthStrings.recordedAgainst,
            color: c.staffFg,
          ),
          Text(
            AuthStrings.recordedNote(state.result.personName),
            style: AppTextStyles.noteText.copyWith(color: c.ink2),
          ),
        ],
      ),
    );
  }

  Widget _footer(
    BuildContext context,
    KioskFamilyState state,
    KioskFamilyCubit cubit,
  ) {
    final c = context.colours;
    final primaryLabel = state.hasSelection
        ? (state.isSigningIn ? AppStrings.signIn : AppStrings.signOut)
        : AuthStrings.selectAStudent;

    return Padding(
      padding: AuthSizes.familyFooterPad,
      child: Column(
        spacing: AuthSizes.familyFooterGap,
        children: <Widget>[
          Row(
            spacing: AuthSizes.familyKeyGap,
            children: <Widget>[
              Expanded(
                child: SecondaryKey(
                  label: state.isSigningIn
                      ? AppStrings.signOut
                      : AppStrings.signIn,
                  padding: AppSizes.fieldPad,
                  onTap: () =>
                      cubit.setDirection(isSigningIn: !state.isSigningIn),
                ),
              ),
              Expanded(
                child: PrimaryKey(
                  label: primaryLabel,
                  isLoading: state.isRecording,
                  enabled: state.hasSelection,
                  padding: AppSizes.fieldPad,
                  onTap: () => unawaited(
                    cubit.record(isSigningIn: state.isSigningIn),
                  ),
                ),
              ),
            ],
          ),
          Text(
            AuthStrings.staffNote,
            textAlign: TextAlign.center,
            style: AppTextStyles.subLine.copyWith(color: c.ink3),
          ),
        ],
      ),
    );
  }

  /// "Sunflower · Not Marked", or "Willow · in since 8:06 AM".
  static String _subline(KioskStudent student) => AuthStrings.studentLine(
    student.classroomName,
    student.isSignedIn
        ? '${AppStrings.signedIn.toLowerCase()} ${student.timeLabel}'
        : _statusWord(student),
  );

  static String _statusWord(KioskStudent student) =>
      switch (student.attendance) {
        AttendanceStatus.signedIn => AppStrings.signedIn,
        AttendanceStatus.signedOut => AppStrings.signedOut,
        AttendanceStatus.absent => AppStrings.absent,
        AttendanceStatus.notMarked => AppStrings.notMarked,
      };
}
