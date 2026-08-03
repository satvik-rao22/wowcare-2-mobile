import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_coordinator_state.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/staff_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  static const String routeName = '/staff-dashboard';

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late final StaffDashboardCoordinatorCubit _coordinator;

  // static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _coordinator = serviceLocator<StaffDashboardCoordinatorCubit>();
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
        return const RatioMonitoringCard();
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
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: MultiBlocProvider(
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
            ),
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
            child: _DashboardCardList(cardFor: _cardFor),
          ),
        ),
      ),
    );
  }
}

class _DashboardCardList extends StatelessWidget {
  const _DashboardCardList({required this.cardFor});

  final Widget Function(StaffDashboardCard) cardFor;

  static const double _maxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffDashboardCubit, StaffDashboardState>(
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
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 28),
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
