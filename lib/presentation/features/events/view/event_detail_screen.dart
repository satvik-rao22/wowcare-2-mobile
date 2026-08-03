import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/presentation/features/events/view/event_form_screen.dart';
import 'package:wowcare/presentation/features/events/utils/recurrence_summary.dart';
import 'package:wowcare/presentation/features/events/widgets/entity_list_sheet.dart';
import 'package:wowcare/presentation/features/events/widgets/occurrence_scope_sheet.dart';
import 'package:wowcare/presentation/features/events/widgets/event_rsvp_bar.dart';
import 'package:wowcare/presentation/features/events/widgets/event_rsvp_summary.dart';
import 'package:wowcare/presentation/features/events/widgets/event_type_chip.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_section.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    required this.eventCode,
    this.occurrenceCode = '',
    super.key,
  });

  static const String routeName = '/dashboard/events/detail';

  final String eventCode;

  /// The specific occurrence being viewed (occurrence-based reads return
  /// one row per occurrence). Empty falls back to the series' first row.
  final String occurrenceCode;

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          final event =
              state.eventByOccurrence(occurrenceCode, eventCode: eventCode);
          if (event == null) {
            // Deleted (possibly by this screen) or unknown code.
            return const Center(
              child: Text(
                'Event not found',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          // Admins manage any event; staff only their own; parents none.
          final canManage = EventAccess.canManageEvent(
            roles: roles,
            event: event,
            userCode: state.currentUserCode,
            staffCode: state.currentStaffCode,
          );
          // Occurrence rows carry the full roster — only people on it may
          // RSVP (server rule; students respond implicitly, never manually),
          // and only while the occurrence hasn't passed and `EVENT_RSVP`
          // permits responding.
          final canRsvp = state.isParticipant(event) &&
              !event.isPast &&
              EventAccess.canRsvp(
                roles: roles,
                event: event,
                userCode: state.currentUserCode,
                staffCode: state.currentStaffCode,
              );
          final canSeeSummary = EventAccess.canSeeRsvpSummary(roles);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerRow(context, event, canManage),
                const SizedBox(height: 12),
                _whenCard(event),
                if (event.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _sectionCard(
                    title: 'Description',
                    child: Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _attendeesCard(
                  context,
                  state,
                  event,
                  canSeeRsvps: canSeeSummary,
                ),
                if (event.attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _attachmentCard(context, event),
                ],
                if (canRsvp || canSeeSummary) ...[
                  const SizedBox(height: 10),
                  _rsvpCard(
                    context,
                    state,
                    event,
                    isParent: roles.isParent,
                    canRsvp: canRsvp,
                    canSeeSummary: canSeeSummary,
                  ),
                ],
                const SizedBox(height: 14),
                _footer(event),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerRow(BuildContext context, Event event, bool canManage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              EventTypeChip(type: event.type),
            ],
          ),
        ),
        if (canManage) ...[
          IconButton(
            tooltip: 'Edit event',
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.themeColor,
              size: 22,
            ),
            onPressed: () => _onEditPressed(context, event),
          ),
          IconButton(
            tooltip: 'Delete event',
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.errorColor,
              size: 22,
            ),
            onPressed: () => _onDeletePressed(context, event),
          ),
        ],
      ],
    );
  }

  Widget _whenCard(Event event) {
    return _sectionCard(
      title: 'When',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            Icons.calendar_today_outlined,
            DateFormat('EEEE, MMM d, yyyy').format(event.date),
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time, EventUiUtils.timeLabel(event)),
          if (event.recurring && event.recurrence != null) ...[
            const SizedBox(height: 6),
            _infoRow(
              Icons.repeat,
              RecurrenceSummary.describe(
                rule: event.recurrence!,
                startDate: event.date,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Compact group tiles instead of chip walls — one row per audience
  /// group ("Students (150)") that opens a member bottom sheet on tap,
  /// consistent with the create-form pickers and identical across event
  /// types. The occurrence row carries the fully hydrated roster (incl.
  /// the parent list) with per-person RSVPs — no lookups needed.
  Widget _attendeesCard(
    BuildContext context,
    EventsState state,
    Event event, {
    required bool canSeeRsvps,
  }) {
    final classrooms = event.classrooms;
    final students = event.students;
    final staff = event.staff;
    final guardians = event.parents;
    // Guardians may see WHO is invited but not how others responded, so the
    // per-person RSVP chips are dropped for them (PRD BR-RSVP-04/05).
    final rsvpByCode = canSeeRsvps
        ? {for (final r in event.rsvps) r.userCode: r}
        : const <String, EventRsvp>{};
    final childNames = {
      for (final s in event.students)
        if (s.name.isNotEmpty) s.code: s.name,
    };

    return _sectionCard(
      title: 'Attendees',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (classrooms.isNotEmpty)
            _attendeeGroupTile(
              context,
              label: 'Classrooms',
              icon: EventUiUtils.typeIcon(EventType.classroom),
              color: EventUiUtils.typeColor(EventType.classroom),
              attendees: classrooms,
              rsvpByCode: const {},
            ),
          if (students.isNotEmpty)
            _attendeeGroupTile(
              context,
              label: 'Students',
              icon: EventUiUtils.typeIcon(EventType.student),
              color: EventUiUtils.typeColor(EventType.student),
              attendees: students,
              rsvpByCode: rsvpByCode,
            ),
          if (staff.isNotEmpty)
            _attendeeGroupTile(
              context,
              label: 'Staff',
              icon: EventUiUtils.typeIcon(EventType.staff),
              color: EventUiUtils.typeColor(EventType.staff),
              attendees: staff,
              rsvpByCode: rsvpByCode,
            ),
          if (event.includeParents || guardians.isNotEmpty)
            _attendeeGroupTile(
              context,
              label: 'Parents',
              icon: Icons.family_restroom_outlined,
              color: EventUiUtils.typeColor(EventType.individual),
              attendees: guardians,
              rsvpByCode: rsvpByCode,
              childNameByCode: childNames,
              countLabel: guardians.isEmpty ? 'invited' : null,
              emptyHint:
                  'All parents of invited students are welcome. Responses '
                  'will appear here as parents RSVP.',
            ),
        ],
      ),
    );
  }

  Widget _attendeeGroupTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required List<EventAttendee> attendees,
    required Map<String, EventRsvp> rsvpByCode,
    Map<String, String> childNameByCode = const {},
    String? countLabel,
    String? emptyHint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showAttendeeGroupSheet(
            context,
            label: label,
            color: color,
            icon: icon,
            attendees: attendees,
            rsvpByCode: rsvpByCode,
            childNameByCode: childNameByCode,
            emptyHint: emptyHint,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  countLabel ?? '${attendees.length}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAttendeeGroupSheet(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required List<EventAttendee> attendees,
    required Map<String, EventRsvp> rsvpByCode,
    Map<String, String> childNameByCode = const {},
    String? emptyHint,
  }) {
    showEntityListSheet(
      context,
      title: label,
      icon: icon,
      color: color,
      emptyHint: emptyHint,
      items: [
        for (final attendee in attendees)
          EntityListItem(
            name: attendee.name.isNotEmpty ? attendee.name : attendee.code,
            // Parent rows carry the linked child's code — show the child.
            subtitle: childNameByCode[attendee.linkedCode] ?? '',
            rsvp: rsvpByCode[attendee.code]?.status,
          ),
      ],
    );
  }

  Widget _attachmentCard(BuildContext context, Event event) {
    return _sectionCard(
      title: event.attachments.length == 1
          ? 'Attachment'
          : 'Attachments (${event.attachments.length})',
      // Same widget, same viewer as the task detail screen. Events use the
      // `.resolved` constructor because their occurrence payload already
      // includes `deliveryUrl`/`thumbnailUrl` — no resolve request needed.
      child: AttachmentSection.resolved(attachments: event.attachments),
    );
  }

  Widget _rsvpCard(
    BuildContext context,
    EventsState state,
    Event event, {
    required bool isParent,
    required bool canRsvp,
    required bool canSeeSummary,
  }) {
    final myRsvp = event.myRsvpStatus;
    return _sectionCard(
      title: canRsvp ? 'Your RSVP' : 'RSVP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canRsvp)
            EventRsvpBar(
              selected: myRsvp,
              onChanged: (status) async {
                final (ok, message) = await context.read<EventsCubit>().respond(
                  occurrence: event,
                  status: status,
                  userType: isParent ? 'PARENT' : 'STAFF',
                );
                if (!context.mounted) return;
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: message,
                  isSuccess: ok,
                  isError: !ok,
                );
              },
            ),
          if (canSeeSummary) ...[
            if (canRsvp) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
            ],
            const Text(
              'Responses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            EventRsvpSummary(event: event),
          ],
        ],
      ),
    );
  }

  Widget _footer(Event event) {
    final created = event.createdByName.isNotEmpty
        ? 'Created by ${event.createdByName}'
        : 'Created';
    return Text(
      '$created on ${DateFormat('MMM d, yyyy').format(event.createdAt)}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11, color: Colors.black38),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  /// Recurring events ask which scope the edit targets: a slim
  /// single-occurrence editor (THIS_ONLY override), the full form applied
  /// from this occurrence onward (THIS_AND_FUTURE — splits the series), or
  /// the full form for the entire series. One-off events go straight to
  /// the form.
  Future<void> _onEditPressed(BuildContext context, Event event) async {
    if (!event.recurring || event.occurrenceCode.isEmpty) {
      context.push(
        EventFormScreen.routeName,
        extra: <String, dynamic>{'eventCode': event.code},
      );
      return;
    }
    final scope = await showOccurrenceScopeSheet(
      context,
      title: 'Edit recurring event',
      icon: Icons.edit_outlined,
    );
    if (scope == null || !context.mounted) return;
    if (scope == OccurrenceScope.wholeSeries) {
      context.push(
        EventFormScreen.routeName,
        extra: <String, dynamic>{'eventCode': event.code},
      );
      return;
    }
    if (scope == OccurrenceScope.thisAndFuture) {
      context.push(
        EventFormScreen.routeName,
        extra: <String, dynamic>{
          'eventCode': event.code,
          'splitFromOccurrence': event.occurrenceCode,
          'splitFromDate': event.date.toIso8601String(),
        },
      );
      return;
    }
    // THIS_ONLY also uses the full edit screen (occurrence mode).
    context.push(
      EventFormScreen.routeName,
      extra: <String, dynamic>{
        'eventCode': event.code,
        'editOccurrence': event.occurrenceCode,
      },
    );
  }

  /// Recurring events choose between cancelling this occurrence (with an
  /// optional reason), cancelling this and every later one
  /// (THIS_AND_FUTURE — e.g. an admin stopping the event from next month),
  /// or deleting the whole series; one-off events keep the plain confirm
  /// dialog.
  Future<void> _onDeletePressed(BuildContext context, Event event) async {
    if (!event.recurring || event.occurrenceCode.isEmpty) {
      await _confirmDelete(context, event);
      return;
    }
    final scope = await showOccurrenceScopeSheet(
      context,
      title: 'Delete recurring event',
      icon: Icons.delete_outline,
    );
    if (scope == null || !context.mounted) return;
    if (scope == OccurrenceScope.wholeSeries) {
      await _confirmDelete(context, event);
      return;
    }
    if (scope == OccurrenceScope.thisAndFuture) {
      final confirmed = await _confirmFromHere(context, event);
      if (confirmed != true || !context.mounted) return;
      final (ok, message) =
          await context.read<EventsCubit>().deleteFromOccurrence(event);
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: ok,
        isError: !ok,
      );
      if (ok) context.pop();
      return;
    }
    final reason = await promptOccurrenceCancelReason(context);
    if (reason == null || !context.mounted) return;
    final (ok, message) = await context.read<EventsCubit>().cancelOccurrence(
      eventCode: event.code,
      occurrenceCode: event.occurrenceCode,
      reason: reason,
    );
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isSuccess: ok,
      isError: !ok,
    );
    if (ok) context.pop();
  }

  Future<bool?> _confirmFromHere(BuildContext context, Event event) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this and future events?'),
        content: Text(
          '"${event.name}" will be cancelled from '
          '${DateFormat('MMM d, yyyy').format(event.date)} to the end of '
          'the series. Earlier events stay on the calendar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep events'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete from here',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          '"${event.name}" will be removed for everyone. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<EventsCubit>().delete(event.code);
    if (!context.mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Event deleted',
        isSuccess: true,
      );
      context.pop();
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to delete event',
        isError: true,
      );
    }
  }
}
