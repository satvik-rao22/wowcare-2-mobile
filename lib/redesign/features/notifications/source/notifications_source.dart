import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';

/// Where M12 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation over the four usecases the inbox already has.
///
/// Nothing here is new API work:
/// * [loadPage] is `GetNotificationsUseCase` with the arguments the shipped
///   center already sends (`page`, `size`, `module`, `onlyShowUnread`), plus
///   `GetNotificationUnreadCountsUseCase` for the total that spans pages;
/// * [markRead] and [markAllRead] are the two mark usecases;
/// * [arrivals] is `NotificationEvents.inboxChanged`, the signal the FCM
///   foreground handler already fires and the shipped screen already listens
///   to.
///
/// The filter and the unread switch are **server-side** in the shipped app,
/// which is why they are arguments here rather than something the cubit does
/// to a list it already holds.
abstract interface class NotificationsSource {
  /// One page of the inbox for [persona]. The persona is the scope: the
  /// server decides what a role may be told about before it reaches the
  /// phone, so a module a persona cannot open never appears here.
  Future<NotificationFeed> loadPage({
    required Persona persona,
    required int page,
    required int pageSize,
    NotificationFilter filter = NotificationFilter.all,
    bool onlyUnread = false,
  });

  Future<void> markRead(String id);

  Future<void> markAllRead();

  /// Fires when a push lands while the center is open, so the list can
  /// reload itself (12b's "one arrives").
  Stream<void> get arrivals;
}

/// The inbox could not be read.
class NotificationsUnavailable implements Exception {
  const NotificationsUnavailable();

  @override
  String toString() => 'NotificationsUnavailable';
}
