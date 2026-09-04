import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/segmented_control.dart';
import 'package:wowcare/redesign/features/students/cubit/student_profile_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/docked_bar.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/profile_tab_body.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/profile_tab_pills.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_profile_header.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// 5c. One student's record, every tab.
///
/// It covers the tab bar rather than sitting inside it: the record has its
/// own two keys at the foot, and a screen cannot carry two rows of chrome at
/// the bottom.
class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final persona = context.read<SessionCubit>().state.persona;

    return BlocProvider<StudentProfileCubit>(
      create: (_) {
        final cubit = redesignLocator<StudentProfileCubit>(
          param1: studentId,
          param2: persona,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _StudentProfileView(),
    );
  }
}

class _StudentProfileView extends StatelessWidget {
  const _StudentProfileView();

  static const List<String> _tabLabels = <String>[
    StudentsStrings.tabProfile,
    StudentsStrings.tabHealth,
    StudentsStrings.tabAttendance,
    StudentsStrings.tabDates,
    StudentsStrings.tabDocuments,
  ];

  static const List<String> _profileSections = <String>[
    StudentsStrings.subAbout,
    StudentsStrings.subFamily,
    StudentsStrings.subPickup,
  ];

  static const List<String> _healthSections = <String>[
    StudentsStrings.subHealth,
    StudentsStrings.subPhysician,
    StudentsStrings.subExam,
    StudentsStrings.subImmunization,
  ];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StudentProfileCubit, StudentProfileState>(
        builder: (context, state) {
          final record = state.record;

          if (state.isFailed) {
            return ScreenScaffold(
              body: Center(
                child: ErrorState(
                  message: StudentsStrings.profileLoadError,
                  onRetry: () =>
                      unawaited(context.read<StudentProfileCubit>().load()),
                ),
              ),
            );
          }
          if (state.isLoading || record == null) {
            return const ScreenScaffold(body: LoadingState());
          }

          return ScreenScaffold(
            header: StudentProfileHeader(student: record.student),
            bodyPadding: EdgeInsets.zero,
            bottomBar: _Footer(student: record.student),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ProfileTabPills(
                  labels: _tabLabels,
                  index: state.tab.index,
                  onChanged: (i) => context
                      .read<StudentProfileCubit>()
                      .selectTab(ProfileTab.values[i]),
                ),
                if (state.hasSections)
                  Padding(
                    padding: StudentsSizes.subTabsPad,
                    child: _sections(context, state),
                  ),
                Expanded(
                  child: ProfileTabBody(state: state, record: record),
                ),
              ],
            ),
          );
        },
      );

  Widget _sections(BuildContext context, StudentProfileState state) {
    final cubit = context.read<StudentProfileCubit>();
    final isProfile = state.tab == ProfileTab.profile;

    return SegmentedControl(
      segments: isProfile ? _profileSections : _healthSections,
      index: isProfile ? state.profileSection.index : state.healthSection.index,
      onChanged: (i) => isProfile
          ? cubit.selectProfileSection(ProfileSection.values[i])
          : cubit.selectHealthSection(HealthSection.values[i]),
    );
  }
}

/// The two keys docked under the record: talk to the family, or end the
/// student's day. Sign Out is the one pink thing on the screen, and it is off
/// unless there is a day to end.
class _Footer extends StatelessWidget {
  const _Footer({required this.student});

  final StudentSummary student;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = student.attendance == AttendanceStatus.signedIn;

    return DockedBar(
      child: Row(
        spacing: StudentsSizes.footerGap,
        children: <Widget>[
          Expanded(
            child: SecondaryKey(
              label: StudentsStrings.messageFamily,
              onTap: student.hasGuardian
                  ? () => showAppToast(context, StudentsStrings.messagingSoon)
                  : null,
            ),
          ),
          Expanded(
            child: PrimaryKey(
              label: AppStrings.signOut,
              enabled: isSignedIn,
              onTap: () =>
                  showAppToast(context, StudentsStrings.attendanceFormSoon),
            ),
          ),
        ],
      ),
    );
  }
}
