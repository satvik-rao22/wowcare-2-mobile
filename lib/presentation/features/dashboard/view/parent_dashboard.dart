import 'dart:async';
import 'package:wowcare/core/responsive/app_breakpoints.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/tab_visibility_events.dart';
import 'package:wowcare/presentation/features/app_update/widgets/optional_update_banner.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/dashboard_coordinator_state.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/parent_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/billing/view_model/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/model/parent_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/my_childs_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/student_attendance_summary_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/student_billing_card.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/student_newsletters_card.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  static const String routeName = '/parent-dashboard';

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with TabBecameVisibleMixin {
  late final ParentDashboardCoordinatorCubit _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = serviceLocator<ParentDashboardCoordinatorCubit>();
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
    // ParentDashboardCoordinatorCubit is closed automatically by BlocProvider,
    // which then automatically disposes of all screen-scoped child cubits.
    super.dispose();
  }

  Widget _cardFor(ParentDashboardCard card) {
    switch (card) {
      case ParentDashboardCard.myChildsDay:
        return const MyChildsDayCard();
      case ParentDashboardCard.studentAttendance:
        return const StudentAttendanceSummaryCard();
      case ParentDashboardCard.studentBilling:
        return const StudentBillingCard();
      case ParentDashboardCard.studentNewsletters:
        return const StudentNewslettersCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParentDashboardCoordinatorCubit>(
      create: (context) => _coordinator,
      child: Builder(
        builder: (context) {
          final coordinator = context.read<ParentDashboardCoordinatorCubit>();
          return MultiBlocProvider(
            providers: [
              BlocProvider<ParentDashboardCubit>.value(
                value: coordinator.dashboardCubit,
              ),
              BlocProvider<MyChildsDayCubit>.value(
                value: coordinator.myChildsDayCubit,
              ),
              BlocProvider<StudentAttendanceProfileCubit>.value(
                value: coordinator.studentAttendanceProfileCubit,
              ),
              BlocProvider<CommunicationCubit>.value(
                value: coordinator.communicationCubit,
              ),
              BlocProvider<StudentNewslettersCubit>.value(
                value: coordinator.studentNewslettersCubit,
              ),
              BlocProvider<ParentBillingCubit>.value(
                value: coordinator.parentBillingCubit,
              ),
              BlocProvider<GeofenceCubit>.value(
                value: coordinator.geofenceCubit,
              ),
            ],
            child: _buildScaffold(context),
          );
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final coordinator = context.read<ParentDashboardCoordinatorCubit>();
    return BlocListener<ParentDashboardCoordinatorCubit, DashboardState>(
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
        isParent: true,
        bodyPadding: EdgeInsets.zero,
        body: Material(
          type: MaterialType.transparency,
          child: CustomRefreshIndicator(
            onRefresh: () => coordinator.refresh(),
            child: _ParentDashboardCardList(cardFor: _cardFor),
          ),
        ),
      ),
    );
  }
}

/// Isolated widget for the reorderable card list.
///
/// Keeping `SliverReorderableList` in its own `BlocBuilder` with
/// `buildWhen: cards changed` prevents the builder from firing during an
/// active drag (no state is emitted mid-drag). Without this isolation the
/// parent `BlocBuilder` could rebuild the list while a drag overlay entry is
/// still alive, producing duplicate `_OverlayEntryWidgetState` GlobalKeys and
/// the `_elements.contains(element)` framework assertion.
class _ParentDashboardCardList extends StatelessWidget {
  const _ParentDashboardCardList({required this.cardFor});

  final Widget Function(ParentDashboardCard) cardFor;

  static const double _maxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
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
                  slivers: [
                    // The optional update banner (System Messages S1). It
                    // takes the list's 24px top inset, and is zero height
                    // unless an update is waiting, so the cards sit exactly
                    // where they did.
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
                      sliver: const SliverToBoxAdapter(
                        child: OptionalUpdateBanner(),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
                      sliver: SliverReorderableList(
                        itemCount: dashState.cards.length,
                        onReorder: context
                            .read<ParentDashboardCubit>()
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
