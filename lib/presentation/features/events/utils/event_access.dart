import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Role-based access rules for the Events & Holidays module (PRD §5 RBAC).
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

  /// Admin and staff can create events; parents never can.
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
  static bool canManageHolidays(RoleCubit roles) => isAdmin(roles);

  /// RSVP counts, summary and the responses list are admin-only
  /// (PRD FR-EV-19, BR-RSVP-04/05).
  static bool canSeeRsvpSummary(RoleCubit roles) => isAdmin(roles);

  /// Edit/delete an event: admins always, staff only for events they
  /// created (PRD §5.1), parents never.
  static bool canManageEvent({
    required RoleCubit roles,
    required Event event,
    required String userCode,
    String staffCode = '',
  }) {
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
    if (roles.isParent) return event.includeParents;
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

  static bool _isCreator(Event event, String userCode, String staffCode) {
    if (event.createdBy.isEmpty) return false;
    return event.createdBy == userCode ||
        (staffCode.isNotEmpty && event.createdBy == staffCode);
  }
}
