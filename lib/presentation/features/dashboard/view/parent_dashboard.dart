import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_coordinator_state.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_childs_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_newsletters_card.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/parent_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  static const String routeName = '/parent-dashboard';

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  late final ParentDashboardCoordinatorCubit _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = serviceLocator<ParentDashboardCoordinatorCubit>();
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
        return const StudentAttendanceCard();
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
        } else if (state.isPartialError) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Some sections could not be loaded. Pull down to retry.',
            isWarning: true,
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
            child: _DashboardCardList(cardFor: _cardFor),
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
class _DashboardCardList extends StatelessWidget {
  const _DashboardCardList({required this.cardFor});

  final Widget Function(ParentDashboardCard) cardFor;

  static const double _maxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
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
