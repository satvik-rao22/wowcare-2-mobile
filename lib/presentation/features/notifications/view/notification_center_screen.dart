import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../domain/features/notifications/entities/app_notification.dart';
import '../../../../domain/features/notifications/entities/notification_category.dart';
import '../../../../src/app_router.dart';
import '../cubit/notification_center_cubit.dart';
import '../routing/notification_route_resolver.dart';
import '../widgets/notification_card.dart';

/// The notification center opened from the app-bar bell.
///
/// Pure View: it renders [NotificationCenterState] and forwards user intent to
/// [NotificationCenterCubit] (filter, toggle, mark-read). No business logic or
/// data access lives here. The cubit is provided by the route (see app_router).
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  static const String routeName = '/notifications';

  /// Category labels for the filter dropdown ("All" is the cleared/hint state).
  static const String _allLabel = 'All';

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      // Same app-wide bottom nav as the shell. The bar handles being rendered
      // outside the shell: tapping a tab routes into that branch via
      // `context.go(branchRoot)` (see CustomNavigationBar).
      bottomNavigationBar: const CustomNavigationBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _Header(responsive: responsive),
                  const SizedBox(height: 16),
                  const _ActionsRow(),
                  const SizedBox(height: 12),
                  const Expanded(child: _NotificationsList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.responsive});

  final ResponsiveHelper responsive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.titleFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          child: BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
            buildWhen: (p, c) => p.categoryFilter != c.categoryFilter,
            builder: (context, state) {
              return CustomDropdown(
                hintText: NotificationCenterScreen._allLabel,
                showAsterisk: false,
                items: NotificationCategory.values
                    .map((c) => c.label)
                    .toList(),
                selectedItem: state.categoryFilter?.label,
                onSelect: (label) {
                  // Hint ("All") => null clears the filter.
                  final category = (label == null)
                      ? null
                      : NotificationCategory.values
                          .firstWhere((c) => c.label == label);
                  context
                      .read<NotificationCenterCubit>()
                      .setCategoryFilter(category);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
      buildWhen: (p, c) =>
          p.hasUnread != c.hasUnread ||
          p.onlyUnread != c.onlyUnread ||
          p.isMutating != c.isMutating,
      builder: (context, state) {
        final cubit = context.read<NotificationCenterCubit>();
        final canMarkAll = state.hasUnread && !state.isMutating;
        return Row(
          children: [
            Opacity(
              opacity: canMarkAll ? 1 : 0.5,
              child: GestureDetector(
                onTap: canMarkAll ? cubit.markAllAsRead : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.buildPrimaryGradient(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            CustomToggle(
              label: 'Only Show Unread',
              isToggled: state.onlyUnread,
              onToggle: cubit.setOnlyUnread,
              labelOnLeftSide: false,
              labelStyle: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList();

  /// Mark the item read, then deep-link where the equivalent PUSH tap would go.
  ///
  /// In-app items carry the same `action` + code keys as the FCM `data` map, so
  /// this goes through the same [NotificationRouteResolver] table as push —
  /// the two channels cannot drift apart. `go` (not `push`) is deliberate: it
  /// leaves the user on the same stack a push tap would ([Dashboard, target]),
  /// so Back behaves identically no matter which channel opened the screen.
  void _onNotificationTap(BuildContext context, AppNotification notification) {
    unawaited(
      context.read<NotificationCenterCubit>().markAsRead(notification.id),
    );
    final destination =
        NotificationRouteResolver.resolveData(notification.data);
    // No action / unmapped action, or an action whose target IS this screen
    // (TASK_DELETED): stay put — marking it read is the whole interaction.
    if (destination == null ||
        destination.path == NotificationCenterScreen.routeName) {
      return;
    }
    appRouter.go(destination.location);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: PrimaryCircularLoader());
        }

        if (state.errorMessage != null && state.items.isEmpty) {
          return _ErrorView(
            message: state.errorMessage!,
            onRetry: () => context.read<NotificationCenterCubit>().refresh(),
          );
        }

        final items = state.visibleItems;
        return CustomRefreshIndicator(
          onRefresh: () => context.read<NotificationCenterCubit>().refresh(),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    _EmptyView(),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = items[index];
                    return NotificationCard(
                      notification: notification,
                      onTap: () => _onNotificationTap(context, notification),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 56,
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'You’re all caught up',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'No notifications to show',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.redProgressBar,
            ),
            const SizedBox(height: 12),
            Text(
              'Couldn’t load notifications',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
