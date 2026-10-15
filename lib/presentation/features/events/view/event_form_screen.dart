import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/events/view_model/events_cubit.dart';
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/presentation/features/events/utils/event_attendee_names.dart';
import 'package:wowcare/presentation/features/events/utils/event_audience_cascade.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/presentation/features/events/utils/recurrence_end_policy.dart';
import 'package:wowcare/presentation/features/events/utils/recurrence_summary.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/attachment_picker_field.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';
import 'package:wowcare/core/theme/app_haptics.dart';

/// Create/edit form for an event. A single scrollable mobile form replaces
/// the web design's multi-step wizard: basics up top, audience pickers
/// (modal bottom sheets) below.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({
    this.eventCode,
    this.initialDate,
    this.splitFromOccurrenceCode,
    this.splitFromDate,
    this.editOccurrenceCode,
    super.key,
  });

  static const String routeName = '/dashboard/events/form';

  /// When set, the form edits the existing event with this code.
  final String? eventCode;

  /// Default date for new events (the day selected on the calendar).
  final DateTime? initialDate;

  /// When set, saving splits the recurring series at this occurrence
  /// (THIS_AND_FUTURE): changes apply from [splitFromDate] onward and
  /// earlier occurrences keep the old details.
  final String? splitFromOccurrenceCode;
  final DateTime? splitFromDate;

  /// When set, saving edits ONLY this occurrence (THIS_ONLY override:
  /// name, description, date, times); series-level sections are hidden.
  final String? editOccurrenceCode;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Event? _editing;
  EventType _type = EventType.classroom;
  late DateTime _date;
  bool _allDay = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _recurring = false;
  RecurrenceFrequency _recurFrequency = RecurrenceFrequency.daily;
  int _recurInterval = 1;
  Set<int> _recurDays = const {};
  MonthlyRepeatMode _recurMonthlyMode = MonthlyRepeatMode.dayOfMonth;
  YearlyRepeatMode _recurYearlyMode = YearlyRepeatMode.date;
  DateTime? _recurringEndDate;

  /// Whether the user picked the "Until" date themselves — manual picks
  /// are clamped (not replaced) when the unit or start date changes.
  bool _recurEndManual = false;

  /// True while `GET /events/{code}` is still in flight for a series edit.
  ///
  /// The occurrence row this form prefills from carries no recurrence rule, so
  /// until that response lands the recurrence fields hold placeholder values.
  /// Saving then would overwrite the real series rule with the placeholder, so
  /// the Save button stays disabled — visibly, with its own label — rather than
  /// letting a half-loaded form be submitted.
  bool _loadingSeries = false;
  bool _includeParents = false;

  /// Files picked on this form, uploaded inside [_save] — so an abandoned form
  /// uploads nothing.
  ///
  /// Existing attachments on an edited event are not prefilled: no event read
  /// returns an assets list, so there is nothing to load. See
  /// [_attachmentNotice].
  List<PickedFile> _attachments = const [];

  /// Live per-file upload progress while a save is running; null otherwise.
  AttachmentUploadState? _uploadState;

  bool get _isUploading => _uploadState?.isUploading ?? false;

  List<EventAttendee> _classrooms = const [];
  List<EventAttendee> _students = const [];
  List<EventAttendee> _staff = const [];

  bool get _isEditing => _editing != null;

  bool get _isSplitting =>
      (widget.splitFromOccurrenceCode ?? '').trim().isNotEmpty;

  bool get _isOccurrenceEdit =>
      (widget.editOccurrenceCode ?? '').trim().isNotEmpty;

  /// Name plus the type-specific audience/time rules must all be satisfied
  /// before the Save button is enabled — mirrors [_validateAudienceAndTime],
  /// which still runs on submit as a safety net.
  bool get _isFormValid =>
      !_loadingSeries &&
      _nameController.text.trim().isNotEmpty &&
      _validateAudienceAndTime() == null;

  @override
  void initState() {
    super.initState();
    // New events cannot be scheduled in the past (PRD VR-EV-03); a past day
    // tapped on the calendar falls back to today. Editing keeps past dates.
    final today = _dateOnly(DateTime.now());
    final initial = _dateOnly(widget.initialDate ?? today);
    _date = initial.isBefore(today) ? today : initial;
    final code = widget.eventCode?.trim() ?? '';
    if (code.isNotEmpty) {
      // Instant prefill from the occurrence row in state, then refine with
      // the full series event (recurrence rule + audience selectors live
      // only on GET /events/{code}).
      final state = context.read<EventsCubit>().state;
      final row = _isOccurrenceEdit
          ? state.eventByOccurrence(
              widget.editOccurrenceCode!,
              eventCode: code,
            )
          : state.eventByCode(code);
      if (row != null) _prefill(row);
      // Occurrence mode edits the row's own values — the series detail
      // (rrule, selectors) isn't needed and would overwrite them.
      if (!_isOccurrenceEdit) {
        _loadingSeries = true;
        unawaited(_loadFullEvent(code));
      }
    }
    _nameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _loadFullEvent(String code) async {
    final full = await context.read<EventsCubit>().loadEventForEdit(code);
    if (!mounted) return;
    setState(() {
      _loadingSeries = false;
      if (full != null) {
        _prefill(EventAttendeeNames.resolve(context, full, listen: false));
      }
      // A recurring series whose rule never arrived — the read failed, the API
      // omitted the rrule, or it didn't parse — would otherwise leave "Until"
      // empty, and an empty Until blocks Save with no way to recover: the field
      // the user would have to fill is the one that failed to load. Seed the
      // policy default instead, so the form stays editable and the date is
      // visible in the panel before anything is saved.
      if (_recurring && _recurringEndDate == null) {
        _recurringEndDate = RecurrenceEndPolicy.defaultEnd(
          _recurFrequency,
          _date,
        );
        _recurEndManual = false;
      }
    });
  }

  void _prefill(Event event) {
    _editing = event;
    _type = event.type;
    _nameController.text = event.name;
    _descriptionController.text = event.description;
    _date = _dateOnly(event.date);
    _allDay = event.allDay;
    _startTime = _parseTime(event.startTime) ?? _startTime;
    _endTime = _parseTime(event.endTime) ?? _endTime;
    // An occurrence edit changes only this occurrence's name, description,
    // date and times — the series rule is neither shown nor sent. Carrying the
    // row's `recurring` flag in anyway made the form demand an "Until" date
    // from a panel this mode deliberately hides, which left Save disabled with
    // nothing on screen to fix.
    _recurring = _isOccurrenceEdit ? false : event.recurring;
    final rule = event.recurrence;
    if (rule != null) {
      _recurFrequency = rule.frequency;
      _recurInterval = rule.interval;
      _recurDays = Set.of(rule.daysOfWeek);
      _recurMonthlyMode = rule.monthlyMode;
      _recurYearlyMode = rule.yearlyMode;
      _recurringEndDate = rule.endDate;
      _recurEndManual = true;
    }
    _includeParents = event.includeParents;
    _classrooms = event.classrooms;
    _students = event.students;
    _staff = event.staff;
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Event' : 'New Event',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isEditing && !_isOccurrenceEdit) ...[
                const SizedBox(height: 10),
                _editLimitsBanner(),
              ],
              if (_isOccurrenceEdit) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPalette.statusInfoSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Editing this event only — name, description, date and '
                    'time apply to this date. Attendees and repeat settings '
                    'belong to the whole series.',
                    style: TextStyle(fontSize: 11.5, color: AppPalette.statusInfo),
                  ),
                ),
              ],
              if (_isSplitting && widget.splitFromDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPalette.statusInfoSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Editing this and future events: changes apply from '
                    '${DateFormat('MMM d, yyyy').format(widget.splitFromDate!)} '
                    'onward — earlier events keep their current details.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppPalette.statusInfo,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _label('Event Type', required: true),
              _typeSelector(),
              const SizedBox(height: 14),
              _label('Event Name', required: true),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration('Enter event name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _label('Date & Time', required: true),
              _dateTile(),
              const SizedBox(height: 8),
              _switchTile(
                title: 'All day',
                value: _allDay,
                onChanged: (value) => setState(() => _allDay = value),
              ),
              if (!_allDay) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _timeTile(
                        label: 'Starts',
                        time: _startTime,
                        onPicked: (time) => setState(() => _startTime = time),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _timeTile(
                        label: 'Ends',
                        time: _endTime,
                        onPicked: (time) => setState(() => _endTime = time),
                      ),
                    ),
                  ],
                ),
              ],
              if (!_isOccurrenceEdit) ...[
                const SizedBox(height: 8),
                _switchTile(
                  title: 'Repeats',
                  value: _recurring,
                  onChanged: _onRecurringToggled,
                ),
                if (_recurring) ..._recurrencePanel(),
              ],
              const SizedBox(height: 14),
              _label('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  'e.g. What to bring, where to meet…',
                ),
              ),
              // Series-level, so hidden while overriding a single occurrence
              // (that mode only carries name, description, date and times).
              if (!_isOccurrenceEdit) ...[
                const SizedBox(height: 14),
                _label('Attachments'),
                AttachmentPickerField(
                  files: _attachments,
                  onChanged: (files) => setState(() => _attachments = files),
                  // The EVENT upload session reports maxAssetCount 25 (TASK
                  // reports 5). The session is authoritative but is only opened
                  // on save, after picking — so this mirrors the observed value
                  // rather than reading it.
                  maxFiles: 25,
                  // Locked mid-upload: the manager is already iterating this
                  // list and the asset codes are tied to what it was handed.
                  enabled: !_isUploading,
                  uploadState: _uploadState,
                ),
                ..._attachmentNotice(),
              ],
              const SizedBox(height: 14),
              _label('Attendees', required: _type != EventType.school),
              ..._audienceSection(),
              if (_type != EventType.staff) ...[
                const SizedBox(height: 8),
                _switchTile(
                  title: 'Invite parents',
                  value: _includeParents,
                  onChanged: (value) => setState(() => _includeParents = value),
                ),
              ],
              const SizedBox(height: 20),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- type

  /// The event type (and its derived audience scope) is the one immutable
  /// field on the events API — changing it means delete + recreate.
  Widget _editLimitsBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.warningColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'The event type can\'t be changed — delete this event and '
              'create a new one to switch types. Everything else is '
              'editable.',
              style: TextStyle(fontSize: 11.5, color: AppColors.warningColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeSelector() {
    // Editing: the API cannot change an event's type, so only the current
    // type is shown, locked. Staff cannot create school-wide events
    // (PRD §5.1) — creatableTypes handles that for the create flow.
    final types = _isEditing
        ? [_type]
        : EventAccess.creatableTypes(context.watch<RoleCubit>());
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final type in types)
          ChoiceChip(
            label: Text(type.label),
            avatar: Icon(
              EventUiUtils.typeIcon(type),
              size: 15,
              color: _type == type
                  ? AppPalette.textOnDark
                  : EventUiUtils.typeColor(type),
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _type == type
                  ? AppPalette.textOnDark
                  : EventUiUtils.typeColor(type),
            ),
            selected: _type == type,
            selectedColor: EventUiUtils.typeColor(type),
            backgroundColor: EventUiUtils.typeColor(
              type,
            ).withValues(alpha: 0.08),
            showCheckmark: false,
            side: BorderSide(
              color: EventUiUtils.typeColor(type).withValues(alpha: 0.3),
            ),
            onSelected: _isEditing ? null : (_) => _onTypeChanged(type),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ audience

  /// Audience pickers follow the school hierarchy (school → classroom →
  /// staff & students): each type exposes exactly its own level. Classroom
  /// staff, admins and parents are auto-included by the events backend, so
  /// no extra pickers are shown for them.
  List<Widget> _audienceSection() {
    switch (_type) {
      case EventType.school:
        return [_schoolAudienceTile()];
      case EventType.classroom:
        return [_classroomPicker()];
      case EventType.student:
        return [_studentPicker()];
      case EventType.staff:
        return [_staffPicker()];
      case EventType.custom:
        return [
          _classroomPicker(onChanged: _onCustomClassroomsChanged),
          const SizedBox(height: 6),
          Text(
            'Picking a classroom pre-selects its students and staff — '
            'fine-tune them below.',
            style: TextStyle(fontSize: 11.5, color: AppPalette.textSecondary),
          ),
          const SizedBox(height: 8),
          _studentPicker(),
          const SizedBox(height: 8),
          _staffPicker(),
        ];
      case EventType.individual:
        return [_studentPicker(), const SizedBox(height: 8), _staffPicker()];
    }
  }

  /// School-wide events invite everyone — show who "everyone" is instead
  /// of a picker.
  Widget _schoolAudienceTile() {
    final schoolName = context.select(
      (EventsCubit cubit) => cubit.state.schoolName,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EventUiUtils.typeBackground(EventType.school),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_outlined,
            size: 18,
            color: EventUiUtils.typeColor(EventType.school),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName.isEmpty ? 'Whole school' : schoolName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'All classrooms, staff and students will be invited.',
                  style: TextStyle(fontSize: 12, color: AppPalette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Type switches keep prior selections (only the levels owned by the new
  /// type are shown and submitted). Entering Custom with classrooms already
  /// picked (e.g. coming from the Classroom type) runs the same cascade as
  /// picking them inside Custom, so their students/staff show as selected.
  void _onTypeChanged(EventType next) {
    if (next == _type) return;
    AppHaptics.select();
    if (next == EventType.custom && _classrooms.isNotEmpty) {
      final allStudents = context.read<StudentCubit>().state.items;
      final allStaff = context.read<StaffCubit>().state.items;
      setState(() {
        _type = next;
        _students = EventAudienceCascade.nextStudents(
          current: _students,
          previousClassrooms: const [],
          nextClassrooms: _classrooms,
          allStudents: allStudents,
        );
        _staff = EventAudienceCascade.nextStaff(
          current: _staff,
          previousClassrooms: const [],
          nextClassrooms: _classrooms,
          allStaff: allStaff,
        );
      });
      return;
    }
    setState(() => _type = next);
  }

  /// Custom mode: cascade the classroom change into the student/staff
  /// selections (classroom members pre-select; manual picks survive).
  void _onCustomClassroomsChanged(List<EventAttendee> selection) {
    final allStudents = context.read<StudentCubit>().state.items;
    final allStaff = context.read<StaffCubit>().state.items;
    setState(() {
      _students = EventAudienceCascade.nextStudents(
        current: _students,
        previousClassrooms: _classrooms,
        nextClassrooms: selection,
        allStudents: allStudents,
      );
      _staff = EventAudienceCascade.nextStaff(
        current: _staff,
        previousClassrooms: _classrooms,
        nextClassrooms: selection,
        allStaff: allStaff,
      );
      _classrooms = selection;
    });
  }

  Widget _classroomPicker({ValueChanged<List<EventAttendee>>? onChanged}) {
    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (context, state) {
        final options = state.classrooms
            .map((c) => EventAttendee(code: c.code, name: c.name))
            .toList();
        return _pickerTile(
          icon: EventUiUtils.typeIcon(EventType.classroom),
          color: EventUiUtils.typeColor(EventType.classroom),
          label: 'Classrooms',
          selected: _classrooms,
          options: options,
          isLoading: state.isLoading,
          onChanged: onChanged ??
              (selection) => setState(() => _classrooms = selection),
        );
      },
    );
  }

  Widget _studentPicker() {
    return BlocBuilder<StudentCubit, StudentState>(
      builder: (context, state) {
        final options = state.items
            .map(
              (s) => EventAttendee(
                code: s.code,
                name: '${s.firstName} ${s.lastName}'.trim(),
              ),
            )
            .toList();
        return _pickerTile(
          icon: EventUiUtils.typeIcon(EventType.student),
          color: EventUiUtils.typeColor(EventType.student),
          label: 'Students',
          selected: _students,
          options: options,
          isLoading: state.isLoading,
          onChanged: (selection) => setState(() => _students = selection),
        );
      },
    );
  }

  Widget _staffPicker() {
    return BlocBuilder<StaffCubit, StaffState>(
      builder: (context, state) {
        final options = state.items
            .map((s) => EventAttendee(code: s.code, name: s.name))
            .toList();
        return _pickerTile(
          icon: EventUiUtils.typeIcon(EventType.staff),
          color: EventUiUtils.typeColor(EventType.staff),
          label: 'Staff',
          selected: _staff,
          options: options,
          isLoading: state.isLoading,
          onChanged: (selection) => setState(() => _staff = selection),
        );
      },
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required Color color,
    required String label,
    required List<EventAttendee> selected,
    required List<EventAttendee> options,
    required bool isLoading,
    required ValueChanged<List<EventAttendee>> onChanged,
  }) {
    final subtitle = selected.isEmpty
        ? 'None selected'
        : selected.map((a) => a.name).join(', ');
    return Material(
      color: AppPalette.surfaceCard,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final result = await _showAttendeeSheet(
            title: 'Select $label',
            options: options,
            selected: selected,
            isLoading: isLoading,
          );
          if (result != null) onChanged(result);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label${selected.isEmpty ? '' : ' (${selected.length})'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppPalette.iconMuted),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<EventAttendee>?> _showAttendeeSheet({
    required String title,
    required List<EventAttendee> options,
    required List<EventAttendee> selected,
    required bool isLoading,
  }) {
    // Selections referencing entities that aren't in the loaded options
    // (e.g. mock seed codes) are kept so editing doesn't silently drop them.
    final merged = <String, EventAttendee>{
      for (final option in options) option.code: option,
      for (final attendee in selected) attendee.code: attendee,
    };
    return showModalBottomSheet<List<EventAttendee>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _AttendeeSheet(
        title: title,
        options: merged.values.toList(),
        initialSelection: selected.map((a) => a.code).toSet(),
        isLoading: isLoading,
      ),
    );
  }

  // ------------------------------------------------------- date & time

  Widget _dateTile() {
    return _fieldTile(
      icon: Icons.calendar_today_outlined,
      text: DateFormat('EEE, MMM d, yyyy').format(_date),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          // Past dates are only reachable when editing (PRD VR-EV-03).
          firstDate: _isEditing
              ? DateTime(DateTime.now().year - 1)
              : _dateOnly(DateTime.now()),
          lastDate: DateTime(DateTime.now().year + 3),
        );
        if (picked != null) _onStartDateChanged(picked);
      },
    );
  }

  /// Moving the start date keeps the recurrence consistent with it: the
  /// old start weekday in the weekly selection follows to the new one
  /// (Thu -> Fri when the event moves a day later; other picked days are
  /// preserved), the monthly/yearly anchors re-derive automatically from
  /// the new date, and the "Until" date is re-anchored into the valid
  /// window.
  void _onStartDateChanged(DateTime picked) {
    setState(() {
      final previous = _date;
      _date = _dateOnly(picked);
      if (!_recurring) return;
      _recurDays = RecurrenceRule.shiftStartWeekday(
        _recurDays,
        previous.weekday,
        _date.weekday,
      );
      _recurringEndDate = _recurEndManual
          ? RecurrenceEndPolicy.clamp(_recurringEndDate, _recurFrequency, _date)
          : RecurrenceEndPolicy.defaultEnd(_recurFrequency, _date);
    });
  }

  Widget _timeTile({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    return _fieldTile(
      icon: Icons.access_time,
      text: '$label  ${time.format(context)}',
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  // -------------------------------------------------- recurrence (Teams)

  /// Enabling recurrence applies the Teams defaults: daily, every 1, all
  /// seven days, ending 30 days after the start date.
  void _onRecurringToggled(bool value) {
    setState(() {
      _recurring = value;
      if (value) {
        _recurFrequency = RecurrenceFrequency.daily;
        _recurInterval = 1;
        _recurDays = {...RecurrenceSummary.chipWeekdays};
        _recurMonthlyMode = MonthlyRepeatMode.dayOfMonth;
        _recurYearlyMode = YearlyRepeatMode.date;
        if (!_recurEndManual) {
          _recurringEndDate =
              RecurrenceEndPolicy.defaultEnd(_recurFrequency, _date);
        }
      }
    });
  }

  /// Switching the unit resets the weekday selection to its per-unit
  /// default (Teams behaviour): day → all seven, week → start weekday.
  void _onFrequencyChanged(RecurrenceFrequency next) {
    setState(() {
      _recurFrequency = next;
      if (next == RecurrenceFrequency.daily) {
        _recurDays = {...RecurrenceSummary.chipWeekdays};
      } else if (next == RecurrenceFrequency.weekly) {
        _recurDays = {_date.weekday};
      }
      // Each unit has its own sensible horizon; a manually picked date is
      // kept but clamped into the new unit's window.
      _recurringEndDate = _recurEndManual
          ? RecurrenceEndPolicy.clamp(_recurringEndDate, next, _date)
          : RecurrenceEndPolicy.defaultEnd(next, _date);
    });
  }

  bool get _showsWeekdayChips =>
      _recurFrequency == RecurrenceFrequency.weekly ||
      (_recurFrequency == RecurrenceFrequency.daily && _recurInterval == 1);

  /// The rule as currently configured on the form. Weekday sets only apply
  /// to the units whose chips are visible.
  RecurrenceRule _buildRecurrenceRule() {
    return RecurrenceRule(
      frequency: _recurFrequency,
      interval: _recurInterval,
      daysOfWeek: _showsWeekdayChips ? _recurDays : const <int>{},
      monthlyMode: _recurMonthlyMode,
      yearlyMode: _recurYearlyMode,
      endDate: _recurringEndDate,
    );
  }

  List<Widget> _recurrencePanel() {
    return [
      const SizedBox(height: 10),
      _label('Repeat every'),
      Row(
        children: [
          SizedBox(width: 86, child: _intervalDropdown()),
          const SizedBox(width: 8),
          Expanded(child: _frequencyDropdown()),
        ],
      ),
      if (_showsWeekdayChips) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(
              _recurFrequency == RecurrenceFrequency.daily
                  ? 'On days'
                  : 'Days of week',
            ),
            TextButton(
              onPressed: _onWeekdaySelectAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _recurDays.length == 7 ? 'Clear all' : 'Select all',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        _weekdayChips(),
      ],
      if (_recurFrequency == RecurrenceFrequency.monthly) ...[
        const SizedBox(height: 10),
        _label('Repeat on'),
        _modeRadio<MonthlyRepeatMode>(
          value: MonthlyRepeatMode.dayOfMonth,
          groupValue: _recurMonthlyMode,
          label:
              'Day ${RecurrenceSummary.dayOfMonthLabel(_date)} of every month',
          onChanged: (mode) => setState(() => _recurMonthlyMode = mode),
        ),
        _modeRadio<MonthlyRepeatMode>(
          value: MonthlyRepeatMode.nthWeekday,
          groupValue: _recurMonthlyMode,
          label:
              'The ${RecurrenceSummary.nthWeekdayLabel(_date)} of every month',
          onChanged: (mode) => setState(() => _recurMonthlyMode = mode),
        ),
      ],
      if (_recurFrequency == RecurrenceFrequency.yearly) ...[
        const SizedBox(height: 10),
        _label('Repeat on'),
        _modeRadio<YearlyRepeatMode>(
          value: YearlyRepeatMode.date,
          groupValue: _recurYearlyMode,
          label: '${DateFormat('MMMM d').format(_date)} every year',
          onChanged: (mode) => setState(() => _recurYearlyMode = mode),
        ),
        _modeRadio<YearlyRepeatMode>(
          value: YearlyRepeatMode.nthWeekday,
          groupValue: _recurYearlyMode,
          label: 'The ${RecurrenceSummary.nthWeekdayLabel(_date)} of '
              '${DateFormat('MMMM').format(_date)} every year',
          onChanged: (mode) => setState(() => _recurYearlyMode = mode),
        ),
      ],
      const SizedBox(height: 10),
      _label('Until'),
      _recurringEndTile(),
      const SizedBox(height: 10),
      _recurrenceSummaryBox(),
    ];
  }

  Widget _intervalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _tileDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _recurInterval,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppPalette.textPrimary),
          items: [
            for (var n = 1; n <= 99; n++)
              DropdownMenuItem(value: n, child: Text('$n')),
          ],
          onChanged: (n) {
            if (n != null) setState(() => _recurInterval = n);
          },
        ),
      ),
    );
  }

  Widget _frequencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _tileDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RecurrenceFrequency>(
          value: _recurFrequency,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppPalette.textPrimary),
          items: [
            for (final frequency in RecurrenceFrequency.values)
              DropdownMenuItem(
                value: frequency,
                child: Text(
                  _recurInterval == 1
                      ? frequency.unitLabel
                      : '${frequency.unitLabel}s',
                ),
              ),
          ],
          onChanged: (frequency) {
            if (frequency != null) _onFrequencyChanged(frequency);
          },
        ),
      ),
    );
  }

  void _onWeekdaySelectAll() {
    AppHaptics.select();
    setState(() {
      if (_recurDays.length == 7) {
        // "Clear all": weekly keeps at least the start date's weekday.
        _recurDays = _recurFrequency == RecurrenceFrequency.weekly
            ? {_date.weekday}
            : const <int>{};
      } else {
        _recurDays = {...RecurrenceSummary.chipWeekdays};
      }
    });
  }

  Widget _weekdayChips() {
    const dayLabels = {
      DateTime.sunday: 'Sun',
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final day in RecurrenceSummary.chipWeekdays)
          FilterChip(
            label: Text(dayLabels[day]!),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _recurDays.contains(day)
                  ? AppPalette.textOnDark
                  : AppColors.primaryColor,
            ),
            selected: _recurDays.contains(day),
            selectedColor: AppColors.primaryColor,
            backgroundColor: AppPalette.surfaceCard,
            checkmarkColor: AppPalette.textOnDark,
            showCheckmark: false,
            side: BorderSide(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
            onSelected: (selected) {
              AppHaptics.select();
              setState(() {
                final next = Set<int>.of(_recurDays);
                if (selected) {
                  next.add(day);
                } else {
                  next.remove(day);
                }
                _recurDays = next;
              });
            },
          ),
      ],
    );
  }

  Widget _modeRadio<T>({
    required T value,
    required T groupValue,
    required String label,
    required ValueChanged<T> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<T>(
            value: value,
            groupValue: groupValue,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppPalette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// Live "Occurs every other week on Mon, Wed … until …" line, mirroring
  /// the web app's summary.
  Widget _recurrenceSummaryBox() {
    final summary = RecurrenceSummary.describe(
      rule: _buildRecurrenceRule(),
      startDate: _date,
      startTime: _allDay ? '' : _formatTime(_startTime),
      endTime: _allDay ? '' : _formatTime(_endTime),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.statusSuccessSoft,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppPalette.statusSuccess, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 15,
            color: AppPalette.statusSuccessStrong,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppPalette.statusSuccessStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recurringEndTile() {
    final maxEnd = RecurrenceEndPolicy.maxEnd(_recurFrequency, _date);
    return _fieldTile(
      icon: Icons.event_repeat_outlined,
      text: _recurringEndDate == null
          ? 'End date'
          : DateFormat('MMM d, yyyy').format(_recurringEndDate!),
      onTap: () async {
        final initial = RecurrenceEndPolicy.clamp(
          _recurringEndDate,
          _recurFrequency,
          _date,
        );
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: _date,
          lastDate: maxEnd,
        );
        if (picked != null) {
          setState(() {
            _recurringEndDate = _dateOnly(picked);
            _recurEndManual = true;
          });
        }
      },
    );
  }

  // ------------------------------------------------------------- save

  Widget _saveButton() {
    return BlocBuilder<EventsCubit, EventsState>(
      builder: (context, state) {
        final busy = state.isSaving || _isUploading;
        final canSave = _isFormValid && !busy;
        final keyVariant = canSave ? KeyVariant.primary : KeyVariant.disabled;
        final keyInk = AppSurfaces.keyInk(keyVariant);
        return SizedBox(
          height: 46,
          child: DecoratedBox(
            decoration: AppSurfaces.key(keyVariant, radius: 10),
            child: ElevatedButton(
              onPressed: canSave ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.transparentColor,
                shadowColor: AppColors.transparentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: busy
                  // While attachments are moving, say so and show how far — a
                  // bare spinner on a multi-file upload reads as a hang.
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: keyInk,
                          ),
                        ),
                        if (_isUploading) ...[
                          const SizedBox(width: 10),
                          Text(
                            _uploadState!.summary,
                            style: TextStyle(
                              color: keyInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      // A disabled button with the usual label reads as broken.
                      // Say what it is waiting for while the series loads.
                      _loadingSeries
                          ? 'Loading event…'
                          : _isEditing
                              ? 'Save Changes'
                              : 'Create Event',
                      style: TextStyle(
                        color: keyInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    AppHaptics.tap();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final error = _validateAudienceAndTime();
    if (error != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: error,
        isWarning: true,
      );
      return;
    }

    final today = _dateOnly(DateTime.now());
    if (!_isEditing && _date.isBefore(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Event date cannot be in the past',
        isWarning: true,
      );
      return;
    }

    // The school is closed on observed holidays — confirm before
    // scheduling there.
    final holidays = context.read<EventsCubit>().state.holidaysOn(_date);
    if (holidays.isNotEmpty) {
      final proceed = await _confirmHolidayDate(holidays.first.name);
      if (proceed != true || !mounted) return;
    }

    // School events snapshot every active classroom as the audience.
    var classrooms = _classrooms;
    if (_type == EventType.school) {
      classrooms = context
          .read<ClassroomCubit>()
          .state
          .classrooms
          .map((c) => EventAttendee(code: c.code, name: c.name))
          .toList();
    }

    final cubit = context.read<EventsCubit>();
    final base =
        _editing ??
        Event(
          code: '',
          type: _type,
          name: '',
          date: _date,
          allDay: _allDay,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    final event = base.copyWith(
      type: _type,
      name: _nameController.text.trim(),
      date: _date,
      allDay: _allDay,
      startTime: _allDay ? '' : _formatTime(_startTime),
      endTime: _allDay ? '' : _formatTime(_endTime),
      description: _descriptionController.text.trim(),
      // Only the levels of the hierarchy owned by the chosen type are
      // kept — pickers hidden for this type may hold stale selections
      // from a previously chosen type.
      classrooms:
          (_type == EventType.school ||
              _type == EventType.classroom ||
              _type == EventType.custom)
          ? classrooms
          : const [],
      students:
          (_type == EventType.student ||
              _type == EventType.custom ||
              _type == EventType.individual)
          ? _students
          : const [],
      staff:
          (_type == EventType.staff ||
              _type == EventType.custom ||
              _type == EventType.individual)
          ? _staff
          : const [],
      includeParents: _type == EventType.staff ? false : _includeParents,
      recurring: _recurring,
      recurrence: () => _recurring ? _buildRecurrenceRule() : null,
    );

    if (_isOccurrenceEdit) {
      // Single-occurrence override: only the fields the THIS_ONLY PATCH
      // supports. Attendee/recurrence changes need a series-level scope.
      final (occOk, message) = await cubit.updateOccurrence(
        eventCode: _editing?.code ?? '',
        occurrenceCode: widget.editOccurrenceCode!,
        overrideName: _nameController.text.trim(),
        overrideDescription: _descriptionController.text.trim(),
        scheduledStartDate: _date,
        scheduledStartTime: _allDay ? null : _formatTime(_startTime),
        scheduledEndTime: _allDay ? null : _formatTime(_endTime),
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: occOk,
        isError: !occOk,
      );
      if (occOk) context.pop();
      return;
    }
    // Upload the staged files only now, on submit: one session, one batched
    // presign, bounded-parallel transfers. A failed upload aborts the save so an
    // event is never persisted without the attachments it was meant to carry.
    List<String> uploadedAssetCodes = const [];
    if (_attachments.isNotEmpty) {
      final result = await cubit.uploadAttachments(
        files: _attachments,
        onProgress: (state) {
          if (mounted) setState(() => _uploadState = state);
        },
      );
      if (!mounted) return;
      setState(() => _uploadState = result);

      if (!result.allSucceeded) {
        // Partial success is still a failed save: dropping the files that did
        // not make it would be worse than not saving. The per-card overlays
        // already show which ones, so the toast stays short.
        CoreUtils.showTopSnackBar(
          context: context,
          message: result.summary,
          isError: true,
        );
        setState(() => _uploadState = null);
        return;
      }
      uploadedAssetCodes = result.assetCodes;
    }

    final ok = _isEditing
        ? await cubit.update(
            event,
            splitFromOccurrenceCode: widget.splitFromOccurrenceCode ?? '',
            // Full replace when files were staged, untouched otherwise — the
            // form cannot show what is already attached, so it must not claim
            // to know the user cleared it.
            assetCodes:
                uploadedAssetCodes.isEmpty ? null : uploadedAssetCodes,
          )
        : await cubit.create(event, assetCodes: uploadedAssetCodes);
    if (!mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: _isEditing ? 'Event updated' : 'Event created',
        isSuccess: true,
      );
      context.pop();
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not save the event. Please try again.',
        isError: true,
      );
    }
  }

  String? _validateAudienceAndTime() {
    if (!_allDay) {
      final start = _startTime.hour * 60 + _startTime.minute;
      final end = _endTime.hour * 60 + _endTime.minute;
      if (end <= start) return 'End time must be after start time';
    }
    if (_recurring && _recurringEndDate == null) {
      return 'Pick an end date for the repeating event';
    }
    if (_recurring &&
        _recurFrequency == RecurrenceFrequency.weekly &&
        _recurDays.isEmpty) {
      return 'Select at least one day of the week';
    }
    switch (_type) {
      case EventType.classroom:
        if (_classrooms.isEmpty) return 'Select at least one classroom';
      case EventType.student:
        if (_students.isEmpty) return 'Select at least one student';
      case EventType.staff:
        if (_staff.isEmpty) return 'Select at least one staff member';
      case EventType.custom:
        if (_classrooms.isEmpty && _students.isEmpty && _staff.isEmpty) {
          return 'Select at least one attendee';
        }
      case EventType.individual:
        if (_students.isEmpty && _staff.isEmpty) {
          return 'Select at least one attendee';
        }
      case EventType.school:
        break;
    }
    return null;
  }

  /// Holidays no longer hard-block scheduling; the user confirms instead.
  Future<bool?> _confirmHolidayDate(String holidayName) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schedule on a holiday?'),
        content: Text(
          '${DateFormat('EEE, MMM d, yyyy').format(_date)} falls on '
          '"$holidayName". Do you want to '
          '${_isEditing ? 'keep' : 'create'} the event on this date anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppHaptics.tap();
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AppHaptics.tap();
              Navigator.pop(dialogContext, true);
            },
            child: Text(_isEditing ? 'Save anyway' : 'Create anyway'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- attachments

  /// Warning shown on edit once files are staged.
  ///
  /// `assetCodes` is a full replace, and the form cannot show what is already
  /// attached because no event read returns an assets list. Saving new files
  /// therefore drops whatever was there, and the honest thing is to say so.
  List<Widget> _attachmentNotice() {
    if (!_isEditing || _attachments.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warningColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.warningColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: AppColors.warningColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Saving replaces any files already attached to this event. '
                'Existing attachments cannot be shown yet.',
                style: TextStyle(fontSize: 11.5, color: AppPalette.textPrimary),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ------------------------------------------------------------ helpers

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.errorColor),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return AppSurfaces.fieldDecoration(radius: 10).copyWith(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppPalette.textMuted),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  /// Every tap-to-pick row and inline dropdown on this form. They hold a
  /// value exactly as the text fields beside them do, so they take the same
  /// well rather than a raised card face.
  Decoration _tileDecoration() => AppSurfaces.well(radius: 10);

  Widget _fieldTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: _tileDecoration(),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppColors.themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppPalette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      // The vertical padding keeps the row the height Material's Switch gave
      // it, so swapping in the house toggle restyles without moving anything.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _tileDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: enabled ? AppPalette.textPrimary : AppPalette.textMuted,
              ),
            ),
          ),
          CustomToggle(
            label: '',
            isToggled: value,
            onToggle: onChanged,
            enabled: enabled,
          ),
        ],
      ),
    );
  }

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  static TimeOfDay? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

/// Searchable multi-select bottom sheet used by the audience pickers.
class _AttendeeSheet extends StatefulWidget {
  const _AttendeeSheet({
    required this.title,
    required this.options,
    required this.initialSelection,
    required this.isLoading,
  });

  final String title;
  final List<EventAttendee> options;
  final Set<String> initialSelection;
  final bool isLoading;

  @override
  State<_AttendeeSheet> createState() => _AttendeeSheetState();
}

class _AttendeeSheetState extends State<_AttendeeSheet> {
  late final Set<String> _selection = Set.of(widget.initialSelection);
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.options
            .where(
              (a) =>
                  _query.isEmpty ||
                  a.name.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final allSelected =
        filtered.isNotEmpty &&
        filtered.every((a) => _selection.contains(a.code));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.sheetGrabber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppHaptics.select();
                        setState(() {
                          if (allSelected) {
                            for (final a in filtered) {
                              _selection.remove(a.code);
                            }
                          } else {
                            for (final a in filtered) {
                              _selection.add(a.code);
                            }
                          }
                        });
                      },
                      child: Text(
                        allSelected ? 'Clear all' : 'Select all',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: AppSurfaces.fieldDecoration(radius: 10).copyWith(
                    hintText: 'Search…',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppPalette.textMuted,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 19),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: widget.isLoading && widget.options.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matches',
                          style: TextStyle(color: AppPalette.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final attendee = filtered[index];
                          final checked = _selection.contains(attendee.code);
                          return CheckboxListTile(
                            dense: true,
                            value: checked,
                            activeColor: AppColors.themeColor,
                            controlAffinity: ListTileControlAffinity.trailing,
                            title: Text(
                              attendee.name.isNotEmpty
                                  ? attendee.name
                                  : attendee.code,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            onChanged: (_) {
                              setState(() {
                                if (checked) {
                                  _selection.remove(attendee.code);
                                } else {
                                  _selection.add(attendee.code);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: DecoratedBox(
                    decoration: AppSurfaces.key(KeyVariant.primary, radius: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.transparentColor,
                        shadowColor: AppColors.transparentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.tap();
                        final byCode = {
                          for (final option in widget.options)
                            option.code: option,
                        };
                        Navigator.pop(context, [
                          for (final code in _selection)
                            if (byCode[code] != null) byCode[code]!,
                        ]);
                      },
                      child: Text(
                        'Done (${_selection.length})',
                        style: TextStyle(
                          color: AppSurfaces.keyInk(KeyVariant.primary),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
