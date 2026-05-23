import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_welcome_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_childs_day_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_billing_card.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/student_newsletters_card.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/parent_dashboard_viewmodel.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Parent / guardian dashboard screen.
///
/// Composes the welcome header and the reusable dashboard cards into a single
/// vertically scrolling, pull-to-refresh feed. Cards can be drag-and-drop
/// reordered (long-press a card to drag it).
///
/// The card list and ordering come from [ParentDashboardViewModel] (MVVM): the
/// view only maps card identifiers to widgets and never owns dashboard state
/// itself.
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  static const String routeName = '/parent-dashboard';

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final ParentDashboardViewModel _viewModel = ParentDashboardViewModel();

  /// Max content width so the feed stays readable on tablets / large screens.
  static const double _maxContentWidth = 640;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Maps a [ParentDashboardCard] identifier to its widget.
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
    return GlobalScaffold(
      showCustomNavigationBar: true,
      isParent: true,
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
                            padding:
                                EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
                            sliver:
                                SliverToBoxAdapter(child: _buildHeader()),
                          ),
                          // Reorderable cards — long-press a card to drag it.
                          SliverPadding(
                            padding:
                                EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
                            sliver: SliverReorderableList(
                              itemCount: cards.length,
                              onReorder: _viewModel.reorderCard,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                return ReorderableDelayedDragStartListener(
                                  key: ValueKey(card),
                                  index: index,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16),
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
