import '../repositories/notification_center_repository.dart';

/// Fetches the authoritative unread / unclicked notification totals (across all
/// pages) for the bell badge and mark-all gating.
class GetNotificationUnreadCountsUseCase {
  GetNotificationUnreadCountsUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<({int unread, int unclicked})> call() => _repository.getUnreadCounts();
}
