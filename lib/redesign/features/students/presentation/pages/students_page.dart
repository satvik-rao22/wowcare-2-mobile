import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_durations.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_fab.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/chip_row.dart';
import 'package:wowcare/redesign/core/widgets/counting_tile.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/inline_alert.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/students/cubit/students_roster_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/bulk_action_bar.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/deactivate_student_sheet.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/roster_group_section.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/select_mode_key.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_actions_sheet.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/students_banner.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/students_edge_state.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/students_filter_chip.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/students_filter_sheet.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/upcoming_student_row.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// 5a, 5b and 5g. The roster, reached from More.
///
/// Same page, two lenses: an Admin sees the school and every write key; a
/// Staff member sees the classroom they are rostered to and a note saying so.
/// A Guardian is refused, which is what 5g's view-only state draws.
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;

    return BlocProvider<StudentsRosterCubit>(
      create: (_) {
        final cubit = redesignLocator<StudentsRosterCubit>(
          param1: session.persona,
          param2: session.isStaff ? session.user?.classroomName : null,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _StudentsView(),
    );
  }
}

class _StudentsView extends StatelessWidget {
  const _StudentsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StudentsRosterCubit>();

    return BlocListener<SessionCubit, SessionState>(
      // The roster is built for one persona. If 13d flips it under us, the
      // safe answer is the dashboard, not a stale list.
      listenWhen: (previous, current) => previous.persona != current.persona,
      listener: (context, state) => context.go(AppRoutes.dashboard),
      child: BlocBuilder<StudentsRosterCubit, StudentsRosterState>(
        builder: (context, state) => ScreenScaffold(
          header: AppHeaderBar(
            title: StudentsStrings.title,
            leading: const BackKey(),
            actions: <Widget>[
              if (!state.isRestricted)
                IconKey(
                  icon: AppIcons.filter,
                  semanticLabel: StudentsStrings.filterKey,
                  onTap: () => unawaited(_openFilter(context, state)),
                ),
              if (state.canWrite && !state.isRestricted)
                SelectModeKey(
                  isOn: state.isSelectMode,
                  onTap: cubit.toggleSelectMode,
                ),
            ],
          ),
          bodyPadding: EdgeInsets.zero,
          fab: state.canWrite && !state.isSelectMode && !state.isRestricted
              ? AppFab(
                  semanticLabel: StudentsStrings.addStudentKey,
                  onTap: () => unawaited(_addStudent(context)),
                )
              : null,
          bottomBar: state.isSelectMode
              ? BulkActionBar(
                  selectedCount: state.selectedIds.length,
                  onClear: cubit.clearSelection,
                  onSignIn: () =>
                      showAppToast(context, StudentsStrings.attendanceFormSoon),
                )
              : null,
          body: _Body(state: state),
        ),
      ),
    );
  }

  Future<void> _openFilter(
    BuildContext context,
    StudentsRosterState state,
  ) async {
    final cubit = context.read<StudentsRosterCubit>();
    final chosen = await StudentsFilterSheet.show(
      context,
      filter: state.filter,
      classroomNames: state.snapshot.classroomNames,
      tagNames: state.snapshot.tagNames,
      guardianNames: state.snapshot.guardianNames,
      activeCount: state.snapshot.activeCount,
      upcomingCount: state.snapshot.upcomingCount,
      attendanceCounts: <AttendanceStatus, int>{
        for (final status in AttendanceStatus.values)
          status: state.snapshot.students
              .where((s) => s.attendance == status)
              .length,
      },
    );
    if (chosen != null) cubit.applyFilter(chosen);
  }

  Future<void> _addStudent(BuildContext context) async {
    final cubit = context.read<StudentsRosterCubit>();
    await context.push<void>(AppRoutes.addStudent);
    await cubit.load(isSilent: true);
  }
}

/// Everything under the header: the search, the applied filters, the two
/// counts, and the list or the state that stands in for it.
class _Body extends StatelessWidget {
  const _Body({required this.state});

  final StudentsRosterState state;

  @override
  Widget build(BuildContext context) {
    if (state.isRestricted) return const _RestrictedBody();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.isOffline)
          Padding(
            padding: StudentsSizes.bannerMargin,
            child: StudentsBanner(
              message: StudentsStrings.offlineBanner(state.asOfLabel ?? ''),
              tone: BannerTone.caution,
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.screenGutter),
          child: _RosterSearchField(),
        ),
        if (!state.isLoading && !state.isFailed) ...<Widget>[
          _AppliedFilters(state: state),
          _Counts(state: state),
        ],
        Expanded(child: _list(context)),
      ],
    );
  }

  Widget _list(BuildContext context) {
    final cubit = context.read<StudentsRosterCubit>();

    if (state.isLoading) return const LoadingState();
    if (state.isFailed) {
      return Center(
        child: ErrorState(
          message: StudentsStrings.loadError,
          onRetry: () => unawaited(cubit.load()),
        ),
      );
    }
    if (state.isOffline) return _EdgeBody(state: state);
    if (state.isEmptySchool || state.hasNoResults) {
      return _EdgeBody(state: state);
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: StudentsSizes.listPad,
        children: <Widget>[
          if (!state.canWrite)
            const Padding(
              padding: EdgeInsets.only(bottom: StudentsSizes.groupGap),
              child: InlineAlert(
                message: StudentsStrings.staffScopeNote,
                tone: AlertTone.info,
              ),
            ),
          for (final group in state.groups)
            Padding(
              padding: const EdgeInsets.only(bottom: StudentsSizes.groupGap),
              child: RosterGroupSection(
                group: group,
                title: state.scopeClassroom == group.classroomName
                    ? StudentsStrings.yourClassroom(group.classroomName)
                    : null,
                expandedId: state.expandedId,
                canWrite: state.canWrite,
                isSelectMode: state.isSelectMode,
                selectedIds: state.selectedIds,
                onToggle: (student) => state.isSelectMode
                    ? cubit.toggleSelected(student.id)
                    : cubit.toggleExpanded(student.id),
                onOpenProfile: (student) =>
                    unawaited(_openProfile(context, student)),
                onMoreActions: (student) =>
                    unawaited(_openActions(context, student)),
              ),
            ),
          if (state.startingSoon.isNotEmpty) _startingSoon(context),
        ],
      ),
    );
  }

  Widget _startingSoon(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSizes.sectionGap,
    children: <Widget>[
      SectionEyebrow(
        label: StudentsStrings.startingSoonEyebrow(state.startingSoon.length),
      ),
      for (final student in state.startingSoon)
        Padding(
          padding: const EdgeInsets.only(bottom: StudentsSizes.rowGap),
          child: UpcomingStudentRow(
            student: student,
            onTap: () => unawaited(_openProfile(context, student)),
          ),
        ),
    ],
  );

  Future<void> _openProfile(
    BuildContext context,
    StudentSummary student,
  ) async {
    final cubit = context.read<StudentsRosterCubit>();
    await context.push<void>(AppRoutes.student(student.id));
    await cubit.load(isSilent: true);
  }

  Future<void> _openActions(
    BuildContext context,
    StudentSummary student,
  ) async {
    final cubit = context.read<StudentsRosterCubit>();
    final action = await StudentActionsSheet.show(context, student: student);
    if (action == null || !context.mounted) return;

    switch (action) {
      case StudentAction.attendance:
        showAppToast(context, StudentsStrings.attendanceFormSoon);
      case StudentAction.activity:
        showAppToast(context, StudentsStrings.activityFormSoon);
      case StudentAction.message:
        showAppToast(context, StudentsStrings.messagingSoon);
      case StudentAction.edit:
        await context.push<void>(AppRoutes.editStudent(student.id));
        await cubit.load(isSilent: true);
      case StudentAction.profile:
        await _openProfile(context, student);
      case StudentAction.deactivate:
        await _deactivate(context, student);
    }
  }

  Future<void> _deactivate(BuildContext context, StudentSummary student) async {
    final cubit = context.read<StudentsRosterCubit>();
    final confirmed = await DeactivateStudentSheet.show(
      context,
      student: student,
      enrolledLabel: StudentsStrings.notRecorded,
    );
    if (confirmed != true) return;

    final done = await cubit.deactivate(student.id);
    if (!context.mounted) return;
    showAppToast(
      context,
      done
          ? StudentsStrings.deactivated(student.fullName)
          : StudentsStrings.saveError,
      tone: done ? ToastTone.ok : ToastTone.error,
    );
  }
}

/// 5g's four states, all of which keep the header and the search above them.
class _EdgeBody extends StatelessWidget {
  const _EdgeBody({required this.state});

  final StudentsRosterState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StudentsRosterCubit>();

    if (state.isOffline) {
      return StudentsEdgeState(
        glyph: StudentsStrings.glyphBang,
        tone: EdgeTone.caution,
        title: StudentsStrings.offlineTitle,
        body: StudentsStrings.offlineBody(state.savedCount),
        actionLabel: AppStrings.retry,
        onAction: () => unawaited(cubit.load()),
      );
    }

    if (state.isEmptySchool) {
      return StudentsEdgeState(
        glyph: StudentsStrings.glyphPlus,
        tone: EdgeTone.invite,
        title: StudentsStrings.emptyTitle,
        body: StudentsStrings.emptyBody,
        actionLabel: state.canWrite ? StudentsStrings.addStudentKey : null,
        onAction: state.canWrite
            ? () => unawaited(context.push<void>(AppRoutes.addStudent))
            : null,
        secondaryLabel: StudentsStrings.bulkImportNote,
      );
    }

    return StudentsEdgeState(
      glyph: StudentsStrings.glyphZero,
      title: StudentsStrings.noResultsTitle(state.query.trim()),
      body: StudentsStrings.noResultsBody,
      actionLabel: StudentsStrings.clearFilters,
      onAction: cubit.clearFilters,
      secondaryLabel: StudentsStrings.searchInactiveToo,
      onSecondary: () => cubit.applyFilter(
        state.filter.copyWith(status: StudentStatus.inactive),
      ),
    );
  }
}

/// A persona that may not read student records at all (5g view only).
class _RestrictedBody extends StatelessWidget {
  const _RestrictedBody();

  @override
  Widget build(BuildContext context) {
    final school = context.read<SessionCubit>().state.user?.schoolName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: StudentsSizes.bannerMargin,
          child: StudentsBanner(message: StudentsStrings.viewOnlyBanner),
        ),
        Expanded(
          child: StudentsEdgeState(
            glyph: StudentsStrings.glyphDash,
            title: StudentsStrings.viewOnlyTitle,
            body: StudentsStrings.viewOnlyBody(school),
            secondaryLabel: StudentsStrings.messageAdmin,
            onSecondary: () =>
                showAppToast(context, StudentsStrings.messagingSoon),
          ),
        ),
      ],
    );
  }
}

/// The chips that say what the roster is currently narrowed to (5a).
class _AppliedFilters extends StatelessWidget {
  const _AppliedFilters({required this.state});

  final StudentsRosterState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StudentsRosterCubit>();
    final filter = state.filter;
    final classrooms = filter.classrooms.isEmpty
        ? state.snapshot.classroomNames
        : filter.classrooms.toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.space3),
      child: ChipRow(
        children: <Widget>[
          StudentsFilterChip(
            label: filter.status.label,
            selected: true,
            onRemove: filter.status == StudentStatus.active
                ? null
                : () => cubit.applyFilter(
                    filter.copyWith(status: StudentStatus.active),
                  ),
          ),
          if (classrooms.isNotEmpty)
            StudentsFilterChip(
              label: classrooms.join(', '),
              onRemove: filter.classrooms.isEmpty
                  ? null
                  : () => cubit.applyFilter(
                      filter.copyWith(classrooms: <String>{}),
                    ),
            ),
          if (filter.tags.isNotEmpty)
            StudentsFilterChip(
              label: filter.tags.join(', '),
              onRemove: () =>
                  cubit.applyFilter(filter.copyWith(tags: <String>{})),
            ),
          if (filter.guardians.isNotEmpty)
            StudentsFilterChip(
              label: filter.guardians.join(', '),
              onRemove: () =>
                  cubit.applyFilter(filter.copyWith(guardians: <String>{})),
            ),
          if (filter.attendance.isNotEmpty)
            StudentsFilterChip(
              label: AppStrings.attendance,
              onRemove: () => cubit.applyFilter(
                filter.copyWith(attendance: <AttendanceStatus>{}),
              ),
            ),
          if (state.isNarrowed)
            TextLink(label: AppStrings.clearAll, onTap: cubit.clearFilters),
        ],
      ),
    );
  }
}

/// The two counts over the list: the roster, and who is joining it.
class _Counts extends StatelessWidget {
  const _Counts({required this.state});

  final StudentsRosterState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: StudentsSizes.stripPad,
    child: Row(
      spacing: StudentsSizes.dockGap,
      children: <Widget>[
        Expanded(
          child: CountingTile(
            value: '${state.snapshot.activeCount}',
            label: StudentsStrings.activeStudentsTile,
            tone: TileTone.student,
          ),
        ),
        Expanded(
          child: CountingTile(
            value: '${state.snapshot.upcomingCount}',
            label: StudentsStrings.startingSoonTile,
          ),
        ),
      ],
    ),
  );
}

/// The search field, which waits for the typing to stop before it asks.
class _RosterSearchField extends StatefulWidget {
  const _RosterSearchField();

  @override
  State<_RosterSearchField> createState() => _RosterSearchFieldState();
}

class _RosterSearchFieldState extends State<_RosterSearchField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      if (!mounted) return;
      unawaited(context.read<StudentsRosterCubit>().search(query));
    });
  }

  @override
  Widget build(BuildContext context) =>
      SearchField(hintText: StudentsStrings.searchHint, onChanged: _onChanged);
}
