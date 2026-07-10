import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/presentation/features/events/utils/event_audience_cascade.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Create/edit form for an event. A single scrollable mobile form replaces
/// the web design's multi-step wizard: basics up top, audience pickers
/// (modal bottom sheets) below.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({this.eventCode, this.initialDate, super.key});

  static const String routeName = '/dashboard/events/form';

  /// When set, the form edits the existing event with this code.
  final String? eventCode;

  /// Default date for new events (the day selected on the calendar).
  final DateTime? initialDate;

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
  EventRecurrence _recurringPattern = EventRecurrence.weekly;
  DateTime? _recurringEndDate;
  bool _includeParents = false;
  List<EventAttendee> _classrooms = const [];
  List<EventAttendee> _students = const [];
  List<EventAttendee> _staff = const [];

  bool get _isEditing => _editing != null;

  /// Name plus the type-specific audience/time rules must all be satisfied
  /// before the Save button is enabled — mirrors [_validateAudienceAndTime],
  /// which still runs on submit as a safety net.
  bool get _isFormValid =>
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
      final event = context.read<EventsCubit>().state.eventByCode(code);
      if (event != null) _prefill(event);
    }
    _nameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  void _prefill(Event event) {
    _editing = event;
    _type = event.type;
    _nameController.text = event.name;
    _descriptionController.text = event.description;
    _date = _dateOnly(event.date);
    _allDay = event.allDay;
    _startTime = _parseTime(event.startTime) ?? _startTime;
    _endTime = _parseTime(event.endTime) ?? _endTime;
    _recurring = event.recurring;
    _recurringPattern = event.recurringPattern ?? EventRecurrence.weekly;
    _recurringEndDate = event.recurringEndDate;
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
              const SizedBox(height: 8),
              _switchTile(
                title: 'Repeats',
                value: _recurring,
                onChanged: (value) => setState(() => _recurring = value),
              ),
              if (_recurring) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _recurrenceDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: _recurringEndTile()),
                  ],
                ),
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

  Widget _typeSelector() {
    // Staff cannot create school-wide events (PRD §5.1); keep the chip
    // visible when editing one so the form still renders correctly.
    final types = EventAccess.creatableTypes(context.watch<RoleCubit>());
    if (_isEditing && !types.contains(_type)) types.add(_type);
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
                  ? Colors.white
                  : EventUiUtils.typeColor(type),
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _type == type
                  ? Colors.white
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
            onSelected: (_) => _onTypeChanged(type),
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
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'All classrooms, staff and students will be invited.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
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
      color: Colors.white,
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500]),
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
      backgroundColor: Colors.white,
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
        if (picked != null) setState(() => _date = _dateOnly(picked));
      },
    );
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

  Widget _recurrenceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _tileDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EventRecurrence>(
          value: _recurringPattern,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            for (final pattern in EventRecurrence.values)
              DropdownMenuItem(value: pattern, child: Text(pattern.label)),
          ],
          onChanged: (pattern) {
            if (pattern != null) {
              setState(() => _recurringPattern = pattern);
            }
          },
        ),
      ),
    );
  }

  Widget _recurringEndTile() {
    return _fieldTile(
      icon: Icons.event_repeat_outlined,
      text: _recurringEndDate == null
          ? 'End date'
          : DateFormat('MMM d, yyyy').format(_recurringEndDate!),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _recurringEndDate ?? _date.add(const Duration(days: 30)),
          firstDate: _date,
          lastDate: DateTime(DateTime.now().year + 3),
        );
        if (picked != null) {
          setState(() => _recurringEndDate = _dateOnly(picked));
        }
      },
    );
  }

  // ------------------------------------------------------------- save

  Widget _saveButton() {
    return BlocBuilder<EventsCubit, EventsState>(
      builder: (context, state) {
        final canSave = _isFormValid && !state.isSaving;
        return SizedBox(
          height: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: canSave ? AppColors.buildPrimaryGradient() : null,
              color: canSave ? null : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: canSave ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save Changes' : 'Create Event',
                      style: const TextStyle(
                        color: Colors.white,
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
      recurringPattern: () => _recurring ? _recurringPattern : null,
      recurringEndDate: () => _recurring ? _recurringEndDate : null,
    );

    final ok = _isEditing
        ? await cubit.update(event)
        : await cubit.create(event);
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_isEditing ? 'Save anyway' : 'Create anyway'),
          ),
        ],
      ),
    );
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
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.themeColor),
      ),
    );
  }

  BoxDecoration _tileDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  Widget _fieldTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppColors.themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _tileDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.themeColor,
            onChanged: onChanged,
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
                  color: Colors.grey[300],
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
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, size: 19),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
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
                          style: TextStyle(color: Colors.grey[600]),
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
                    decoration: BoxDecoration(
                      gradient: AppColors.buildPrimaryGradient(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
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
