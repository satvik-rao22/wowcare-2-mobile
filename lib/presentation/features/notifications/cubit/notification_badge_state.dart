part of 'notification_badge_cubit.dart';

class NotificationBadgeState extends Equatable {
  const NotificationBadgeState({
    required this.unreadCount,
    required this.unclickedCount,
  });

  const NotificationBadgeState.initial() : unreadCount = 0, unclickedCount = 0;

  final int unreadCount;
  final int unclickedCount;

  NotificationBadgeState copyWith({int? unreadCount, int? unclickedCount}) {
    return NotificationBadgeState(
      unreadCount: unreadCount ?? this.unreadCount,
      unclickedCount: unclickedCount ?? this.unclickedCount,
    );
  }

  @override
  List<Object?> get props => [unreadCount, unclickedCount];
}
