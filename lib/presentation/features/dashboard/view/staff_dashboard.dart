import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/dashboard/constants/dashboard_constants.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/services/dashboard_initialization_service.dart';
// import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  static const String routeName = '/staff-dashboard';

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(DashboardInitializationService.loadStaffDashboardData(context));
    });
  }

  @override
  void dispose() {
    // Note: All non-singleton cubits are closed automatically when they go out of scope.
    // GeofenceCubit is a singleton managed by ServiceLocator and must NOT be closed.
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

  // Widget _buildHeader(String userName) {
  //   return Material(
  //     type: MaterialType.transparency,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         DashboardWelcomeHeader(userName: userName, showSectionLabel: false),
  //         const SizedBox(height: 16),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: MultiBlocProvider(
        providers: DashboardInitializationService.initializeStaffDashboardProviders(),
        child: _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return GlobalScaffold(
      showCustomNavigationBar: true,
      bodyPadding: EdgeInsets.zero,
      body: Material(
        type: MaterialType.transparency,
        child: BlocBuilder<StaffDashboardCubit, StaffDashboardState>(
          builder: (context, dashState) {
            return CustomRefreshIndicator(
              onRefresh: () => Future.wait([
                context.read<MyDayCubit>().refresh(),
                context.read<MyAttendanceCubit>().refresh(),
                context.read<MyShiftsCubit>().load(forceRefresh: true),
              ]),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double gutter = constraints.maxWidth < 360 ? 12 : 16;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // SliverPadding(
                          //   padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                          //   sliver: SliverToBoxAdapter(
                          //     child: _buildHeader(dashState.userName),
                          //   ),
                          // ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              gutter,
                              24,
                              gutter,
                              28,
                            ),
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
                                      child: _cardFor(card),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
