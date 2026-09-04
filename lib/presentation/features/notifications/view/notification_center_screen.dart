import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/active_school_switcher.dart';
import 'package:wowcare/core/util/notification_events.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/src/app_router.dart';

import '../../../../domain/features/notifications/entities/app_notification.dart';
import '../widgets/notification_category_style.dart';
import '../../../../domain/features/notifications/entities/push_notification.dart';
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

  /// Interim module options for the filter dropdown. The selected value is sent
  /// as the `module` query param (server-side filter). Replace with the modules
  /// list from the backend once that endpoint is available.
  static const List<String> _filterModules = <String>[
    'ATTENDANCE',
    'CLASSROOM',
    'STUDENT',
    'STAFF',
    'BILLING',
    'SCHEDULING',
    'AVAILABILITY',
    'ACTIVITY',
    'MESSAGING',
    'NEWSLETTER',
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      // Same app-wide bottom nav as the shell. The bar handles being rendered
      // outside the shell: tapping a tab routes into that branch via
      // `context.go(branchRoot)` (see CustomNavigationBar).
      // This route lives OUTSIDE the shell, so the bar can't read a current
      // branch and would otherwise fall back to highlighting Dashboard (0).
      // The notification center isn't a tab — force "no active tab".
      bottomNavigationBar: const CustomNavigationBar(highlightNone: true),
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
        BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
          buildWhen: (p, c) => p.moduleFilter != c.moduleFilter,
          builder: (context, state) {
            // Raw module string → display label. Selecting a label maps back
            // to the raw module sent as the `module` query param.
            // TODO(notifications): source this list from the modules API
            // instead of the interim constant below.
            final modules = NotificationCenterScreen._filterModules;
            final labelToModule = <String, String>{
              for (final m in modules)
                NotificationCategoryStyle.moduleLabel(m): m,
            };
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 150,
                  child: CustomDropdown(
                    hintText: NotificationCenterScreen._allLabel,
                    showAsterisk: false,
                    items: labelToModule.keys.toList(),
                    selectedItem: state.moduleFilter == null
                        ? null
                        : NotificationCategoryStyle.moduleLabel(
                            state.moduleFilter!,
                          ),
                    onSelect: (label) {
                      // Hint ("All") => null clears the filter (server
                      // returns all).
                      final module = (label == null)
                          ? null
                          : labelToModule[label];
                      context
                          .read<NotificationCenterCubit>()
                          .setModuleFilter(module);
                    },
                  ),
                ),
                // The dropdown itself has no way back to "All" once a
                // module is picked — "All" is only its unselectable hint
                // text, not an item in the list — so this was the only way
                // to clear a filter short of leaving and reopening the
                // notification center.
                if (state.moduleFilter != null)
                  Tooltip(
                    message: 'Clear filter',
                    child: IconButton(
                      onPressed: () => context
                          .read<NotificationCenterCubit>()
                          .setModuleFilter(null),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xff573353),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
              ],
            );
          },
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

class _NotificationsList extends StatefulWidget {
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
  State<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<_NotificationsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Reload the list live when a new notification arrives while this screen
    // is open (fired by the FCM foreground handler).
    NotificationEvents.inboxChanged.addListener(_onInboxChanged);
  }

  void _onInboxChanged() {
    if (!mounted) return;
    context.read<NotificationCenterCubit>().refresh();
  }

  @override
  void dispose() {
    NotificationEvents.inboxChanged.removeListener(_onInboxChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Load the next page when within 400px of the bottom.
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<NotificationCenterCubit>().loadNextPage();
    }
  }

  /// Mark read, then deep-link to the same destination an FCM tap would, using
  /// the shared [NotificationRouteResolver] table (the notification's `data`
  /// carries `action` + the target codes).
  void _onTapNotification(AppNotification n) {
    unawaited(context.read<NotificationCenterCubit>().markAsRead(n.id));

    final message = PushNotification(
      title: n.title,
      body: n.body,
      action: n.data['action'],
      type: n.data['module'],
      data: n.data,
    );
    // Cheap, persona-independent check first so we don't switch school for an
    // action that has no in-app destination (mirrors [NotificationNavigator]).
    if (NotificationRouteResolver.resolve(message) == null) return;
    unawaited(_navigate(message));
  }

  Future<void> _navigate(PushNotification message) async {
    // Capture the role cubit before the async gap; reading `.isParent` after the
    // switch then reflects the TARGET school's persona.
    final roleCubit = context.read<RoleCubit>();
    // Switch the active org/school first if the notification targets a different
    // school the user belongs to, so the destination loads the right data.
    if (mounted) {
      await switchActiveSchoolIfNeeded(
        context: context,
        organizationCode: message.organizationCode,
        schoolCode: message.schoolCode,
      );
    }
    // Resolve with the persona: billing opens the PARENT billing screen for
    // guardians and the admin billing screen for staff/admins. Without this a
    // parent landed on the admin billing screen, which shows no data for them.
    final destination = NotificationRouteResolver.resolve(
      message,
      isGuardian: roleCubit.isParent,
    );
    if (destination == null) return;
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
        // Filters are applied server-side now, so paging works with any filter.
        final bool showFooterLoader = state.isLoadingMore;
        return CustomRefreshIndicator(
          onRefresh: () => context.read<NotificationCenterCubit>().refresh(),
          child: items.isEmpty
              ? ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    _EmptyView(),
                  ],
                )
              : ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length + (showFooterLoader ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: PrimaryCircularLoader()),
                      );
                    }
                    final notification = items[index];
                    return NotificationCard(
                      notification: notification,
                      onTap: () => _onTapNotification(notification),
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
