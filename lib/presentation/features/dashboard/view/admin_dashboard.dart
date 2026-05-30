import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
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
  late final AdminDashboardCubit _dashboardCubit;
  late final GeofenceCubit _geofenceCubit;
  late final SchoolStatusCubit _schoolStatusCubit;
  late final RatioMonitoringCubit _ratioMonitoringCubit;
  late final IndividualMovementsCubit _movementsCubit;
  late final FutureAvailabilityCubit _availabilityCubit;
  late final ClassroomShiftsCubit _classroomShiftsCubit;
  late final DashboardAttentionCubit _attentionCubit;
  late final MyDayCubit _myDayCubit;

  static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _dashboardCubit = serviceLocator<AdminDashboardCubit>();
    _geofenceCubit = serviceLocator<GeofenceCubit>();
    _schoolStatusCubit = serviceLocator<SchoolStatusCubit>();
    _ratioMonitoringCubit = serviceLocator<RatioMonitoringCubit>();
    _movementsCubit = serviceLocator<IndividualMovementsCubit>();
    _availabilityCubit = serviceLocator<FutureAvailabilityCubit>();
    _classroomShiftsCubit = serviceLocator<ClassroomShiftsCubit>();
    _attentionCubit = serviceLocator<DashboardAttentionCubit>();
    _myDayCubit = serviceLocator<MyDayCubit>();
    // ignore: discarded_futures
    _initGeofence();
    // ignore: discarded_futures
    _initRatioMonitoring();
    // ignore: discarded_futures
    _initMovements();
    // ignore: discarded_futures
    _initAvailability();
    // ignore: discarded_futures
    _attentionCubit.load(isSilent: true);
    // ignore: discarded_futures
    _myDayCubit.load(isSilent: true);
  }

  Future<void> _initMovements() async {
    await _movementsCubit.loadInitial();
  }

  Future<void> _initAvailability() async {
    await _availabilityCubit.load(date: DateTime.now(), isTwoShifts: true);
  }

  Future<void> _initRatioMonitoring() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);
    if (schoolCode != null && schoolCode.isNotEmpty && mounted) {
      try {
        await _ratioMonitoringCubit.loadRatioMonitoring(
          schoolCode: schoolCode,
          isSilent: true,
        );
      } catch (_) {}
    }
  }

  Future<void> _initGeofence() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);
    if (schoolCode != null && schoolCode.isNotEmpty) {
      _geofenceCubit.initForSchool(schoolCode: schoolCode);
    }
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _dashboardCubit.close();
    // ignore: discarded_futures
    _geofenceCubit.close();
    // ignore: discarded_futures
    _schoolStatusCubit.close();
    // ignore: discarded_futures
    _ratioMonitoringCubit.close();
    // ignore: discarded_futures
    _movementsCubit.close();
    // ignore: discarded_futures
    _availabilityCubit.close();
    // ignore: discarded_futures
    _classroomShiftsCubit.close();
    // ignore: discarded_futures
    _attentionCubit.close();
    // ignore: discarded_futures
    _myDayCubit.close();
    super.dispose();
  }

  Widget _cardFor(AdminDashboardCard card) {
    switch (card) {
      case AdminDashboardCard.myDay:
        return const MyDayCard();
      case AdminDashboardCard.enrollment:
        return const EnrollmentCard(isDashboard: true);
      case AdminDashboardCard.ratioMonitoring:
        return BlocProvider<RatioMonitoringCubit>.value(
          value: _ratioMonitoringCubit,
          child: const RatioMonitoringCard(),
        );
      case AdminDashboardCard.classroomShifts:
        return const ClassroomShiftsCard();
      case AdminDashboardCard.availability:
        return BlocProvider<FutureAvailabilityCubit>.value(
          value: _availabilityCubit,
          child: const AvailabilityCard(),
        );
      case AdminDashboardCard.movements:
        return BlocProvider<IndividualMovementsCubit>.value(
          value: _movementsCubit,
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
          const AttentionGrid(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AdminDashboardCubit>.value(value: _dashboardCubit),
        BlocProvider<GeofenceCubit>.value(value: _geofenceCubit),
        BlocProvider<SchoolStatusCubit>.value(value: _schoolStatusCubit),
        BlocProvider<RatioMonitoringCubit>.value(value: _ratioMonitoringCubit),
        BlocProvider<ClassroomShiftsCubit>.value(value: _classroomShiftsCubit),
        BlocProvider<IndividualMovementsCubit>.value(value: _movementsCubit),
        BlocProvider<FutureAvailabilityCubit>.value(value: _availabilityCubit),
        BlocProvider<DashboardAttentionCubit>.value(value: _attentionCubit),
        BlocProvider<MyDayCubit>.value(value: _myDayCubit),
      ],
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return GlobalScaffold(
      showCustomNavigationBar: true,
      bodyPadding: EdgeInsets.zero,
      body: Material(
        type: MaterialType.transparency,
        child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, dashState) {
            return CustomRefreshIndicator(
              onRefresh: () async {
                final storage = serviceLocator<StorageService>();
                final schoolCode =
                    await storage.getString(StorageKeys.schoolCode);
                if (schoolCode != null && schoolCode.isNotEmpty) {
                  await Future.wait([
                    _schoolStatusCubit.loadSchoolStatus(
                      schoolCode: schoolCode,
                      forceRefresh: true,
                    ),
                    _ratioMonitoringCubit.loadRatioMonitoring(
                      schoolCode: schoolCode,
                      forceRefresh: true,
                    ),
                    _movementsCubit.refresh(),
                    _availabilityCubit.refresh(
                      date: _availabilityCubit.state.selectedDate ??
                          DateTime.now(),
                      isTwoShifts: true,
                    ),
                    _attentionCubit.refresh(),
                    _myDayCubit.refresh(),
                  ]);
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double gutter = constraints.maxWidth < 360 ? 12 : 16;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _maxContentWidth),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding:
                                EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                            sliver: SliverToBoxAdapter(
                              child: _buildHeader(dashState.userName),
                            ),
                          ),
                          SliverPadding(
                            padding:
                                EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
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
                                    padding:
                                        const EdgeInsets.only(bottom: 16),
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
