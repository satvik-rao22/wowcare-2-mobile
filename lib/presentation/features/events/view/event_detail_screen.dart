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
import 'package:wowcare/presentation/features/events/widgets/event_rsvp_bar.dart';
import 'package:wowcare/presentation/features/events/widgets/event_rsvp_summary.dart';
import 'package:wowcare/presentation/features/events/widgets/event_type_chip.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({required this.eventCode, super.key});

  static const String routeName = '/dashboard/events/detail';

  final String eventCode;

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          final event = state.eventByCode(eventCode);
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
          final canRsvp = EventAccess.canRsvp(
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
                _attendeesCard(event),
                if (event.attachmentName != null &&
                    event.attachmentName!.isNotEmpty) ...[
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
            onPressed: () => context.push(
              EventFormScreen.routeName,
              extra: <String, dynamic>{'eventCode': event.code},
            ),
          ),
          IconButton(
            tooltip: 'Delete event',
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.errorColor,
              size: 22,
            ),
            onPressed: () => _confirmDelete(context, event),
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
          if (event.recurring && event.recurringPattern != null) ...[
            const SizedBox(height: 6),
            _infoRow(
              Icons.repeat,
              event.recurringEndDate != null
                  ? '${event.recurringPattern!.label} until '
                        '${DateFormat('MMM d, yyyy').format(event.recurringEndDate!)}'
                  : event.recurringPattern!.label,
            ),
          ],
        ],
      ),
    );
  }

  Widget _attendeesCard(Event event) {
    return _sectionCard(
      title: 'Attendees',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            EventUiUtils.audienceSummary(event),
            style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
          ),
          if (event.classrooms.isNotEmpty)
            _attendeeChips(
              'Classrooms',
              event.classrooms,
              EventUiUtils.typeColor(EventType.classroom),
            ),
          if (event.students.isNotEmpty)
            _attendeeChips(
              'Students',
              event.students,
              EventUiUtils.typeColor(EventType.student),
            ),
          if (event.staff.isNotEmpty)
            _attendeeChips(
              'Staff',
              event.staff,
              EventUiUtils.typeColor(EventType.staff),
            ),
        ],
      ),
    );
  }

  Widget _attendeeChips(
    String label,
    List<EventAttendee> attendees,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final attendee in attendees)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    attendee.name.isNotEmpty ? attendee.name : attendee.code,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attachmentCard(BuildContext context, Event event) {
    return _sectionCard(
      title: 'Attachment',
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18, color: AppColors.themeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.attachmentName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.themeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
    final myRsvp = event.rsvpFor(state.currentUserCode);
    return _sectionCard(
      title: canRsvp ? 'Your RSVP' : 'RSVP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canRsvp)
            EventRsvpBar(
              selected: myRsvp?.status,
              onChanged: (status) async {
                final (ok, message) = await context.read<EventsCubit>().respond(
                  eventCode: event.code,
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
