import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';

/// Adapts lightweight calendar-feed rows to the entities the existing
/// [TaskCard] / [EventCard] widgets render, so the calendar reuses the
/// Tasks and Events module cards instead of a bespoke tile.
extension CalendarFeedItemMappers on CalendarFeedItem {
  /// Feed task row -> [Task]. `code` is the assignment code (TSA_…) that
  /// status/priority mutations act on; the rest is card-level data.
  Task toTask() {
    final due = dueDate ?? date;
    return Task(
      code: code,
      taskCode: taskCode,
      title: name,
      description: description,
      assigneeCode: assigneeCode,
      status: TaskStatus.fromValue(status),
      priority: TaskPriority.fromValue(priority),
      startDate: date,
      startTime: startTime.isEmpty ? '09:00' : startTime,
      dueDate: due,
      dueTime: endTime.isEmpty ? '17:00' : endTime,
      recurring: recurring,
      createdAt: date,
      updatedAt: date,
    );
  }

  /// Feed event row -> [Event] for [EventCard]. Rosters aren't in the feed
  /// (detail hydrates them), so attendee lists stay empty; the card only
  /// needs name/time/type/counts.
  Event toEvent() {
    return Event(
      code: eventCode,
      occurrenceCode: code,
      type: EventType.fromValue(eventType),
      name: name,
      description: description,
      date: date,
      allDay: allDay,
      startTime: startTime,
      endTime: endTime,
      includeParents: includeParents,
      recurring: recurring,
      createdBy: createdBy,
      createdAt: date,
      updatedAt: date,
    );
  }
}
