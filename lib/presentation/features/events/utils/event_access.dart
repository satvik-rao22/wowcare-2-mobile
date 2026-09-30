import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

/// Access rules for the Events & Holidays module (PRD §5 RBAC).
///
/// Two gates apply, in this order:
/// 1. **Module permission** from `/api/v1/users/details` (`EVENT`,
///    `EVENT_RSVP`, `HOLIDAY`, `CALENDAR`) — the backend decides whether the
///    user has the module at all, and read vs write.
/// 2. **Persona + ownership** rules the API flags cannot express: staff manage
///    only events they created, staff cannot create school-wide events, RSVP
///    summaries are admin-only.
///
/// Personas: admin (Org/School Admin — full read/write), staff (scoped
/// create, manages only own events, holidays read-only) and parent
/// (read-only, RSVP only when invited via `includeParents`).
///
/// Note: [RoleCubit.isAdmin] also returns true for staff, so the admin
/// checks here compare the raw role instead.
class EventAccess {
  EventAccess._();

  static bool isAdmin(RoleCubit roles) => roles.role == 'admin';

  /// Whether the Events screen (events / holidays / calendar tabs) may open at
  /// all. Any one of the three modules being readable is enough — the tabs and
  /// the calendar feed gate themselves individually.
  /// TEMP-EVENTS-TASKS-UNLOCK: the backend's users/details payload lists no EVENT /
  /// EVENT_RSVP / HOLIDAY / CALENDAR / TASK module, though the events-todo
  /// service serves this account normally. Restore the commented line and
  /// delete the override once the payload is fixed. Grep TEMP-EVENTS-TASKS-UNLOCK.
  // static bool canOpenModule(RoleCubit roles) => roles.canAccessAny([
  //   AppAccessModules.event,
  //   AppAccessModules.holiday,
  //   AppAccessModules.calendar,
  // ]);
  static bool canOpenModule(RoleCubit roles) => true;

  /// Admin and staff can create events; parents never can.
  /// TEMP-EVENTS-TASKS-UNLOCK: the module write grant is dropped, the parent
  /// exclusion is not.
  // static bool canCreateEvents(RoleCubit roles) =>
  //     !roles.isParent && roles.canWriteModule(AppAccessModules.event);
  static bool canCreateEvents(RoleCubit roles) => !roles.isParent;

  /// Event types the current persona may create. The Individual type is
  /// retired from creation (kept on the enum only so existing individual
  /// events still render/edit). Staff additionally cannot create school-wide
  /// events (PRD §5.1: "no school type allowed").
  static List<EventType> creatableTypes(RoleCubit roles) {
    return EventType.values.where((type) {
      if (type == EventType.individual) return false;
      if (type == EventType.school && !isAdmin(roles)) return false;
      return true;
    }).toList();
  }

  /// Add/edit/delete school holidays and approve/reject federal holidays
  /// is admin-only (PRD §5.3); staff and parents see the list read-only.
  /// TEMP-EVENTS-TASKS-UNLOCK: the module write grant is dropped, the
  /// admin-only rule is not.
  // static bool canManageHolidays(RoleCubit roles) =>
  //     isAdmin(roles) && roles.canWriteModule(AppAccessModules.holiday);
  static bool canManageHolidays(RoleCubit roles) => isAdmin(roles);

  /// RSVP counts, the summary and everyone's responses are visible to
  /// school personas (admin + staff) only — guardians see their own RSVP
  /// but never other people's (PRD FR-EV-19, BR-RSVP-04/05).
  static bool canSeeRsvpSummary(RoleCubit roles) =>
      !roles.isParent && roles.canReadModule(AppAccessModules.eventRsvp);

  /// Edit/delete an event: admins always, staff only for events they
  /// created (PRD §5.1), parents never.
  static bool canManageEvent({
    required RoleCubit roles,
    required Event event,
    required String userCode,
    String staffCode = '',
  }) {
    // TEMP-EVENTS-TASKS-UNLOCK
    // if (!roles.canWriteModule(AppAccessModules.event)) return false;
    if (isAdmin(roles)) return true;
    if (!roles.isStaff) return false;
    return _isCreator(event, userCode, staffCode);
  }

  /// Whether the current user may RSVP to [event]. Parents only when the
  /// event invites parents (BR-RSVP-03); staff when invited as a staff
  /// attendee, for school-wide events, or for their own events; admins
  /// always.
  static bool canRsvp({
    required RoleCubit roles,
    required Event event,
    required String userCode,
    String staffCode = '',
  }) {
    // Parents stay governed by the invite flag alone. Guardian payloads are
    // not confirmed to carry an EVENT_RSVP row yet, and a missing row would
    // silently remove RSVP from every parent.
    if (roles.isParent) return event.includeParents;
    // TEMP-EVENTS-TASKS-UNLOCK
    // if (!roles.canWriteModule(AppAccessModules.eventRsvp)) return false;
    if (isAdmin(roles)) return true;
    if (event.type == EventType.school) return true;
    if (_isCreator(event, userCode, staffCode)) return true;
    // When neither identity is resolved locally, stay permissive so staff
    // aren't locked out of RSVP by a cold cache.
    if (userCode.isEmpty && staffCode.isEmpty) return true;
    return event.staff.any(
      (s) =>
          s.code == userCode ||
          (staffCode.isNotEmpty && s.code == staffCode),
    );
  }

  /// Feed kinds the calendar may render. The unified feed mixes EVENT, TASK and
  /// HOLIDAY rows, so `CALENDAR` read opens the calendar surface while each row
  /// still needs its own module — otherwise a user without TASK access would
  /// read task rows through the calendar.
  static Set<CalendarFeedKind> readableCalendarKinds(RoleCubit roles) {
    return <CalendarFeedKind>{
      if (roles.canReadModule(AppAccessModules.event)) CalendarFeedKind.event,
      if (roles.canReadModule(AppAccessModules.holiday))
        CalendarFeedKind.holiday,
      if (TaskAccess.canAccessModule(roles)) CalendarFeedKind.task,
    };
  }

  static bool _isCreator(Event event, String userCode, String staffCode) {
    if (event.createdBy.isEmpty) return false;
    return event.createdBy == userCode ||
        (staffCode.isNotEmpty && event.createdBy == staffCode);
  }
}
