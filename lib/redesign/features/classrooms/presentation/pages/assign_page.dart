import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/chip_row.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/assign_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/assign_candidate_row.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/assign_step_rail.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/changes_card.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/info_well.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/over_ratio_alert.dart';

/// 7g and 7h. Two steps, one flow: pick who joins the classroom, review what
/// that changes, then submit.
///
/// It applies immediately. Nothing here books a move for a later date, which
/// is what the module's costly list rules out.
class AssignPage extends StatelessWidget {
  const AssignPage({required this.classroomId, required this.kind, super.key});

  final String classroomId;
  final AssignKind kind;

  @override
  Widget build(BuildContext context) => BlocProvider<AssignCubit>(
    create: (_) {
      final cubit = redesignLocator<AssignCubit>(
        param1: classroomId,
        param2: kind,
      );
      unawaited(cubit.load());
      return cubit;
    },
    child: const _AssignView(),
  );
}

class _AssignView extends StatefulWidget {
  const _AssignView();

  @override
  State<_AssignView> createState() => _AssignViewState();
}

class _AssignViewState extends State<_AssignView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  AssignCubit get _cubit => context.read<AssignCubit>();

  Future<void> _submit(AssignState state) async {
    await _cubit.submit();
    if (!mounted) return;
    showAppToast(
      context,
      state.isStudents
          ? ClassroomsStrings.studentsAssigned(
              state.pickedIds.length,
              state.classroomName,
            )
          : ClassroomsStrings.staffAssigned(
              state.pickedIds.length,
              state.classroomName,
            ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AssignCubit, AssignState>(
    builder: (context, state) => ScreenScaffold(
      header: AppHeaderBar.dashboard(
        title: state.isStudents
            ? ClassroomsStrings.assignStudentsTitle
            : ClassroomsStrings.assignStaffTitle,
        subline: ClassroomsStrings.toClassroom(state.classroomName),
        leading: BackKey(
          onTap: state.isReview
              ? _cubit.toPick
              : () => Navigator.of(context).pop(),
        ),
      ),
      bodyPadding: EdgeInsets.zero,
      bottomBar: state.isLoading || state.hasNoCandidates
          ? null
          : _footer(state),
      body: _body(state),
    ),
  );

  Widget _body(AssignState state) {
    if (state.isLoading) return const LoadingState();
    if (state.isFailed && state.candidates.isEmpty) {
      return Padding(
        padding: AppSizes.bodyPad,
        child: Center(
          child: ErrorState(onRetry: () => unawaited(_cubit.load())),
        ),
      );
    }
    if (state.hasNoCandidates) {
      return const Padding(
        padding: AppSizes.bodyPad,
        child: Center(
          child: EmptyState(
            icon: AppIcons.users,
            title: ClassroomsStrings.nobodyToAssign,
            subtitle: ClassroomsStrings.nobodyToAssignBody,
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSizes.screenTopPad,
        bottom: AppSizes.screenBottomPad,
      ),
      children: <Widget>[
        _gutter(
          AssignStepRail(
            firstLabel: state.isStudents
                ? ClassroomsStrings.stepPickStudents
                : ClassroomsStrings.stepPickStaff,
            secondLabel: ClassroomsStrings.stepReview,
            isSecond: state.isReview,
          ),
        ),
        const SizedBox(height: AppSizes.cardGap),
        if (state.isReview) ..._review(state) else ..._pick(state),
      ],
    );
  }

  // --- Step one ---------------------------------------------------------------

  List<Widget> _pick(AssignState state) => <Widget>[
    _gutter(
      SearchField(
        controller: _search,
        hintText: state.isStudents
            ? ClassroomsStrings.searchNotInClassroom
            : ClassroomsStrings.searchStaffNotInClassroom,
        onChanged: _cubit.search,
        onClear: () {
          _search.clear();
          _cubit.search('');
        },
      ),
    ),
    const SizedBox(height: AppSizes.cardGap),
    ChipRow(
      children: <Widget>[
        for (final entry in state.groups.entries)
          AppChip(
            label: entry.key,
            count: '${entry.value}',
            selected: state.group == entry.key,
            onTap: () =>
                _cubit.selectGroup(state.group == entry.key ? null : entry.key),
          ),
      ],
    ),
    const SizedBox(height: AppSizes.cardGap),
    if (state.hasNoMatches)
      _gutter(
        EmptyState(
          icon: AppIcons.search,
          title: ClassroomsStrings.noCandidateMatches,
          actionLabel: ClassroomsStrings.clearSearch,
          onAction: () {
            _search.clear();
            _cubit
              ..search('')
              ..selectGroup(null);
          },
        ),
      )
    else
      for (final candidate in state.visible)
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.screenGutter,
            right: AppSizes.screenGutter,
            bottom: ClassroomsSizes.rosterGap,
          ),
          child: AssignCandidateRow(
            candidate: candidate,
            isStaff: !state.isStudents,
            isPicked: state.pickedIds.contains(candidate.id),
            onTap: () => _cubit.toggle(candidate.id),
          ),
        ),
  ];

  // --- Step two ---------------------------------------------------------------

  List<Widget> _review(AssignState state) {
    final classroom = state.classroom;
    final outside = state.pickedOutsideAgeRange;

    return <Widget>[
      if (outside.isNotEmpty) ...<Widget>[
        _gutter(
          OverRatioAlert(
            title: ClassroomsStrings.outsideAgeRangeTitle(outside.length),
            message: outside.length == 1
                ? ClassroomsStrings.outsideAgeRangeBody(
                    outside.first.name,
                    outside.first.age,
                    classroom?.ageBand ?? '',
                  )
                : ClassroomsStrings.outsideAgeRangeBodyMany(
                    classroom?.ageBand ?? '',
                  ),
          ),
        ),
        const SizedBox(height: AppSizes.cardGap),
      ],
      _gutter(ChangesCard(lines: _changes(state))),
      const SizedBox(height: AppSizes.cardGap),
      _gutter(
        SectionEyebrow(
          label: state.isStudents
              ? ClassroomsStrings.movingInto(state.classroomName)
              : ClassroomsStrings.joining(state.classroomName),
          color: state.isStudents
              ? context.colours.student
              : context.colours.staffFg,
        ),
      ),
      const SizedBox(height: AppSizes.sectionGap),
      for (final candidate in state.picked)
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.screenGutter,
            right: AppSizes.screenGutter,
            bottom: ClassroomsSizes.rosterGap,
          ),
          child: AssignCandidateRow(
            candidate: candidate,
            isStaff: !state.isStudents,
            showCheckbox: false,
            onRemove: () => _cubit.toggle(candidate.id),
          ),
        ),
      if (!state.isStudents)
        _gutter(
          InfoWell(
            message: ClassroomsStrings.shiftNote(
              state.picked.isEmpty ? '' : state.picked.first.firstName,
            ),
          ),
        ),
    ];
  }

  /// What submitting does, in the frame's own three lines.
  List<ChangeLine> _changes(AssignState state) {
    final classroom = state.classroom;
    if (classroom == null) return const <ChangeLine>[];

    if (state.isStudents) {
      final staffNeeded = classroom.allowedRatio <= 0
          ? 0
          : (state.enrolledAfter / classroom.allowedRatio).ceil() -
                classroom.staffPresent;
      return <ChangeLine>[
        ChangeLine(
          label: ClassroomsStrings.placesFilledLabel,
          value: ClassroomsStrings.goesTo(
            classroom.name,
            state.enrolledAfter,
            classroom.capacity,
          ),
        ),
        ChangeLine(
          label: ClassroomsStrings.ratioLabel,
          value: staffNeeded <= 0
              ? ClassroomsStrings.inRatioWith(classroom.staffPresent)
              : ClassroomsStrings.shortWith(
                  classroom.staffPresent,
                  staffNeeded,
                ),
          isGood: staffNeeded <= 0,
        ),
        const ChangeLine(
          label: ClassroomsStrings.applies,
          value: ClassroomsStrings.immediately,
        ),
      ];
    }

    return <ChangeLine>[
      ChangeLine(
        label: ClassroomsStrings.staffInClassroom,
        value: ClassroomsStrings.becomes(
          classroom.staffPresent,
          state.staffAfter,
        ),
      ),
      ChangeLine(
        label: ClassroomsStrings.ratioLabel,
        value: ClassroomsStrings.holdsUpTo(
          classroom.holdsWithStaff(state.staffAfter),
        ),
        isGood: true,
      ),
      const ChangeLine(
        label: ClassroomsStrings.theirShifts,
        value: ClassroomsStrings.unchanged,
      ),
    ];
  }

  // --- The docked keys --------------------------------------------------------

  Widget _footer(AssignState state) {
    final c = context.colours;
    final count = state.pickedIds.length;

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
        child: Row(
          spacing: ClassroomsSizes.footerGap,
          children: <Widget>[
            if (state.isReview)
              SecondaryKey(
                label: AppStrings.back,
                onTap: _cubit.toPick,
                expand: false,
                padding: ClassroomsSizes.footerBackPad,
              ),
            Expanded(
              child: PrimaryKey(
                label: _keyLabel(state, count),
                enabled: count > 0,
                isLoading: state.isSubmitting,
                padding: ClassroomsSizes.footerKeyPad,
                onTap: count == 0
                    ? null
                    : (state.isReview
                          ? () => unawaited(_submit(state))
                          : _cubit.toReview),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _keyLabel(AssignState state, int count) {
    if (count == 0) {
      return state.isStudents
          ? ClassroomsStrings.pickAStudentFirst
          : ClassroomsStrings.pickAStaffFirst;
    }
    if (state.isReview) {
      return state.isStudents
          ? ClassroomsStrings.assignNStudents(count)
          : ClassroomsStrings.assignNStaff(count);
    }
    return state.isStudents
        ? ClassroomsStrings.reviewStudents(count)
        : ClassroomsStrings.reviewStaff(count);
  }

  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenGutter),
    child: child,
  );
}
