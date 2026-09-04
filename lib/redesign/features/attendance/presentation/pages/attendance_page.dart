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
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/multi_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/segmented_control.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/cubit/attendance_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_body.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_day_strip.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_filter_chips.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_select_bar.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_select_key.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/day_picker_sheet.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/edit_times_sheet.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/mark_absent_sheet.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/record_actions_sheet.dart';

/// 4a, 4c, 4d and 4e. The attendance slot: one day, whoever is looking.
///
/// Same page, three lenses. An Admin gets the school and both lists; a Staff
/// member gets their own shift first and then the classroom they are rostered
/// to; a Guardian gets their own children and the month behind them.
class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;

    return BlocProvider<AttendanceCubit>(
      create: (_) {
        final cubit = redesignLocator<AttendanceCubit>(
          param1: session.persona,
          param2: session.isStaff ? session.user?.classroomName : null,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _AttendanceView(),
    );
  }
}

/// The screen itself. Stateful for two things only: the search debounce, and
/// whether the day sheet is open, which the day strip draws a ring for.
class _AttendanceView extends StatefulWidget {
  const _AttendanceView();

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView> {
  Timer? _debounce;
  bool _isDayOpen = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  AttendanceCubit get _cubit => context.read<AttendanceCubit>();

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      if (!mounted) return;
      unawaited(_cubit.search(query));
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, state) => ScreenScaffold(
          header: state.isSearching
              ? _searchHeader(state)
              : _titleHeader(state),
          bodyPadding: EdgeInsets.zero,
          fab: state.canWrite && !state.isSelectMode
              ? AppFab(
                  semanticLabel: AttendanceStrings.signInKey,
                  onTap: _cubit.startSelecting,
                )
              : null,
          bottomBar: state.isSelectMode
              ? AttendanceSelectBar(
                  audience: state.audience,
                  selectedCount: state.selectedIds.length,
                  onClear: _cubit.clearSelection,
                  onSignIn: () => unawaited(_signIn(state)),
                )
              : null,
          body: _body(state),
        ),
      );

  // --- Header ---------------------------------------------------------------

  Widget _titleHeader(AttendanceState state) => AppHeaderBar(
    title: _title(state),
    actions: <Widget>[
      IconKey(
        icon: AppIcons.search,
        semanticLabel: AttendanceStrings.searchKey,
        onTap: _cubit.openSearch,
      ),
      if (!state.isGuardian)
        IconKey(
          icon: AppIcons.filter,
          semanticLabel: AttendanceStrings.rangeFilterTitle,
          badgeCount: state.classrooms.length,
          onTap: () => unawaited(_openClassroomFilter(state)),
        ),
      if (!state.isGuardian)
        AttendanceSelectKey(
          isOn: state.isSelectMode,
          onTap: state.canWrite ? _cubit.toggleSelectMode : null,
        ),
    ],
  );

  /// 4e's search bar: the well takes the whole row, and Cancel puts the
  /// header back.
  Widget _searchHeader(AttendanceState state) => Padding(
    padding: AppSizes.headerBarPad,
    child: Row(
      spacing: AppSizes.headerGap,
      children: <Widget>[
        Expanded(
          child: SearchField(
            autofocus: true,
            hintText: AttendanceStrings.searchHint,
            onChanged: _onSearchChanged,
          ),
        ),
        TextLink(
          label: AppStrings.cancel,
          onTap: () => unawaited(_cubit.closeSearch()),
        ),
      ],
    ),
  );

  String _title(AttendanceState state) {
    if (state.isSelectMode) {
      return state.selectedIds.isEmpty
          ? AttendanceStrings.selectTitle
          : AttendanceStrings.selectedTitle(state.selectedIds.length);
    }
    if (state.isGuardian) {
      final children = state.snapshot.children;
      return children.length == 1
          ? AttendanceStrings.guardianTitle(children.first.today.firstName)
          : AppStrings.attendance;
    }
    return state.scopeClassroom ?? AppStrings.attendance;
  }

  // --- Body -----------------------------------------------------------------

  Widget _body(AttendanceState state) {
    if (state.isLoading) return const LoadingState();
    if (state.isFailed) {
      return Center(
        child: ErrorState(
          message: AttendanceStrings.loadError,
          onRetry: () => unawaited(_cubit.load()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.showsAudienceSwitch)
          Padding(
            padding: AttendanceSizes.switchMargin,
            child: SegmentedControl(
              segments: const <String>[
                AttendanceStrings.studentsSegment,
                AttendanceStrings.staffSegment,
              ],
              sublabels: <String>[
                AttendanceStrings.inOfCount(
                  state.snapshot.studentsSignedIn,
                  state.snapshot.studentsTotal,
                ),
                AttendanceStrings.inOfCount(
                  state.snapshot.staffSignedIn,
                  state.snapshot.staffTotal,
                ),
              ],
              index: state.audience.index,
              onChanged: (index) => unawaited(
                _cubit.setAudience(AttendanceAudience.values[index]),
              ),
            ),
          ),
        Padding(
          padding: AttendanceSizes.stripMargin,
          child: AttendanceDayStrip(
            label: AttendanceFormats.dayLabel(state.day, state.today),
            isActive: _isDayOpen,
            onPick: () => unawaited(_openDayPicker(state)),
            onBack: () => unawaited(_cubit.stepDay(-1)),
            onForward: state.isToday
                ? null
                : () => unawaited(_cubit.stepDay(1)),
          ),
        ),
        if (!state.isGuardian)
          Padding(
            padding: AttendanceSizes.chipStripPad,
            child: AttendanceFilterChips(
              selected: state.filter,
              countFor: state.countFor,
              onSelected: _cubit.setFilter,
            ),
          ),
        Expanded(
          child: AttendanceBody(
            state: state,
            onRefresh: _cubit.refresh,
            onRetry: () => unawaited(_cubit.load()),
            onClearNarrowing: () => unawaited(_cubit.clearNarrowing()),
            onToggleRow: (record) => _cubit.toggleExpanded(record.id),
            onSelectRow: (record) => _cubit.toggleSelected(record.id),
            onMoreActions: (record) => unawaited(_openActions(state, record)),
            onSignSelf: () => unawaited(_signSelf(state)),
            onSignOutSelf: () => unawaited(_signOutSelf()),
            onOpenScheduling: () =>
                showAppToast(context, AttendanceStrings.schedulingSoon),
            onSeeWhoIsFree: () =>
                showAppToast(context, AttendanceStrings.availabilitySoon),
            onScanQr: () => showAppToast(context, AttendanceStrings.scanQrSoon),
            onGuardianSignOut: (record) =>
                unawaited(_signOutOne(state, record)),
          ),
        ),
      ],
    );
  }

  // --- The day sheet --------------------------------------------------------

  Future<void> _openDayPicker(AttendanceState state) async {
    setState(() => _isDayOpen = true);
    final chosen = await DayPickerSheet.show(
      context,
      today: state.today,
      day: state.day,
      range: _defaultRange(state.today),
      allowRange: !state.isGuardian,
    );
    if (!mounted) return;
    setState(() => _isDayOpen = false);
    if (chosen == null) return;

    if (chosen.choice == DayChoice.range) {
      await context.push<void>(AppRoutes.attendanceRange, extra: chosen.range);
      return;
    }
    await _cubit.chooseDay(chosen);
  }

  /// The range 4f opens on: this month to date.
  static DateRange _defaultRange(DateTime today) =>
      DateRange(from: DateTime(today.year, today.month), to: today);

  Future<void> _openClassroomFilter(AttendanceState state) async {
    final chosen = await MultiSelectSheet.show<String>(
      context,
      title: AttendanceStrings.rangeFilterTitle,
      subtitle: AttendanceStrings.rangeFilterSubtitle,
      options: <SelectOption<String>>[
        for (final name in state.snapshot.classroomNames)
          SelectOption<String>(value: name, label: name),
      ],
      selected: state.classrooms,
    );
    if (chosen != null) _cubit.setClassrooms(chosen);
  }

  // --- Writes ---------------------------------------------------------------

  Future<void> _signIn(AttendanceState state) async {
    if (state.selectedIds.isEmpty) {
      showAppToast(context, AttendanceStrings.nobodyPicked);
      return;
    }
    await _pushSignForm(
      SignAttendanceArgs(
        kind: SignKind.signIn,
        audience: state.audience,
        ids: state.selectedRows.map((r) => r.id).toList(),
      ),
    );
    if (!mounted) return;
    _cubit.clearSelection();
  }

  Future<void> _signOutOne(
    AttendanceState state,
    AttendanceRecord record,
  ) async => _pushSignForm(
    SignAttendanceArgs(
      kind: SignKind.signOut,
      audience: record.audience,
      ids: <String>[record.id],
    ),
  );

  Future<void> _pushSignForm(SignAttendanceArgs args) async {
    final route = args.kind.isSignIn
        ? AppRoutes.attendanceSignIn
        : AppRoutes.attendanceSignOut;
    final done = await context.push<bool>(route, extra: args);
    if (!mounted || done != true) return;
    await _cubit.load(isSilent: true);
  }

  Future<void> _signSelf(AttendanceState state) async {
    final shift = state.selfShift;
    if (shift != null && !shift.canSignSelfIn) {
      showAppToast(
        context,
        AttendanceStrings.geofenceBlocked,
        tone: ToastTone.error,
      );
      return;
    }
    final done = await _cubit.signSelfIn();
    if (!mounted || done) return;
    showAppToast(context, AttendanceStrings.saveError, tone: ToastTone.error);
  }

  Future<void> _signOutSelf() async {
    final done = await _cubit.signSelfOut();
    if (!mounted || done) return;
    showAppToast(context, AttendanceStrings.saveError, tone: ToastTone.error);
  }

  // --- The record sheet -----------------------------------------------------

  Future<void> _openActions(
    AttendanceState state,
    AttendanceRecord record,
  ) async {
    final action = await RecordActionsSheet.show(
      context,
      record: record,
      now: ClockTime.fromDateTime(state.today),
      canEditTimes: state.canEditTimes,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case AttendanceAction.signIn:
        if (record.isAbsent) await _cubit.undoAbsence(record.id);
        if (!mounted) return;
        await _pushSignForm(
          SignAttendanceArgs(
            kind: SignKind.signIn,
            audience: record.audience,
            ids: <String>[record.id],
          ),
        );
      case AttendanceAction.signOut:
        await _signOutOne(state, record);
      case AttendanceAction.transfer:
        await _transfer(state, record);
      case AttendanceAction.markAbsent:
        await _markAbsent(state, record);
      case AttendanceAction.undoAbsence:
        await _undoAbsence(record);
      case AttendanceAction.editTimes:
        await _editTimes(state, record);
      case AttendanceAction.openProfile:
        await context.push<void>(
          record.audience.isStudents
              ? AppRoutes.student(record.id)
              : AppRoutes.staffMember(record.id),
        );
    }
  }

  Future<void> _transfer(AttendanceState state, AttendanceRecord record) async {
    final others = <String>[
      for (final name in state.snapshot.classroomNames)
        if (name != record.classroomName) name,
    ];
    if (others.isEmpty) {
      showAppToast(context, AttendanceStrings.transferNoRoom);
      return;
    }

    final chosen = await SingleSelectSheet.show<String>(
      context,
      title: AttendanceStrings.transferTitle,
      subtitle: AttendanceStrings.transferSubtitle(record.classroomName),
      options: <SelectOption<String>>[
        for (final name in others)
          SelectOption<String>(value: name, label: name),
      ],
    );
    if (chosen == null || !mounted) return;

    final done = await _cubit.transfer(id: record.id, toClassroom: chosen);
    if (!mounted) return;
    showAppToast(
      context,
      done
          ? AttendanceStrings.transferToast(record.fullName, chosen)
          : AttendanceStrings.saveError,
      tone: done ? ToastTone.ok : ToastTone.error,
    );
  }

  Future<void> _markAbsent(
    AttendanceState state,
    AttendanceRecord record,
  ) async {
    final draft = await MarkAbsentSheet.show(
      context,
      name: record.fullName,
      date: state.day,
      today: state.today,
    );
    if (draft == null || !mounted) return;

    final done = await _cubit.markAbsent(id: record.id, reason: draft.reason);
    if (!mounted) return;
    showAppToast(
      context,
      done
          ? AttendanceStrings.markedAbsentToast(record.fullName)
          : AttendanceStrings.saveError,
      tone: done ? ToastTone.ok : ToastTone.error,
    );
  }

  Future<void> _undoAbsence(AttendanceRecord record) async {
    final done = await _cubit.undoAbsence(record.id);
    if (!mounted) return;
    showAppToast(
      context,
      done
          ? AttendanceStrings.undoAbsenceToast(record.fullName)
          : AttendanceStrings.saveError,
      tone: done ? ToastTone.ok : ToastTone.error,
    );
  }

  Future<void> _editTimes(
    AttendanceState state,
    AttendanceRecord record,
  ) async {
    final draft = await EditTimesSheet.show(
      context,
      record: record,
      date: state.day,
      today: state.today,
    );
    if (draft == null || !mounted) return;

    final done = await _cubit.editTimes(
      id: record.id,
      at: draft.at,
      isSignOut: draft.isSignOut,
    );
    if (!mounted) return;
    showAppToast(
      context,
      done ? AttendanceStrings.editTimesToast : AttendanceStrings.saveError,
      tone: done ? ToastTone.ok : ToastTone.error,
    );
  }
}
