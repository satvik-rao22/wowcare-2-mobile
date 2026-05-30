import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/classroom_progress_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/events_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/todo_card.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/staff_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Staff dashboard screen.
///
/// Composes the welcome header and the reusable dashboard cards into a single
/// vertically scrolling, pull-to-refresh feed. Cards can be drag-and-drop
/// reordered (long-press a card to drag it).
///
/// The card list and ordering come from [StaffDashboardViewModel] (MVVM): the
/// view only maps card identifiers to widgets and never owns dashboard state
/// itself.
class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  static const String routeName = '/staff-dashboard';

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final StaffDashboardViewModel _viewModel = StaffDashboardViewModel();
  late final GeofenceCubit _geofenceCubit;
  late final RatioMonitoringCubit _ratioMonitoringCubit;

  /// Max content width so the feed stays readable on tablets / large screens.
  static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _geofenceCubit = serviceLocator<GeofenceCubit>();
    _ratioMonitoringCubit = serviceLocator<RatioMonitoringCubit>();
    _initGeofence();
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
    _geofenceCubit.close();
    _ratioMonitoringCubit.close();
    _viewModel.dispose();
    super.dispose();
  }

  /// Maps a [StaffDashboardCard] identifier to its widget.
  Widget _cardFor(StaffDashboardCard card) {
    switch (card) {
      case StaffDashboardCard.myDay:
        return const MyDayCard();
      case StaffDashboardCard.ratioMonitoring:
        return const RatioMonitoringCard();
      // case StaffDashboardCard.events:
      //   return const EventsCard();
      // case StaffDashboardCard.todo:
      //   return const TodoCard();
      case StaffDashboardCard.myShifts:
        return const MyShiftsCard();
      case StaffDashboardCard.myAttendance:
        return const MyAttendanceCard();
      // case StaffDashboardCard.classroomProgress:
      //   return const ClassroomProgressCard();
    }
  }

  /// Greeting header, shown above the cards. Fixed — only cards reorder.
  Widget _buildHeader() {
    // Transparent Material so InkWell ripples in the header have an ancestor.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardWelcomeHeader(
            userName: _viewModel.userName,
            showSectionLabel: false,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GeofenceCubit>.value(value: _geofenceCubit),
        BlocProvider<RatioMonitoringCubit>.value(value: _ratioMonitoringCubit),
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
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final cards = _viewModel.visibleCards;

            return CustomRefreshIndicator(
              onRefresh: _viewModel.refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Page gutter scales down a little on narrow phones.
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
                          // Fixed (non-reorderable) header section.
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                            sliver: SliverToBoxAdapter(child: _buildHeader()),
                          ),
                          // Reorderable cards — long-press a card to drag it.
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
                            sliver: SliverReorderableList(
                              itemCount: cards.length,
                              onReorder: _viewModel.reorderCard,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                return ReorderableDelayedDragStartListener(
                                  key: ValueKey(card),
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    // Transparent Material so InkWell ripples
                                    // in the card have an ancestor.
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
