import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_coordinator_state.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/school_status_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/attention_grid.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/availability_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/billing_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/classroom_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/enrollment_card.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/movements_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/admin_dashboard_viewmodel.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const String routeName = '/admin-dashboard';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final AdminDashboardCoordinatorCubit _coordinator;
  final GlobalKey _ratioCardKey = GlobalKey();
  final GlobalKey _shiftsCardKey = GlobalKey();

  // static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _coordinator = serviceLocator<AdminDashboardCoordinatorCubit>();
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
              // Navigate to the Custom Activities view with the Incident Type filter.
              // Note: ActivityFeedScreen currently does not support these query
              // parameters natively, so this sets the convention.
              context.go(
                '/activityFeed?tab=custom&activityType=Incident&classroom=All',
                extra: <String, dynamic>{'timestamp': DateTime.now().millisecondsSinceEpoch},
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
        }
        // else if (state.isPartialError) {
        //   CoreUtils.showTopSnackBar(
        //     context: context,
        //     message: 'Some sections could not be loaded. Pull down to retry.',
        //     isWarning: true,
        //   );
        // }
        else if (state.isReady) {
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
            child: _DashboardCardList(
              cardFor: _cardFor,
              buildHeader: _buildHeader,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCardList extends StatelessWidget {
  const _DashboardCardList({required this.cardFor, required this.buildHeader});

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
            final double gutter = constraints.maxWidth < 360 ? 12 : 16;

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
