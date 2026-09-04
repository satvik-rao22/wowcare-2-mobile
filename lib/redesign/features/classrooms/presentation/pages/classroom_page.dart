import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/offline_banner.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_head_card.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_mini_card.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_tabs.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/extended_fab.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/locked_overlay.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/move_blocked_sheet.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/note_composer.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/notes_tab.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/over_ratio_alert.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/remove_student_sheet.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/select_action_bar.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/staff_filter_sheet.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/staff_tab.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/student_filter_sheet.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/students_tab.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/teacher_clock_card.dart';

/// One classroom, seen by whoever opened it.
///
/// An Admin gets 7c: three tabs, select mode and the two refusals. A teacher
/// opening their own classroom gets 7e: two tabs, a clock card, and a roster
/// that stays locked until they are on the clock. Everybody else looks (7j).
class ClassroomPage extends StatelessWidget {
  const ClassroomPage({
    required this.classroomId,
    this.isOwn = false,
    super.key,
  });

  final String classroomId;

  /// The signed-in teacher's own classroom, which is 7e.
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final persona = context.read<SessionCubit>().state.persona;

    return BlocProvider<ClassroomCubit>(
      create: (_) {
        final cubit = redesignLocator<ClassroomCubit>(
          param1: ClassroomArgs(
            classroomId: classroomId,
            persona: persona,
            isOwnClassroom: isOwn,
          ),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _ClassroomView(),
    );
  }
}

class _ClassroomView extends StatefulWidget {
  const _ClassroomView();

  @override
  State<_ClassroomView> createState() => _ClassroomViewState();
}

class _ClassroomViewState extends State<_ClassroomView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ClassroomCubit get _cubit => context.read<ClassroomCubit>();

  /// The shift the teacher is late for. A real shift comes from Scheduling;
  /// until M14 lands this is the demo day's own.
  static const String _shift = '7:30 to 16:30';

  void _clearSearch() {
    _search.clear();
    _cubit.clearSearch();
  }

  void _notReady() => showAppToast(context, AppStrings.comingSoon);

  void _refused() => showAppToast(
    context,
    ClassroomsStrings.viewOnlyToast,
    tone: ToastTone.error,
  );

  // --- Sheets ----------------------------------------------------------------

  Future<void> _openFilters(ClassroomState state) async {
    final detail = state.detail;
    if (detail == null) return;

    if (state.tab == ClassroomTab.staff) {
      final result = await StaffFilterSheet.show(
        context,
        filters: state.staffFilters,
        designations: detail.designations,
        counts: <StaffDutyState, int>{
          for (final duty in StaffDutyState.values)
            if (detail.countOfDuty(duty) > 0) duty: detail.countOfDuty(duty),
        },
      );
      if (result != null) _cubit.applyStaffFilters(result);
      return;
    }

    final result = await StudentFilterSheet.show(
      context,
      filters: state.studentFilters,
      activeCount: detail.students.length,
      upcomingCount: detail.upcomingStudents.length,
      signedInCount: detail.signedInCount,
      nappingCount: detail.nappingCount,
      tags: detail.careTags,
    );
    if (result != null) _cubit.applyStudentFilters(result);
  }

  /// The two things an Admin can do to a student from the roster, and the two
  /// ways the app says no (7i).
  Future<void> _moreActions(ClassroomState state, RosterStudent student) async {
    final detail = state.detail;
    if (detail == null) return;
    if (!state.canEdit) {
      _refused();
      return;
    }

    final action = await SingleSelectSheet.show<_RowAction>(
      context,
      title: student.name,
      options: const <SelectOption<_RowAction>>[
        SelectOption<_RowAction>(
          value: _RowAction.move,
          label: ClassroomsStrings.moveClassroom,
          subtitle: ClassroomsStrings.transferWhy,
        ),
        SelectOption<_RowAction>(
          value: _RowAction.remove,
          label: ClassroomsStrings.removeFromClassroom,
          subtitle: ClassroomsStrings.removeBody,
        ),
      ],
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _RowAction.move:
        await _move(detail, student);
      case _RowAction.remove:
        await _remove(detail, student);
    }
  }

  /// A student who is in the classroom right now cannot be moved out of it
  /// today: their attendance would end up recorded against a classroom they
  /// are not in.
  Future<void> _move(ClassroomDetail detail, RosterStudent student) async {
    if (student.isSignedIn) {
      final choice = await MoveBlockedSheet.show(context, student: student);
      if (!mounted || choice == null) return;
      _notReady();
      return;
    }

    final target = await SingleSelectSheet.show<String>(
      context,
      title: ClassroomsStrings.pickClassroom,
      options: <SelectOption<String>>[
        for (final classroom in detail.others)
          SelectOption<String>(
            value: classroom.id,
            label: classroom.name,
            subtitle: ClassroomsStrings.ofPlaces(
              classroom.enrolled,
              classroom.capacity,
            ),
          ),
      ],
    );
    if (!mounted || target == null) return;

    await _cubit.moveStudent(studentId: student.id, toClassroomId: target);
    if (!mounted) return;
    final name = detail.others.firstWhere((r) => r.id == target).name;
    showAppToast(context, ClassroomsStrings.movedTo(student.firstName, name));
  }

  Future<void> _remove(ClassroomDetail detail, RosterStudent student) async {
    final confirmed = await RemoveStudentSheet.show(
      context,
      student: student,
      classroom: detail.summary,
    );
    if (!mounted || confirmed != true) return;

    await _cubit.removeStudent(student.id);
    if (!mounted) return;
    showAppToast(
      context,
      ClassroomsStrings.removedFrom(student.name, detail.summary.name),
    );
  }

  // --- Navigation ------------------------------------------------------------

  void _openProfile(ClassroomState state) =>
      unawaited(context.push(AppRoutes.classroomProfile(state.classroomId)));

  void _assign(ClassroomState state, {required bool isStaff}) {
    if (!state.canEdit) {
      _refused();
      return;
    }
    unawaited(
      context.push(
        isStaff
            ? AppRoutes.assignStaff(state.classroomId)
            : AppRoutes.assignStudents(state.classroomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, state) => ScreenScaffold(
          header: _header(state),
          bodyPadding: EdgeInsets.zero,
          bottomBar: _bottomBar(state),
          fab: _fab(state),
          body: _body(state),
        ),
      );

  // --- The frame -------------------------------------------------------------

  Widget _header(ClassroomState state) {
    final name = state.summary?.name ?? '';

    return AppHeaderBar(
      title: name,
      isDetail: true,
      leading: state.isTeacherView ? null : const BackKey(),
      actions: <Widget>[
        if (state.isTeacherView)
          const StatusPill(
            label: ClassroomsStrings.yourClassroom,
            tone: PillTone.staff,
          )
        else if (!state.canEdit)
          const StatusPill(label: ClassroomsStrings.viewOnly)
        else if (state.tab == ClassroomTab.students)
          _selectKey(state),
      ],
    );
  }

  Widget _selectKey(ClassroomState state) => state.isSelectMode
      ? PrimaryKey(
          label: ClassroomsStrings.done,
          onTap: _cubit.toggleSelectMode,
          expand: false,
          padding: ClassroomsSizes.headerKeyPad,
        )
      : SecondaryKey(
          label: ClassroomsStrings.select,
          onTap: _cubit.toggleSelectMode,
          expand: false,
          padding: ClassroomsSizes.headerKeyPad,
        );

  Widget? _bottomBar(ClassroomState state) {
    if (state.isSelectMode) {
      return SelectActionBar(
        selectedCount: state.selectedIds.length,
        onClear: _cubit.clearSelection,
        onMessage: _notReady,
        onActivities: _notReady,
        onMarkAttendance: _notReady,
      );
    }
    if (state.tab == ClassroomTab.notes && state.detail != null) {
      return NoteComposer(
        onSend: (text) => unawaited(_cubit.postNote(text)),
        onAttach: _notReady,
      );
    }
    return null;
  }

  Widget? _fab(ClassroomState state) {
    if (state.detail == null ||
        state.isSelectMode ||
        state.tab == ClassroomTab.notes ||
        state.isTeacherView) {
      return null;
    }

    final isStaffTab = state.tab == ClassroomTab.staff;
    if (!isStaffTab && state.hasNoStudents) return null;

    return ExtendedFab(
      label: isStaffTab
          ? ClassroomsStrings.assignStaff
          : ClassroomsStrings.assignStudents,
      isDead: !state.canEdit,
      onTap: state.canEdit ? () => _assign(state, isStaff: isStaffTab) : null,
    );
  }

  // --- The body --------------------------------------------------------------

  Widget _body(ClassroomState state) {
    if (state.isLoading) {
      return const LoadingState(label: ClassroomsStrings.loadingClassroom);
    }
    final detail = state.detail;
    if (detail == null || state.isFailed) {
      return Padding(
        padding: AppSizes.bodyPad,
        child: Center(
          child: ErrorState(
            title: ClassroomsStrings.couldNotReachTitle,
            message: ClassroomsStrings.couldNotReachBodyNoCache,
            onRetry: () => unawaited(_cubit.load()),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cubit.refresh,
      color: context.colours.pink,
      backgroundColor: context.colours.card,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenGutter,
          AppSizes.screenTopPad,
          AppSizes.screenGutter,
          AppSizes.screenBottomPad,
        ),
        children: <Widget>[
          if (state.isCached) ...<Widget>[
            const OfflineBanner(),
            const SizedBox(height: AppSizes.cardGap),
          ],
          ..._head(state, detail),
          const SizedBox(height: ClassroomsSizes.tabsTopGap),
          ClassroomTabs(
            tabs: state.tabs,
            selected: state.tab,
            onChanged: _cubit.selectTab,
            studentCount: detail.students.length,
            staffCount: detail.staff.length,
            newNoteCount: detail.newNoteCount,
          ),
          if (state.isTeacherView) ...<Widget>[
            const SizedBox(height: ClassroomsSizes.toolbarGap),
            Text(
              ClassroomsStrings.noStaffTabNote,
              style: ClassroomsTextStyles.hours.copyWith(
                color: context.colours.ink3,
              ),
            ),
          ],
          const SizedBox(height: ClassroomsSizes.toolbarGap),
          _tabBody(state),
        ],
      ),
    );
  }

  List<Widget> _head(ClassroomState state, ClassroomDetail detail) {
    if (!state.isTeacherView) {
      return <Widget>[
        ClassroomHeadCard(
          summary: detail.summary,
          staffOnDuty: detail.staffOnDuty,
          onOpenProfile: () => _openProfile(state),
        ),
      ];
    }

    final session = context.read<SessionCubit>().state.user;

    return <Widget>[
      if (state.isLocked) ...<Widget>[
        TeacherClockCard(
          initials: session?.initials ?? '',
          shiftLine: ClassroomsStrings.shiftLine(_shift),
          onClockIn: _cubit.clockIn,
        ),
        const SizedBox(height: AppSizes.cardGap),
      ] else if (!detail.summary.isInRatio) ...<Widget>[
        OverRatioAlert(
          title: ClassroomsStrings.overRatioBy(detail.summary.staffNeeded),
          message: ClassroomsStrings.overRatioBody(
            detail.summary.studentsPresent,
            detail.summary.staffPresent,
            detail.summary.staffNeeded,
          ),
        ),
        const SizedBox(height: AppSizes.cardGap),
      ],
      ClassroomMiniCard(
        summary: detail.summary,
        subtitle: ClassroomsStrings.profileCapacityCounts,
        onTap: () => _openProfile(state),
      ),
    ];
  }

  Widget _tabBody(ClassroomState state) => switch (state.tab) {
    ClassroomTab.students => _students(state),
    ClassroomTab.staff => StaffTab(
      state: state,
      searchController: _search,
      onSearch: _cubit.search,
      onClearSearch: _clearSearch,
      onOpenFilters: () => unawaited(_openFilters(state)),
      onToggleDutyState: _cubit.toggleStaffDuty,
    ),
    ClassroomTab.notes => NotesTab(
      notes: state.detail!.notes,
      newCount: state.detail!.newNoteCount,
    ),
  };

  Widget _students(ClassroomState state) {
    final tab = StudentsTab(
      state: state,
      searchController: _search,
      onSearch: _cubit.search,
      onClearSearch: _clearSearch,
      onOpenFilters: () => unawaited(_openFilters(state)),
      onToggleSignedIn: _cubit.toggleSignedInOnly,
      onToggleNapping: _cubit.toggleNappingOnly,
      onToggleRow: (student) => _cubit.toggleExpanded(student.id),
      onToggleSelected: (student) => _cubit.toggleSelected(student.id),
      onAssignStudents: state.canEdit
          ? () => _assign(state, isStaff: false)
          : null,
      onOpenStudent: (_) => _notReady(),
      onMoreActions: (student) => unawaited(_moreActions(state, student)),
    );

    if (!state.isLocked) return tab;
    return Stack(children: <Widget>[tab, const LockedOverlay()]);
  }
}

/// The two things an Admin can do to a student from the roster.
enum _RowAction { move, remove }
