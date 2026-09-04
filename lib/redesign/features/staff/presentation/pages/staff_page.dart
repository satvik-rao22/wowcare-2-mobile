import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/app_fab.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/chip_row.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_roster_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/deactivate_staff_sheet.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/own_record_card.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_actions_sheet.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_banner.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_counts.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_filter_sheet.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_row_card.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_select_bar.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_state_view.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/team_row.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/upcoming_row.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6a, 6b, 6e. Staff is reached from More, so this is a drill-down under the
/// dashboard branch: it leads with a back key and lights no tab.
///
/// Which of the three screens it is depends on who is looking, and the lens
/// decides that once: an Admin gets the roster, a staff member gets their own
/// record and the colleagues they share a classroom with, and a guardian gets
/// the refusal.
class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final lens = StaffLens(
      persona: session.persona,
      viewerId: session.user?.id ?? '',
      viewerClassroom: session.user?.classroomName,
    );

    return BlocProvider<StaffRosterCubit>(
      create: (_) {
        final cubit = redesignLocator<StaffRosterCubit>(param1: lens);
        unawaited(cubit.load());
        return cubit;
      },
      child: const _StaffView(),
    );
  }
}

class _StaffView extends StatefulWidget {
  const _StaffView();

  @override
  State<_StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<_StaffView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  StaffRosterCubit get _cubit => context.read<StaffRosterCubit>();

  // --- Going places -----------------------------------------------------------

  void _open(StaffMember member) =>
      unawaited(context.push(AppRoutes.staffMember(member.id)));

  Future<void> _create() async {
    await context.push<StaffMember>(AppRoutes.addStaff);
    if (!mounted) return;
    await _cubit.refresh();
  }

  void _message() => unawaited(context.push(AppRoutes.composeMessage));

  /// Calling is the platform's job. Until the dialer is wired in Phase 5 the
  /// number is what the roster row already shows, so this only acknowledges.
  void _call(StaffMember member) =>
      showAppToast(context, StaffStrings.callName(member.firstName));

  // --- Sheets ------------------------------------------------------------------

  Future<void> _openFilters() async {
    final state = _cubit.state;
    final applied = await StaffFilterSheet.show(
      context,
      filters: state.filters,
      designations: state.designationOptions,
      classrooms: state.classroomOptions,
      designationCounts: <String, int>{
        for (final designation in state.designationOptions)
          designation: state.countOfDesignation(designation),
      },
      attendanceCounts: <AttendanceStatus, int>{
        for (final status in AttendanceStatus.values)
          status: state.countOfAttendance(status),
      },
    );
    if (applied != null) _cubit.applyFilters(applied);
  }

  Future<void> _openActions(StaffMember member) async {
    final action = await StaffActionsSheet.show(context, member: member);
    if (!mounted || action == null) return;

    switch (action) {
      case StaffAction.signInForThem:
        unawaited(context.push(AppRoutes.attendanceSignIn));
      case StaffAction.editShifts:
        unawaited(context.push(AppRoutes.staffSchedule(member.id)));
      case StaffAction.changeClassrooms:
        unawaited(context.push(AppRoutes.staffMember(member.id)));
      case StaffAction.deactivate:
        await _confirmDeactivate(member);
      case StaffAction.reactivate:
        await _setActive(member, isActive: true);
    }
  }

  Future<void> _confirmDeactivate(StaffMember member) async {
    final confirmed = await DeactivateStaffSheet.show(context, member: member);
    if (!mounted || confirmed != true) return;
    await _setActive(member, isActive: false);
  }

  Future<void> _setActive(StaffMember member, {required bool isActive}) async {
    final ok = await _cubit.setActive(id: member.id, isActive: isActive);
    if (!mounted) return;
    showAppToast(
      context,
      ok
          ? (isActive
                ? StaffStrings.reactivated(member.name)
                : StaffStrings.deactivated(member.name))
          : AppStrings.somethingWentWrong,
      tone: ok ? ToastTone.ok : ToastTone.error,
    );
  }

  // --- The screen --------------------------------------------------------------

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StaffRosterCubit, StaffRosterState>(
        builder: (context, state) => ScreenScaffold(
          header: _header(state),
          bodyPadding: EdgeInsets.zero,
          fab: state.lens.canWrite && !state.isSelectMode && !state.isDenied
              ? AppFab(semanticLabel: StaffStrings.addStaff, onTap: _create)
              : null,
          bottomBar: state.isSelectMode
              ? StaffSelectBar(
                  selectedCount: state.selectedIds.length,
                  onClear: _cubit.clearSelection,
                  onMessage: _message,
                )
              : null,
          body: _body(state),
        ),
      );

  Widget _header(StaffRosterState state) => AppHeaderBar(
    title: StaffStrings.title,
    leading: const BackKey(),
    actions: <Widget>[
      if (!state.isViewOnly && !state.isDenied) ...<Widget>[
        IconKey(
          icon: AppIcons.filter,
          semanticLabel: AppStrings.filter,
          onTap: () => unawaited(_openFilters()),
        ),
        _SelectKey(isOn: state.isSelectMode, onTap: _cubit.toggleSelectMode),
      ],
    ],
  );

  Widget _body(StaffRosterState state) {
    if (state.isDenied) return _deniedBody(state);
    if (state.isLoading) {
      return const LoadingState(label: StaffStrings.loadingStaff);
    }
    if (state.isFailed) return _offlineBody();

    return RefreshIndicator(
      onRefresh: _cubit.refresh,
      color: context.colours.pink,
      backgroundColor: context.colours.card,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: AppSizes.screenBottomPad),
        children: state.isViewOnly ? _viewOnly(state) : _roster(state),
      ),
    );
  }

  // --- 6e, the two screens that are not a roster -------------------------------

  Widget _deniedBody(StaffRosterState state) => Column(
    children: <Widget>[
      const StaffBanner(
        message: StaffStrings.deniedBanner,
        tone: StaffBannerTone.denied,
      ),
      Expanded(
        child: StaffStateView(
          mark: StaffStrings.dash,
          title: StaffStrings.deniedTitle,
          message: StaffStrings.deniedBody(
            context.read<SessionCubit>().state.user?.schoolName ?? '',
          ),
          tone: StaffStateTone.denied,
          actionLabel: StaffStrings.switchSchool,
          onAction: () => unawaited(context.push(AppRoutes.account)),
        ),
      ),
    ],
  );

  Widget _offlineBody() => Center(
    child: StaffStateView(
      mark: AppStrings.alertMark,
      title: StaffStrings.offlineTitle,
      message: StaffStrings.offlineBody,
      tone: StaffStateTone.offline,
      actionLabel: AppStrings.retry,
      onAction: () => unawaited(_cubit.load()),
    ),
  );

  /// 6e's view-only screen: the viewer's own record in full, then the
  /// colleagues they share a classroom with, and nothing else.
  List<Widget> _viewOnly(StaffRosterState state) {
    final own = state.ownRecord;
    final team = state.team;

    return <Widget>[
      const StaffBanner(
        message: StaffStrings.viewOnlyBanner,
        tone: StaffBannerTone.quiet,
      ),
      const SizedBox(height: AppSizes.screenTopPad),
      if (state.isCached) ...<Widget>[
        _gutter(_offlineBanner(state)),
        const SizedBox(height: AppSizes.cardGap),
      ],
      if (own != null) ...<Widget>[
        _gutter(OwnRecordCard(member: own, onOpen: () => _open(own))),
        const SizedBox(height: StaffSizes.teamGap),
      ],
      if (team.isNotEmpty) ...<Widget>[
        _gutter(
          SectionEyebrow(
            label: StaffStrings.inYourClassrooms(team.length),
            color: context.colours.staffFg,
          ),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        for (final member in team)
          Padding(
            padding: _rowPad,
            child: TeamRow(member: member, onCall: () => _call(member)),
          ),
        _gutter(
          Text(
            StaffStrings.teamFootnote,
            style: StaffTextStyles.footnote.copyWith(
              color: context.colours.ink3,
            ),
          ),
        ),
      ],
    ];
  }

  // --- 6a, the roster ----------------------------------------------------------

  List<Widget> _roster(StaffRosterState state) => <Widget>[
    const SizedBox(height: AppSizes.screenTopPad),
    if (state.isCached) ...<Widget>[
      _gutter(_offlineBanner(state)),
      const SizedBox(height: AppSizes.cardGap),
    ],
    _gutter(
      SearchField(
        controller: _search,
        hintText: StaffStrings.searchHint,
        onChanged: _cubit.search,
        onClear: _cubit.clearSearch,
      ),
    ),
    const SizedBox(height: StaffSizes.chipRowGap),
    _chips(state),
    const SizedBox(height: StaffSizes.chipRowGap),
    _gutter(
      StaffCounts(
        activeCount: state.roster.activeCount,
        upcomingCount: state.roster.upcomingCount,
      ),
    ),
    const SizedBox(height: AppSizes.cardGap),
    if (state.hasNoStaff)
      _gutter(
        EmptyState(
          icon: AppIcons.staff,
          title: StaffStrings.noStaffTitle,
          subtitle: StaffStrings.noStaffBody,
          actionLabel: state.lens.canWrite ? StaffStrings.addStaff : null,
          onAction: state.lens.canWrite ? _create : null,
        ),
      )
    else if (state.hasNoMatches)
      _gutter(
        EmptyState(
          icon: AppIcons.search,
          title: StaffStrings.noMatchTitle,
          subtitle: StaffStrings.noMatchBody,
          actionLabel: AppStrings.clearAll,
          onAction: _cubit.clearFilters,
        ),
      )
    else ...<Widget>[
      _gutter(
        SectionEyebrow(
          label: StaffStrings.staffMemberCount(state.visible.length),
          color: context.colours.staffFg,
          meta: StaffStrings.orderLabel(state.filters.order),
        ),
      ),
      const SizedBox(height: AppSizes.sectionGap),
      for (final member in state.visible)
        Padding(
          padding: _rowPad,
          child: StaffRowCard(
            member: member,
            isExpanded: state.expandedId == member.id,
            isSelectMode: state.isSelectMode,
            isSelected: state.selectedIds.contains(member.id),
            onTap: () => state.isSelectMode
                ? _cubit.toggleSelected(member.id)
                : _cubit.toggleExpanded(member.id),
            onCall: () => _call(member),
            onOpen: () => _open(member),
            onMoreActions: state.lens.canWrite
                ? () => unawaited(_openActions(member))
                : null,
          ),
        ),
    ],
    if (state.startingSoon.isNotEmpty) ...<Widget>[
      _gutter(
        SectionEyebrow(
          label: StaffStrings.startingSoon,
          color: context.colours.ink3,
          meta: '${state.startingSoon.length}',
        ),
      ),
      const SizedBox(height: AppSizes.sectionGap),
      for (final member in state.startingSoon)
        Padding(
          padding: _rowPad,
          child: UpcomingRow(member: member, onTap: () => _open(member)),
        ),
    ],
  ];

  /// The chips over the roster. Every one of them opens the sheet; the ones
  /// that stand for something the viewer chose also carry a cross that takes
  /// it back off, which is what the frame draws.
  Widget _chips(StaffRosterState state) => ChipRow(
    children: <Widget>[
      for (final chip in state.chips)
        AppChip(
          label: chip.label,
          selected: chip.isRemovable,
          onTap: () => unawaited(_openFilters()),
          onRemove: chip.isRemovable ? () => _cubit.removeChip(chip) : null,
        ),
      if (!state.filters.isClear)
        TextLink(label: AppStrings.clearAll, onTap: _cubit.clearFilters),
    ],
  );

  /// What is on screen is the team as it was, and the strip says when.
  Widget _offlineBanner(StaffRosterState state) {
    final at = state.roster.asOf;
    return StaffBanner(
      message: StaffStrings.offlineBanner(
        at == null
            ? StaffStrings.dash
            : StaffStrings.clock(at.hour * 60 + at.minute),
      ),
      tone: StaffBannerTone.offline,
    );
  }

  static const EdgeInsets _rowPad = EdgeInsets.only(
    left: AppSizes.screenGutter,
    right: AppSizes.screenGutter,
    bottom: AppSizes.cardGap,
  );

  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenGutter),
    child: child,
  );
}

/// The Select key in the header bar. Navy while select mode is on, which is
/// the same "this is switched on" the chips use.
class _SelectKey extends StatelessWidget {
  const _SelectKey({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final label = isOn ? AppStrings.done : AppStrings.select;

    return Semantics(
      button: true,
      selected: isOn,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isOn
              ? AppSurfaces.chipSelected(c)
              : AppSurfaces.keySecondary(c),
          padding: StaffSizes.selectKeyPad,
          child: Text(
            label,
            style: StaffTextStyles.headerKey.copyWith(
              color: isOn ? c.onImpact : c.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
