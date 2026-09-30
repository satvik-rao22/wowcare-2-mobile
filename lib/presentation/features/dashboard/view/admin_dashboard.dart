import 'dart:async';
import 'package:wowcare/core/responsive/app_breakpoints.dart';
import 'package:wowcare/modules/attendance_regularization/regularization.dart';
import 'package:wowcare/presentation/features/dashboard/model/dashboard_route_args.dart';
import 'package:wowcare/core/router/app_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/tab_visibility_events.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/dashboard_coordinator_state.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/admin_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/admin_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/school_status_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/attention_grid.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/availability_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/billing_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/classroom_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/enrollment_card.dart';
import 'package:wowcare/presentation/features/availability/view_model/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/availability/view_model/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/movements_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/presentation/features/dashboard/model/admin_dashboard_viewmodel.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.focus});

  static const String routeName = '/admin-dashboard';

  /// See [DashboardScreen.focus]. `'ratioMonitoring'` scrolls to the Ratio
  /// Monitoring card once this dashboard has rendered.
  final String? focus;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TabBecameVisibleMixin {
  late final AdminDashboardCoordinatorCubit _coordinator;
  final GlobalKey _ratioCardKey = GlobalKey();
  final GlobalKey _shiftsCardKey = GlobalKey();

  // static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _coordinator = serviceLocator<AdminDashboardCoordinatorCubit>();
    if (widget.focus == 'ratioMonitoring') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToRatioCard();
      });
    }
  }

  @override
  void didUpdateWidget(AdminDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The dashboard is the kept-alive root of the shell's first branch (see
    // DashboardScreen's doc comment), so a repeat "Classroom Notes" tap while
    // it's already mounted rebuilds this widget with a new `focus` instead of
    // recreating it — initState alone only ever fired once, on the first-ever
    // dashboard build, so every later tap silently redirected without
    // scrolling. Re-check here too, same guard as initState.
    if (widget.focus == 'ratioMonitoring' &&
        oldWidget.focus != widget.focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToRatioCard();
      });
    }
  }

  // Dashboard is branch index 0 in app_router.dart's shell.
  @override
  int get tabBranchIndex => 0;

  @override
  void onTabBecameVisible() {
    if (!mounted) return;
    // Returning to the Dashboard tab (or re-tapping it while already there)
    // refreshes the coordinator that is ALREADY alive. This used to live in
    // DashboardScreen, where it bumped a KeyedSubtree epoch and destroyed the
    // whole subtree — which re-resolved this coordinator from GetIt (a
    // `registerFactory`, so a brand-new instance) and re-ran its constructor's
    // `initialize()`, i.e. the entire cold-open fan-out, every single time.
    //
    // `refresh()` is the same call pull-to-refresh already makes, and every
    // child cubit behind it has an in-flight guard plus a silent-refresh mode,
    // so this is idempotent and cheap. Same visible outcome: fresh data.
    unawaited(_coordinator.refresh());
  }

  void _scrollToRatioCard() {
    _scrollToKey(_ratioCardKey);
  }

  void _scrollToShiftsCard() {
    _scrollToKey(_shiftsCardKey);
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  void dispose() {
    // AdminDashboardCoordinatorCubit is closed automatically by BlocProvider,
    // which then automatically disposes of all screen-scoped child cubits.
    super.dispose();
  }

  Widget _cardFor(AdminDashboardCard card) {
    switch (card) {
      case AdminDashboardCard.myDay:
        return const MyDayCard();
      case AdminDashboardCard.enrollment:
        return BlocProvider<SchoolStatusCubit>.value(
          value: _coordinator.schoolStatusCubit,
          child: const EnrollmentCard(isDashboard: true),
        );
      case AdminDashboardCard.ratioMonitoring:
        return BlocProvider<RatioMonitoringCubit>.value(
          value: _coordinator.ratioMonitoringCubit,
          child: RatioMonitoringCard(key: _ratioCardKey),
        );
      case AdminDashboardCard.classroomShifts:
        return ClassroomShiftsCard(key: _shiftsCardKey);
      case AdminDashboardCard.availability:
        return BlocProvider<FutureAvailabilityCubit>.value(
          value: _coordinator.availabilityCubit,
          child: const AvailabilityCard(),
        );
      case AdminDashboardCard.movements:
        return BlocProvider<IndividualMovementsCubit>.value(
          value: _coordinator.movementsCubit,
          child: const MovementsCard(),
        );
      case AdminDashboardCard.billing:
        return const BillingCard();
    }
  }

  Widget _buildHeader(String userName) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardWelcomeHeader(userName: userName, showSectionLabel: false),
          const SizedBox(height: 16),
          AttentionGrid(
            onRatioCardTap: _scrollToRatioCard,
            onShiftsCardTap: _scrollToShiftsCard,
            onIncidentCardTap: () {
              // Navigate to the Custom Activities view with the Incident Type
              // AND Pending Admin Approval filters applied, every classroom,
              // no date bound — the card counts pending incidents regardless
              // of when they occurred, so scoping the list to a date range
              // (the Custom tab's default is the current month) would hide
              // older ones the count still includes.
              //
              // 'Pending Admin Approval' (not the raw PENDING_ADMIN_APPROVAL
              // enum) because ActivityCustomTab's _filterApprovalStatuses
              // holds human-readable labels throughout (mirroring how
              // _filterActivityTypes holds 'Incident', not an ACT_TYPE_*
              // code) — the Filter Activities sheet's own pruning step
              // (activity_filter_screen.dart's _pruneSelectionsToOptions)
              // strips any value that doesn't exactly match its Title Case
              // option list, so the raw enum silently vanished from the
              // sheet's display (though it still reached the API correctly
              // via _approvalStatusesForApiFilter's case-insensitive label
              // lookup) — the funnel badge counted it as an active filter
              // while the sheet itself showed "Select status".
              context.go(
                Uri(
                  path: ShellBranchRoutes.activityFeed,
                  queryParameters: const <String, String>{
                    'tab': 'custom',
                    'activityType': 'Incident',
                    'classroom': 'All',
                    'approvalStatus': 'Pending Admin Approval',
                    'dateRange': 'all',
                  },
                ).toString(),
                // The timestamp exists only to make each tap a distinct
                // location so `_fastPage`'s query-keyed page identity rebuilds
                // the feed; ActivityFeedScreen never reads it.
                extra: IncidentFeedNonce(
                  value: DateTime.now().millisecondsSinceEpoch,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminDashboardCoordinatorCubit>(
      create: (context) => _coordinator,
      child: Builder(
        builder: (context) {
          final coordinator = context.read<AdminDashboardCoordinatorCubit>();
          return MultiBlocProvider(
            providers: [
              BlocProvider<AdminDashboardCubit>.value(
                value: coordinator.dashboardCubit,
              ),
              BlocProvider<GeofenceCubit>.value(
                value: coordinator.geofenceCubit,
              ),
              BlocProvider<SchoolStatusCubit>.value(
                value: coordinator.schoolStatusCubit,
              ),
              BlocProvider<RatioMonitoringCubit>.value(
                value: coordinator.ratioMonitoringCubit,
              ),
              BlocProvider<ClassroomShiftsCubit>.value(
                value: coordinator.classroomShiftsCubit,
              ),
              BlocProvider<IndividualMovementsCubit>.value(
                value: coordinator.movementsCubit,
              ),
              BlocProvider<FutureAvailabilityCubit>.value(
                value: coordinator.availabilityCubit,
              ),
              BlocProvider<DashboardAttentionCubit>.value(
                value: coordinator.attentionCubit,
              ),
              BlocProvider<MyDayCubit>.value(value: coordinator.myDayCubit),
            ],
            child: _buildScaffold(context),
          );
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final coordinator = context.read<AdminDashboardCoordinatorCubit>();
    return BlocListener<AdminDashboardCoordinatorCubit, DashboardState>(
      listenWhen: (prev, curr) {
        if (curr.isFailure && !prev.isFailure) return true;
        if (curr.isPartialError && !prev.isPartialError) return true;
        if (prev.isRefreshing && curr.isReady) return true;
        return false;
      },
      listener: (context, state) {
        if (state.isFailure) {
          CoreUtils.showTopSnackBar(
            context: context,
            message:
                state.errorMessage ??
                'Unable to load dashboard data. Please try again.',
            isError: true,
          );
        } else if (state.isReady) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Dashboard refreshed successfully.',
            isSuccess: true,
          );
        }
      },
      child: GlobalScaffold(
        showCustomNavigationBar: true,
        bodyPadding: EdgeInsets.zero,
        body: Material(
          type: MaterialType.transparency,
          child: CustomRefreshIndicator(
            onRefresh: () => coordinator.refresh(),
            child: _AdminDashboardCardList(
              cardFor: _cardFor,
              buildHeader: _buildHeader,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardCardList extends StatelessWidget {
  const _AdminDashboardCardList({
    required this.cardFor,
    required this.buildHeader,
  });

  final Widget Function(AdminDashboardCard) cardFor;
  final Widget Function(String) buildHeader;

  static const double _maxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AdminDashboardCubit, String>(
      (cubit) => cubit.state.userName,
    );

    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      buildWhen: (prev, curr) => prev.cards != curr.cards,
      builder: (context, dashState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // §7.2 KEEPS this LayoutBuilder — it is one of the "dashboard
            // gutter checks" the mandate names, and it decides only this
            // subtree's own horizontal padding.
            //
            // Precise about what it measures: this sits OUTSIDE the 640 cap
            // below, so `constraints.maxWidth` is the width the shell hands
            // the list, not the capped content box. That distinction cannot
            // change the outcome, because the threshold (360) is below the cap
            // (640): at every width where this ternary flips, the cap is not
            // binding and the two are the same number. Above 640 both sides
            // yield 16.
            //
            // The 360 literal is gone — the boundary is AppBreakpoints', so
            // nothing here defines a breakpoint locally.
            final double gutter =
                constraints.maxWidth < AppBreakpoints.narrowMaxWidth ? 12 : 16;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Pre-build all cards so GlobalKey scroll targets are always
                  // resolvable regardless of initial scroll position.
                  cacheExtent: 5000,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                      sliver: SliverToBoxAdapter(child: buildHeader(userName)),
                    ),
                    // Attendance Regularization — "needs your approval" card
                    // with the pending count badge. Hidden at zero.
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
                      sliver: SliverToBoxAdapter(
                        child: Regularization.gateWatcher(),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
                      sliver: SliverReorderableList(
                        itemCount: dashState.cards.length,
                        onReorder: context
                            .read<AdminDashboardCubit>()
                            .reorderCard,
                        itemBuilder: (context, index) {
                          final card = dashState.cards[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(card),
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Material(
                                type: MaterialType.transparency,
                                child: cardFor(card),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
