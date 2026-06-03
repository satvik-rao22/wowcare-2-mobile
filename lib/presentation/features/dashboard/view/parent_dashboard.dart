import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/dashboard/constants/dashboard_constants.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/services/dashboard_initialization_service.dart';
// import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_childs_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_newsletters_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  static const String routeName = '/parent-dashboard';

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(DashboardInitializationService.loadParentDashboardData(context));
    });
  }

  @override
  void dispose() {
    // Note: All non-singleton cubits are closed automatically when they go out of scope.
    // GeofenceCubit is a singleton managed by ServiceLocator and must NOT be closed.
    super.dispose();
  }

  Widget _cardFor(ParentDashboardCard card) {
    switch (card) {
      case ParentDashboardCard.myChildsDay:
        return const MyChildsDayCard();
      case ParentDashboardCard.studentAttendance:
        return const StudentAttendanceCard();
      // case ParentDashboardCard.studentBilling:
      //   return const StudentBillingCard();
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
      providers: DashboardInitializationService.initializeParentDashboardProviders(),
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
        child: CustomRefreshIndicator(
          onRefresh: () => Future<void>.value(),
          child: _DashboardCardList(cardFor: _cardFor),
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
