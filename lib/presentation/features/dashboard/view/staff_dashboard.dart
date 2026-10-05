import 'dart:async';
import 'package:wowcare/core/responsive/app_breakpoints.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/tab_visibility_events.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/dashboard_coordinator_state.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/staff_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/staff_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/my_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/presentation/features/dashboard/model/staff_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key, this.focus});

  static const String routeName = '/staff-dashboard';

  /// See `DashboardScreen.focus`. `'ratioMonitoring'` scrolls to the Ratio
  /// Monitoring card once this dashboard has rendered.
  final String? focus;

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with TabBecameVisibleMixin {
  late final StaffDashboardCoordinatorCubit _coordinator;
  final GlobalKey _ratioCardKey = GlobalKey();

  // static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _coordinator = serviceLocator<StaffDashboardCoordinatorCubit>();
    if (widget.focus == 'ratioMonitoring') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToRatioCard();
      });
    }
  }

  @override
  void didUpdateWidget(StaffDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The dashboard is the kept-alive root of the shell's first branch (see
    // DashboardScreen's doc comment), so a repeat "Classroom Notes" tap while
    // it's already mounted rebuilds this widget with a new `focus` instead of
    // recreating it — initState alone only ever fired once, on the first-ever
    // dashboard build, so every later tap silently redirected without
    // scrolling. Re-check here too, same guard as initState.
    if (widget.focus == 'ratioMonitoring' && oldWidget.focus != widget.focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToRatioCard();
      });
    }
  }

  void _scrollToRatioCard() {
    final ctx = _ratioCardKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
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

  @override
  void dispose() {
    // StaffDashboardCoordinatorCubit is closed automatically by BlocProvider,
    // which then automatically disposes of all screen-scoped child cubits.
    super.dispose();
  }

  Widget _cardFor(StaffDashboardCard card) {
    switch (card) {
      case StaffDashboardCard.myDay:
        return const MyDayCard();
      case StaffDashboardCard.ratioMonitoring:
        return RatioMonitoringCard(key: _ratioCardKey);
      case StaffDashboardCard.myShifts:
        return const MyShiftsCard();
      case StaffDashboardCard.myAttendance:
        return const MyAttendanceCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffDashboardCoordinatorCubit>(
      create: (context) => _coordinator,
      child: Builder(
        builder: (context) {
          final coordinator = context.read<StaffDashboardCoordinatorCubit>();
          return MultiBlocProvider(
            providers: [
              BlocProvider<StaffDashboardCubit>.value(
                value: coordinator.dashboardCubit,
              ),
              BlocProvider<GeofenceCubit>.value(
                value: coordinator.geofenceCubit,
              ),
              BlocProvider<RatioMonitoringCubit>.value(
                value: coordinator.ratioMonitoringCubit,
              ),
              BlocProvider<MyDayCubit>.value(value: coordinator.myDayCubit),
              BlocProvider<MyShiftsCubit>.value(
                value: coordinator.myShiftsCubit,
              ),
              BlocProvider<MyAttendanceCubit>.value(
                value: coordinator.myAttendanceCubit,
              ),
            ],
            child: _buildScaffold(context),
          );
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final coordinator = context.read<StaffDashboardCoordinatorCubit>();
    return BlocListener<StaffDashboardCoordinatorCubit, DashboardState>(
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
            child: _StaffDashboardCardList(cardFor: _cardFor),
          ),
        ),
      ),
    );
  }
}

class _StaffDashboardCardList extends StatelessWidget {
  const _StaffDashboardCardList({required this.cardFor});

  final Widget Function(StaffDashboardCard) cardFor;

  static const double _maxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffDashboardCubit, StaffDashboardState>(
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
                  // Pre-build all cards so GlobalKey scroll targets (e.g. the
                  // Ratio Monitoring card's notification-driven auto-scroll)
                  // are always resolvable regardless of initial scroll
                  // position - mirrors AdminDashboard's identical fix.
                  cacheExtent: 5000,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 28),
                      sliver: SliverReorderableList(
                        itemCount: dashState.cards.length,
                        onReorder: context
                            .read<StaffDashboardCubit>()
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
