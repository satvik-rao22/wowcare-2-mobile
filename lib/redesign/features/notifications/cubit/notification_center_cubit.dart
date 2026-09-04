import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/notifications_formats.dart';
import 'package:wowcare/redesign/features/notifications/source/notifications_source.dart';

part 'notification_center_state.dart';

/// 12a and 12b. The inbox, what narrows it, and what it says when there is
/// nothing to show.
///
/// The list is paged ten at a time and the next page is fetched as the end of
/// the list comes into view, which is what the shipped center already does and
/// says nowhere on screen. Here the footer says it.
///
/// The filter chips and the unread switch are **server-side** filters, so
/// either one refetches from page one rather than hiding rows the phone
/// already has. That is the shipped contract (`module` and `onlyShowUnread`
/// query parameters), and it is also the only way the unread total stays
/// honest across pages.
///
/// The persona is passed in rather than read off a locator: the screen is
/// built for one person, and the feed the server hands back is already scoped
/// to what that person may be told about.
class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit({
    required NotificationsSource source,
    required Persona persona,
  }) : _source = source,
       super(NotificationCenterState(persona: persona)) {
    _arrivals = _source.arrivals.listen((_) => unawaited(_onArrival()));
  }

  /// What the shipped center asks for: ten rows a page.
  static const int pageSize = 10;

  final NotificationsSource _source;
  late final StreamSubscription<void> _arrivals;

  bool _isFetching = false;

  /// [isSilent] keeps the list on screen while it refetches behind it, so a
  /// pull to refresh and a push arriving never flash the skeleton.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) {
      emit(state.copyWith(status: NotificationCenterStatus.loading));
    }

    try {
      final feed = await _fetch(page: 0);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: NotificationCenterStatus.ready,
          items: feed.items,
          page: 0,
          hasMore: feed.hasMore,
          unreadCount: feed.unreadCount,
          asOf: feed.asOf,
          isLoadingMore: false,
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      // Something already on screen is worth more than an error page: the
      // list stays and the banner says it is not live.
      emit(
        state.copyWith(
          status: state.items.isEmpty
              ? NotificationCenterStatus.failed
              : NotificationCenterStatus.cached,
          isLoadingMore: false,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// The next ten, appended. Fired by the list reaching its end, so it must
  /// be safe to call again before the last one has answered.
  Future<void> loadMore() async {
    if (_isFetching || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true));

    final next = state.page + 1;
    try {
      final feed = await _fetch(page: next);
      if (isClosed) return;
      // De-duped defensively: a row read between two fetches shifts the page
      // boundary under us.
      final seen = state.items.map((i) => i.id).toSet();
      emit(
        state.copyWith(
          status: NotificationCenterStatus.ready,
          items: <NotificationItem>[
            ...state.items,
            for (final item in feed.items)
              if (!seen.contains(item.id)) item,
          ],
          page: next,
          hasMore: feed.hasMore,
          unreadCount: feed.unreadCount,
          asOf: feed.asOf,
          isLoadingMore: false,
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: NotificationCenterStatus.cached,
          isLoadingMore: false,
        ),
      );
    }
  }

  /// A filter chip. Server-side, so the list starts again at page one.
  Future<void> setFilter(NotificationFilter filter) async {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter, items: const <NotificationItem>[]));
    await load();
  }

  Future<void> setOnlyUnread({required bool value}) async {
    if (value == state.onlyUnread) return;
    emit(state.copyWith(onlyUnread: value, items: const <NotificationItem>[]));
    await load();
  }

  /// Reading one row. Optimistic, because the row must go quiet under the
  /// finger that opened it; a write that fails puts the dot back.
  Future<void> markRead(String id) async {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index < 0 || state.items[index].isRead) return;

    final previousItems = state.items;
    final previousUnread = state.unreadCount;
    emit(
      state.copyWith(
        items: <NotificationItem>[
          for (final item in previousItems)
            if (item.id == id) item.copyWith(isRead: true) else item,
        ],
        unreadCount: previousUnread > 0 ? previousUnread - 1 : 0,
        isWorking: true,
      ),
    );

    try {
      await _source.markRead(id);
      if (!isClosed) emit(state.copyWith(isWorking: false));
    } on Exception catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          items: previousItems,
          unreadCount: previousUnread,
          isWorking: false,
        ),
      );
    }
  }

  /// Mark all as read. Returns whether it went through, so the screen knows
  /// which toast to put up.
  Future<bool> markAllRead() async {
    if (!state.hasUnread || state.isWorking) return false;

    final previousItems = state.items;
    final previousUnread = state.unreadCount;
    emit(
      state.copyWith(
        items: <NotificationItem>[
          for (final item in previousItems) item.copyWith(isRead: true),
        ],
        unreadCount: 0,
        isWorking: true,
      ),
    );

    try {
      await _source.markAllRead();
      if (!isClosed) emit(state.copyWith(isWorking: false));
      return true;
    } on Exception catch (_) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          items: previousItems,
          unreadCount: previousUnread,
          isWorking: false,
        ),
      );
      return false;
    }
  }

  /// The reader has seen the "one arrived" line.
  void dismissArrival() {
    if (state.hasArrived) emit(state.copyWith(hasArrived: false));
  }

  /// A push landed while this screen was open. The list reloads itself, and
  /// says so, rather than quietly going stale.
  Future<void> _onArrival() async {
    if (isClosed) return;
    emit(state.copyWith(hasArrived: true));
    await load(isSilent: true);
  }

  Future<NotificationFeed> _fetch({required int page}) => _source.loadPage(
    persona: state.persona,
    page: page,
    pageSize: pageSize,
    filter: state.filter,
    onlyUnread: state.onlyUnread,
  );

  @override
  Future<void> close() async {
    await _arrivals.cancel();
    return super.close();
  }
}
