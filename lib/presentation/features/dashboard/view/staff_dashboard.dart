import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
// import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
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
  late final StaffDashboardCubit _dashboardCubit;
  late final GeofenceCubit _geofenceCubit;
  late final RatioMonitoringCubit _ratioMonitoringCubit;
  late final MyDayCubit _myDayCubit;
  late final MyAttendanceCubit _myAttendanceCubit;
  late final MyShiftsCubit _myShiftsCubit;

  static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _dashboardCubit = serviceLocator<StaffDashboardCubit>();
    _geofenceCubit = serviceLocator<GeofenceCubit>();
    _ratioMonitoringCubit = serviceLocator<RatioMonitoringCubit>();
    _myDayCubit = serviceLocator<MyDayCubit>();
    _myAttendanceCubit = serviceLocator<MyAttendanceCubit>();
    _myShiftsCubit = serviceLocator<MyShiftsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initGeofence());
      _myDayCubit.load(isSilent: true);
    });
  }

  Future<void> _initGeofence() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);
    if (schoolCode != null && schoolCode.isNotEmpty) {
      await _geofenceCubit.initForSchool(schoolCode: schoolCode);
    }
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _dashboardCubit.close();
    // GeofenceCubit is a singleton — do NOT close it here; it must survive navigation.
    // ignore: discarded_futures
    _ratioMonitoringCubit.close();
    // ignore: discarded_futures
    _myDayCubit.close();
    // ignore: discarded_futures
    _myAttendanceCubit.close();
    // ignore: discarded_futures
    _myShiftsCubit.close();
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
        providers: [
          BlocProvider<StaffDashboardCubit>.value(value: _dashboardCubit),
          BlocProvider<GeofenceCubit>.value(value: _geofenceCubit),
          BlocProvider<RatioMonitoringCubit>.value(
            value: _ratioMonitoringCubit,
          ),
          BlocProvider<MyDayCubit>.value(value: _myDayCubit),
          BlocProvider<MyShiftsCubit>.value(value: _myShiftsCubit),
          BlocProvider<MyAttendanceCubit>.value(value: _myAttendanceCubit),
        ],
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
                _myDayCubit.refresh(),
                _myAttendanceCubit.refresh(),
                _myShiftsCubit.load(forceRefresh: true),
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
