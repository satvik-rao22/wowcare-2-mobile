import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/attention_grid.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/availability_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/billing_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/classroom_progress_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/classroom_shifts_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/enrollment_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/events_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/movements_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/ratio_monitoring_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/todo_card.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/admin_dashboard_viewmodel.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Admin dashboard screen.
///
/// Composes the welcome header, the "Need your attention" grid, and the
/// reusable dashboard cards into a single vertically scrolling, pull-to-refresh
/// feed. Cards can be drag-and-drop reordered (long-press a card to drag it).
///
/// The card list and ordering come from [AdminDashboardViewModel] (MVVM): the
/// view only maps card identifiers to widgets and never owns dashboard state
/// itself.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const String routeName = '/admin-dashboard';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminDashboardViewModel _viewModel = AdminDashboardViewModel();

  /// Max content width so the feed stays readable on tablets / large screens
  /// instead of stretching cards edge to edge.
  static const double _maxContentWidth = 640;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Maps a [AdminDashboardCard] identifier to its widget.
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
      case AdminDashboardCard.events:
        return const EventsCard();
      case AdminDashboardCard.todo:
        return const TodoCard();
      case AdminDashboardCard.availability:
        return const AvailabilityCard();
      case AdminDashboardCard.movements:
        return const MovementsCard();
      case AdminDashboardCard.billing:
        return const BillingCard();
      case AdminDashboardCard.classroomProgress:
        return const ClassroomProgressCard();
    }
  }

  /// Greeting header + "Need your attention" grid, shown above the cards.
  /// This section is fixed — only the cards below it can be reordered.
  Widget _buildHeader() {
    // Transparent Material so InkWell ripples in the header have an ancestor.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardWelcomeHeader(userName: _viewModel.userName),
          const SizedBox(height: 16),
          const AttentionGrid(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      showCustomNavigationBar: true,
      bodyPadding: EdgeInsets.zero,
      // Transparent Material so InkWell ripples in the cards have an ancestor.
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
                // Horizontal page gutter scales down a little on narrow phones.
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
                                  // Transparent Material so InkWell ripples in
                                  // the card have an ancestor (the dragged
                                  // proxy is hosted outside the body Material).
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
