import '../entities/calendar_feed_item.dart';
import '../repositories/event_repository.dart';

class GetCalendarFeedUseCase {
  GetCalendarFeedUseCase(this._repository);

  final EventRepository _repository;

  /// Unified calendar feed for [from]..[to]. [scope] = ALL_ITEMS (admin)
  /// or MY_ITEMS; [partyCode] identifies the caller for MY_ITEMS.
  Future<List<CalendarFeedItem>> call({
    required DateTime from,
    required DateTime to,
    required String scope,
    String partyCode = '',
  }) {
    return _repository.getCalendarFeed(
      from: from,
      to: to,
      scope: scope,
      partyCode: partyCode,
    );
  }
}
