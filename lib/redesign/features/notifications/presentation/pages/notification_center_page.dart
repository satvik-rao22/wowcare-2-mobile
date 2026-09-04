import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/badge_cubit.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/offline_banner.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/notifications/cubit/notification_center_cubit.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/notification_routing.dart';
import 'package:wowcare/redesign/features/notifications/notifications_formats.dart';
import 'package:wowcare/redesign/features/notifications/notifications_sizes.dart';
import 'package:wowcare/redesign/features/notifications/notifications_strings.dart';
import 'package:wowcare/redesign/features/notifications/notifications_text_styles.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/loading_more_footer.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/notification_filter_chips.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/notification_row.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/notification_skeleton.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/notification_toolbar.dart';

/// 12a, 12b and 12c. The notification center, reached from the bell in the
/// dashboard header.
///
/// It stays inside the shell with nothing lit: the bell is not a slot, and
/// the five slots are still where you would want to go next. Reading a row
/// drops the bell's badge as it happens, and Mark all as read takes it to
/// nothing at once.
class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final persona = context.read<SessionCubit>().state.persona;

    return BlocProvider<NotificationCenterCubit>(
      create: (_) {
        final cubit = redesignLocator<NotificationCenterCubit>(param1: persona);
        unawaited(cubit.load());
        return cubit;
      },
      child: const _NotificationCenterView(),
    );
  }
}

class _NotificationCenterView extends StatelessWidget {
  const _NotificationCenterView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationCenterCubit>();

    return MultiBlocListener(
      listeners: [
        // The bell's count is this screen's to keep honest: it is the same
        // total, and reading one row here is what makes it drop there.
        BlocListener<NotificationCenterCubit, NotificationCenterState>(
          listenWhen: (previous, current) =>
              previous.unreadCount != current.unreadCount &&
              !current.isFailed &&
              !current.isLoading,
          listener: (context, state) =>
              context.read<BadgeCubit>().setNotifications(state.unreadCount),
        ),
        // The feed is scoped to one persona. If 13d flips it under us, the
        // safe answer is the dashboard, not somebody else's inbox.
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) =>
              previous.persona != current.persona,
          listener: (context, state) => context.go(AppRoutes.dashboard),
        ),
      ],
      child: BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
        builder: (context, state) {
          final isBare = state.isLoading && state.isEmpty;

          return ScreenScaffold(
            header: const AppHeaderBar(
              title: NotificationsStrings.title,
              leading: BackKey(),
            ),
            bodyPadding: EdgeInsets.zero,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!isBare) _UnreadLine(state: state),
                Padding(
                  padding: const EdgeInsets.only(
                    top: NotificationsSizes.chipsTopPad,
                  ),
                  child: NotificationFilterChips(
                    filters: state.chips,
                    selected: state.filter,
                    onSelect: (filter) => unawaited(cubit.setFilter(filter)),
                  ),
                ),
                if (!isBare)
                  NotificationToolbar(
                    canMarkAll: state.hasUnread && !state.isWorking,
                    onlyUnread: state.onlyUnread,
                    onMarkAll: () => unawaited(_markAll(context)),
                    onToggleUnread: (value) =>
                        unawaited(cubit.setOnlyUnread(value: value)),
                  ),
                Expanded(child: _Body(state: state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAll(BuildContext context) async {
    final cubit = context.read<NotificationCenterCubit>();
    final didMark = await cubit.markAllRead();
    if (!context.mounted) return;
    showAppToast(
      context,
      didMark
          ? NotificationsStrings.markedAllRead
          : NotificationsStrings.markFailed,
      tone: didMark ? ToastTone.ok : ToastTone.error,
    );
  }
}

/// "7 unread" under the title, or "All read" once there is nothing left.
class _UnreadLine extends StatelessWidget {
  const _UnreadLine({required this.state});

  final NotificationCenterState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: NotificationsSizes.unreadLinePad,
      child: Text(
        state.hasUnread
            ? NotificationsStrings.unread(state.unreadCount)
            : NotificationsStrings.allRead,
        style: NotificationsTextStyles.unreadLine.copyWith(
          color: state.hasUnread ? c.onPinkTint : c.ink3,
        ),
      ),
    );
  }
}

/// The list, or the state standing in for it (12b).
class _Body extends StatelessWidget {
  const _Body({required this.state});

  final NotificationCenterState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationCenterCubit>();

    if (state.isLoading && state.isEmpty) {
      return const SingleChildScrollView(
        padding: NotificationsSizes.listPad,
        child: NotificationSkeleton(),
      );
    }

    if (state.isFailed) {
      return _Centered(
        child: ErrorState(
          title: NotificationsStrings.errorTitle,
          message: NotificationsStrings.errorBody,
          icon: AppIcons.alertCircle,
          onRetry: () => unawaited(cubit.load()),
        ),
      );
    }

    if (state.isEmpty) {
      return _Centered(
        child: EmptyState(
          icon: AppIcons.bell,
          title: state.isNarrowed
              ? NotificationsStrings.filteredEmptyTitle
              : NotificationsStrings.emptyTitle,
          subtitle: state.isNarrowed
              ? NotificationsStrings.filteredEmptyBody
              : NotificationsStrings.emptyBody,
        ),
      );
    }

    return _NotificationList(state: state);
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: NotificationsSizes.emptyPad,
    child: Align(alignment: Alignment.topCenter, child: child),
  );
}

/// The rows, banded by day, paging as the end comes into view.
class _NotificationList extends StatefulWidget {
  const _NotificationList({required this.state});

  final NotificationCenterState state;

  @override
  State<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<_NotificationList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Ten at a time: the next page is asked for while the last one is still
  /// on screen, so the list never stops under a moving finger.
  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >=
        position.maxScrollExtent - NotificationsSizes.pageTrigger) {
      unawaited(context.read<NotificationCenterCubit>().loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final state = widget.state;
    final cubit = context.read<NotificationCenterCubit>();

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      color: c.pink,
      backgroundColor: c.card,
      child: ListView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: NotificationsSizes.listPad.copyWith(
          bottom: AppSizes.screenBottomPad,
        ),
        children: <Widget>[
          if (state.isCached) const _Banner(),
          if (state.hasArrived)
            _Banner(
              message: NotificationsStrings.arrived,
              onTap: cubit.dismissArrival,
            ),
          for (final group in state.groups) ...<Widget>[
            Padding(
              padding: NotificationsSizes.bandPad,
              child: SectionEyebrow(
                label: NotificationsFormats.dayLabel(group.day),
              ),
            ),
            const SizedBox(height: NotificationsSizes.bandGap),
            for (final item in group.items) ...<Widget>[
              NotificationRow(
                item: item,
                now: state.clock,
                onTap: () => _open(context, item),
              ),
              const SizedBox(height: NotificationsSizes.listGap),
            ],
          ],
          if (state.isLoadingMore) const LoadingMoreFooter(),
        ],
      ),
    );
  }

  /// 12c. Reading it and opening it are the same tap: the row goes quiet and
  /// the app lands where the notification is about. A module that is not
  /// rebuilt yet says so rather than opening a screen that is not there.
  void _open(BuildContext context, NotificationItem item) {
    unawaited(context.read<NotificationCenterCubit>().markRead(item.id));

    final persona = context.read<SessionCubit>().state.persona;
    final destination = NotificationRouting.destinationOf(
      item,
      persona: persona,
    );

    switch (destination) {
      case NotificationRoute(:final location):
        unawaited(context.push<void>(location));
      case NotificationNotBuilt():
        showAppToast(context, AppStrings.comingSoon);
    }
  }
}

/// The navy strip over the list: the copy that is on screen is not live, or
/// a push landed while it was open.
class _Banner extends StatelessWidget {
  const _Banner({this.message, this.onTap});

  final String? message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final banner = Padding(
      padding: const EdgeInsets.only(bottom: NotificationsSizes.listGap),
      child: message == null
          ? const OfflineBanner()
          : OfflineBanner(message: message!),
    );

    if (onTap == null) return banner;
    return Pressable.surface(onTap: onTap, child: banner);
  }
}
