import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/constants/dashboard_constants.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/school_status_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/services/dashboard_initialization_service.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/attention_grid.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/availability_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/classroom_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/enrollment_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/movements_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const String routeName = '/admin-dashboard';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(DashboardInitializationService.loadAdminDashboardData(context));
    });
  }

  @override
  void dispose() {
    // Note: All non-singleton cubits are closed automatically when they go out of scope.
    // GeofenceCubit is a singleton managed by ServiceLocator and must NOT be closed.
    super.dispose();
  }

  Widget _cardFor(AdminDashboardCard card) {
    switch (card) {
      case AdminDashboardCard.myDay:
        return const MyDayCard();
      case AdminDashboardCard.enrollment:
        return const EnrollmentCard(isDashboard: true);
      case AdminDashboardCard.ratioMonitoring:
        return const RatioMonitoringCard();
      case AdminDashboardCard.classroomShifts:
        return const ClassroomShiftsCard();
      case AdminDashboardCard.availability:
        return const AvailabilityCard();
      case AdminDashboardCard.movements:
        return const MovementsCard();
      case AdminDashboardCard.attentionGrid:
        return const AttentionGrid();
      // case AdminDashboardCard.billing:
      //   return const BillingCard();
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
      providers: DashboardInitializationService.initializeAdminDashboardProviders(),
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
                final schoolCode = await storage.getString(
                  StorageKeys.schoolCode,
                );
                if (!context.mounted) return;
                if (schoolCode != null && schoolCode.isNotEmpty) {
                  final availabilityCubit = context.read<FutureAvailabilityCubit>();
                  await Future.wait([
                    context.read<SchoolStatusCubit>().loadSchoolStatus(
                      schoolCode: schoolCode,
                      forceRefresh: true,
                    ),
                    context.read<RatioMonitoringCubit>().loadRatioMonitoring(
                      schoolCode: schoolCode,
                      forceRefresh: true,
                    ),
                    context.read<IndividualMovementsCubit>().refresh(),
                    availabilityCubit.refresh(
                      date: availabilityCubit.state.selectedDate ?? DateTime.now(),
                      isTwoShifts: true,
                    ),
                    context.read<DashboardAttentionCubit>().refresh(),
                    context.read<MyDayCubit>().refresh(),
                  ]);
                }
              },
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
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                            sliver: SliverToBoxAdapter(
                              child: _buildHeader(dashState.userName),
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
