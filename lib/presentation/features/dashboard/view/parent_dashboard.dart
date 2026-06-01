import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
// import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_childs_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_billing_card.dart';
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
  late final ParentDashboardCubit _dashboardCubit;
  late final MyChildsDayCubit _myChildsDayCubit;
  late final StudentAttendanceProfileCubit _studentAttendanceProfileCubit;
  late final CommunicationCubit _communicationCubit;
  late final StudentNewslettersCubit _studentNewslettersCubit;
  late final GeofenceCubit _geofenceCubit;

  static const double _maxContentWidth = 640;

  @override
  void initState() {
    super.initState();
    _dashboardCubit = serviceLocator<ParentDashboardCubit>();
    _myChildsDayCubit = serviceLocator<MyChildsDayCubit>();
    _studentAttendanceProfileCubit =
        serviceLocator<StudentAttendanceProfileCubit>();
    _communicationCubit = serviceLocator<CommunicationCubit>();
    _studentNewslettersCubit = serviceLocator<StudentNewslettersCubit>();
    _geofenceCubit = serviceLocator<GeofenceCubit>();
    // ignore: discarded_futures
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
    // ignore: discarded_futures
    _dashboardCubit.close();
    // ignore: discarded_futures
    _myChildsDayCubit.close();
    // ignore: discarded_futures
    _studentAttendanceProfileCubit.close();
    // ignore: discarded_futures
    _communicationCubit.close();
    // ignore: discarded_futures
    _studentNewslettersCubit.close();
    // GeofenceCubit is a singleton — do NOT close it here; it must survive navigation.
    super.dispose();
  }

  Widget _cardFor(ParentDashboardCard card) {
    switch (card) {
      case ParentDashboardCard.myChildsDay:
        return const MyChildsDayCard();
      case ParentDashboardCard.studentAttendance:
        return const StudentAttendanceCard();
      case ParentDashboardCard.studentBilling:
        return const StudentBillingCard();
      case ParentDashboardCard.studentNewsletters:
        return const StudentNewslettersCard();
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<ParentDashboardCubit>.value(value: _dashboardCubit),
        BlocProvider<MyChildsDayCubit>.value(value: _myChildsDayCubit),
        BlocProvider<StudentAttendanceProfileCubit>.value(
          value: _studentAttendanceProfileCubit,
        ),
        BlocProvider<CommunicationCubit>.value(value: _communicationCubit),
        BlocProvider<StudentNewslettersCubit>.value(
          value: _studentNewslettersCubit,
        ),
        BlocProvider<GeofenceCubit>.value(value: _geofenceCubit),
      ],
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return GlobalScaffold(
      showCustomNavigationBar: true,
      isParent: true,
      bodyPadding: EdgeInsets.zero,
      body: Material(
        type: MaterialType.transparency,
        child: BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
          builder: (context, dashState) {
            return CustomRefreshIndicator(
              onRefresh: () => Future<void>.value(),
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
                          //   padding:
                          //       EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
                          //   sliver: SliverToBoxAdapter(
                          //     child: _buildHeader(dashState.userName),
                          //   ),
                          // ),
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
