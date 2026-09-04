import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/notifications/models/notification_item.dart';

/// One page of the inbox, as the fetch returned it.
///
/// [unreadCount] is the authoritative total across every page, which is what
/// the bell shows and what gates Mark all as read; the loaded rows are only
/// ever part of it. [asOf] is the school's own clock at the moment the page
/// was read, and every relative time on the screen is measured against it
/// rather than the device clock, which is the app's own rule about time.
@immutable
class NotificationFeed extends Equatable {
  const NotificationFeed({
    required this.asOf,
    this.items = const <NotificationItem>[],
    this.hasMore = false,
    this.unreadCount = 0,
  });

  final List<NotificationItem> items;

  /// Whether there is a page after this one.
  final bool hasMore;

  final int unreadCount;
  final DateTime asOf;

  @override
  List<Object?> get props => [items, hasMore, unreadCount, asOf];
}
