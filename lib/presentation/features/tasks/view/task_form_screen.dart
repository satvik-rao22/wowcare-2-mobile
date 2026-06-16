import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Create/edit form for a task. A single scrollable mobile form replaces the
/// web design's dialog: basics up top, scheduling and recurrence below.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({this.taskCode, super.key});

  static const String routeName = '/dashboard/tasks/form';

  /// When set, the form edits the existing task with this code.
  final String? taskCode;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  static const List<String> _weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _effortController = TextEditingController();

  Task? _editing;

  /// code -> name for the chosen assignee(s). Add mode allows many
  /// (one task per assignee, PRD BR-TASK-01); edit mode keeps a single entry.
  final Map<String, String> _assignees = {};

  TaskStatus _status = TaskStatus.toDo;
  TaskPriority _priority = TaskPriority.medium;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = const TimeOfDay(hour: 17, minute: 0);

  bool _recurring = false;
  TaskRecurrence _recurringPattern = TaskRecurrence.monthly;
  DateTime? _recurringEndDate;
  String _startDay = 'MONDAY';
  String _dueDay = 'FRIDAY';
  int _startMonthDay = 1;
  int _dueMonthDay = 25;

  String? _attachmentName;
  String? _attachmentUrl;
  String? _attachmentType;

  bool get _isEditing => _editing != null;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _startDate = today;
    _dueDate = today;
    final code = widget.taskCode?.trim() ?? '';
    if (code.isNotEmpty) {
      final task = context.read<TasksCubit>().state.taskByCode(code);
      if (task != null) _prefill(task);
    }
  }

  void _prefill(Task task) {
    _editing = task;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _effortController.text =
        task.effort > 0 ? TaskUiUtils.effortLabel(task.effort).split(' ').first : '';
    if (task.assigneeCode.isNotEmpty) {
      _assignees[task.assigneeCode] = task.assigneeName;
    }
    _status = task.status;
    _priority = task.priority;
    _startDate = _dateOnly(task.startDate);
    _startTime = _parseTime(task.startTime) ?? _startTime;
    _dueDate = _dateOnly(task.dueDate);
    _dueTime = _parseTime(task.dueTime) ?? _dueTime;
    _recurring = task.recurring;
    _recurringPattern = task.recurringPattern ?? TaskRecurrence.monthly;
    _recurringEndDate = task.recurringEndDate;
    if (_recurringPattern == TaskRecurrence.weekly) {
      _startDay = (task.startDay ?? _startDay).toUpperCase();
      _dueDay = (task.dueDay ?? _dueDay).toUpperCase();
    } else if (_recurringPattern == TaskRecurrence.monthly) {
      _startMonthDay = int.tryParse(task.startDay ?? '') ?? _startMonthDay;
      _dueMonthDay = int.tryParse(task.dueDay ?? '') ?? _dueMonthDay;
    }
    _attachmentName = task.attachmentName;
    _attachmentUrl = task.attachmentUrl;
    _attachmentType = task.attachmentType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _effortController.dispose();
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
                _isEditing ? 'Edit Task' : 'New Task',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _label('Task Name'),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration('E.g. Schedule Origami activity'),
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              _label('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration('Add context for this task…'),
              ),
              const SizedBox(height: 14),
              _label('Assignee'),
              _assigneePicker(),
              const SizedBox(height: 14),
              _label('Priority'),
              _prioritySelector(),
              const SizedBox(height: 14),
              _label('Status'),
              _statusSelector(),
              const SizedBox(height: 14),
              _switchTile(
                title: 'Recurring task',
                value: _recurring,
                onChanged: (value) => setState(() => _recurring = value),
              ),
              if (_recurring) ...[
                const SizedBox(height: 8),
                _recurrenceFields(),
              ] else ...[
                const SizedBox(height: 14),
                _label('Start'),
                _dateTimeRow(
                  date: _startDate,
                  time: _startTime,
                  onDate: (d) => setState(() => _startDate = d),
                  onTime: (t) => setState(() => _startTime = t),
                ),
                const SizedBox(height: 14),
                _label('Due'),
                _dateTimeRow(
                  date: _dueDate,
                  time: _dueTime,
                  onDate: (d) => setState(() => _dueDate = d),
                  onTime: (t) => setState(() => _dueTime = t),
                ),
              ],
              const SizedBox(height: 14),
              _label('Estimated Effort'),
              TextFormField(
                controller: _effortController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _inputDecoration('in hours'),
              ),
              const SizedBox(height: 14),
              _label('Attachment'),
              _attachmentTile(),
              const SizedBox(height: 22),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------- assignee

  Widget _assigneePicker() {
    return BlocBuilder<StaffCubit, StaffState>(
      builder: (context, state) {
        // Only ACTIVE staff are selectable (PRD BR-ATT-01 / FR-TK-02). The
        // StaffCubit already loads ACTIVE by default; guard again here.
        final options = state.items
            .where((s) =>
                s.status.trim().isEmpty ||
                s.status.toUpperCase() == 'ACTIVE')
            .map((s) => (code: s.code, name: s.name))
            .toList();
        final subtitle = _assignees.isEmpty
            ? 'Select staff'
            : _assignees.values.join(', ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openAssigneeSheet(options, state.isLoading),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: TaskUiUtils.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 19, color: TaskUiUtils.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assignee'
                              '${_assignees.isEmpty ? '' : ' (${_assignees.length})'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TaskUiUtils.accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[500]),
                    ],
                  ),
                ),
              ),
            ),
            // PRD FR-TK-03: multi-select in add mode creates one task each.
            if (!_isEditing && _assignees.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(
                  '${_assignees.length} separate tasks will be created '
                  '(one for each assignee)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TaskUiUtils.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openAssigneeSheet(
    List<({String code, String name})> options,
    bool isLoading,
  ) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AssigneeSheet(
        options: options,
        initialSelection: Map.of(_assignees),
        isLoading: isLoading,
        // Edit mode is single-select (PRD FR-TK-04 / BR-TASK-02).
        singleSelect: _isEditing,
      ),
    );
    if (result != null) {
      setState(() {
        _assignees
          ..clear()
          ..addAll(result);
      });
    }
  }

  // --------------------------------------------------------- priority

  Widget _prioritySelector() {
    return Row(
      children: [
        for (final priority in TaskPriority.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _priority = priority),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _priority == priority
                      ? TaskUiUtils.priorityColor(priority)
                          .withValues(alpha: 0.14)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _priority == priority
                        ? TaskUiUtils.priorityColor(priority)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  priority.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _priority == priority
                        ? TaskUiUtils.priorityColor(priority)
                        : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ----------------------------------------------------------- status

  Widget _statusSelector() {
    return Column(
      children: [
        for (final status in TaskStatus.values)
          GestureDetector(
            onTap: () => setState(() => _status = status),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _status == status
                    ? TaskUiUtils.statusBackground(status)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _status == status
                      ? TaskUiUtils.statusColor(status)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _status == status
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: _status == status
                        ? TaskUiUtils.statusColor(status)
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _status == status
                          ? TaskUiUtils.statusColor(status)
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------- recurrence

  Widget _recurrenceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _recurrenceDropdown()),
            const SizedBox(width: 8),
            Expanded(child: _recurringEndTile()),
          ],
        ),
        const SizedBox(height: 10),
        if (_recurringPattern == TaskRecurrence.weekly) ...[
          _label('Start day'),
          _weekdayDropdown(
            value: _startDay,
            onChanged: (v) => setState(() => _startDay = v),
          ),
          const SizedBox(height: 10),
          _label('Due day'),
          _weekdayDropdown(
            value: _dueDay,
            onChanged: (v) => setState(() => _dueDay = v),
          ),
        ] else if (_recurringPattern == TaskRecurrence.monthly) ...[
          _label('Start day of month'),
          _monthDayDropdown(
            value: _startMonthDay,
            onChanged: (v) => setState(() => _startMonthDay = v),
          ),
          const SizedBox(height: 10),
          _label('Due day of month'),
          _monthDayDropdown(
            value: _dueMonthDay,
            onChanged: (v) => setState(() => _dueMonthDay = v),
          ),
        ] else ...[
          // Daily recurrence defaults start/due to today (PRD FR-TK-06).
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TaskUiUtils.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Daily tasks start today and recur every day until the end '
              'date.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _fieldTile(
                icon: Icons.access_time,
                text: 'Start  ${_startTime.format(context)}',
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: _startTime);
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _fieldTile(
                icon: Icons.access_time,
                text: 'Due  ${_dueTime.format(context)}',
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: _dueTime);
                  if (picked != null) setState(() => _dueTime = picked);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _recurrenceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _tileDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskRecurrence>(
          value: _recurringPattern,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            for (final pattern in TaskRecurrence.values)
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
          ? 'Until (optional)'
          : DateFormat('MMM d, yyyy').format(_recurringEndDate!),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _recurringEndDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: _dateOnly(DateTime.now()),
          lastDate: DateTime(DateTime.now().year + 3),
        );
        if (picked != null) {
          setState(() => _recurringEndDate = _dateOnly(picked));
        }
      },
    );
  }

  Widget _weekdayDropdown({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _tileDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            for (final day in _weekdays)
              DropdownMenuItem(value: day, child: Text(_titleCase(day))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _monthDayDropdown({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _tileDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            for (var day = 1; day <= 30; day++)
              DropdownMenuItem(value: day, child: Text(_ordinal(day))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------- attachment

  Widget _attachmentTile() {
    if (_attachmentName != null && _attachmentName!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _tileDecoration(),
        child: Row(
          children: [
            const Icon(Icons.attach_file,
                size: 18, color: AppColors.themeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _attachmentName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _attachmentName = null;
                _attachmentUrl = null;
                _attachmentType = null;
              }),
              child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return _fieldTile(
      icon: Icons.upload_file_outlined,
      text: 'Add attachment (JPEG, PNG, WebP, PDF • max 10MB)',
      onTap: () => CoreUtils.showTopSnackBar(
        context: context,
        message: 'File attachments will be available once the backend is '
            'connected.',
        isWarning: true,
      ),
    );
  }

  // ------------------------------------------------------------- save

  Widget _saveButton() {
    final canSave =
        _titleController.text.trim().isNotEmpty && _assignees.isNotEmpty;
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final enabled = canSave && !state.isSaving;
        return SizedBox(
          height: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: enabled ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.grey.shade300,
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
                      _isEditing ? 'Save Changes' : 'Create Task',
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
    if (_assignees.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Select at least one assignee',
        isWarning: true,
      );
      return;
    }

    final dates = _resolveDates();
    if (dates == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Due date must be on or after the start date',
        isWarning: true,
      );
      return;
    }

    final cubit = context.read<TasksCubit>();
    final effort = double.tryParse(_effortController.text.trim()) ?? 0;
    final now = DateTime.now();
    final base = _editing ??
        Task(
          code: '',
          title: '',
          startDate: dates.start,
          dueDate: dates.due,
          createdAt: now,
          updatedAt: now,
        );

    final draft = base.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      priority: _priority,
      startDate: dates.start,
      startTime: _formatTime(_startTime),
      dueDate: dates.due,
      dueTime: _formatTime(_dueTime),
      effort: effort,
      recurring: _recurring,
      recurringPattern: () => _recurring ? _recurringPattern : null,
      recurringEndDate: () => _recurring ? _recurringEndDate : null,
      startDay: () => _recurringDayValue(isStart: true),
      dueDay: () => _recurringDayValue(isStart: false),
      attachmentName: () => _attachmentName,
      attachmentUrl: () => _attachmentUrl,
      attachmentType: () => _attachmentType,
    );

    final bool ok;
    if (_isEditing) {
      final entry = _assignees.entries.first;
      ok = await cubit.update(
        draft.copyWith(
          assigneeCode: entry.key,
          assigneeName: entry.value,
        ),
      );
    } else {
      final assignees = _assignees.entries
          .map((e) => (code: e.key, name: e.value))
          .toList();
      ok = await cubit.create(draft, assignees);
    }

    if (!mounted) return;
    if (ok) {
      final created = !_isEditing && _assignees.length > 1;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _isEditing
            ? 'Task updated'
            : created
                ? '${_assignees.length} tasks created'
                : 'Task created',
        isSuccess: true,
      );
      context.pop();
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not save the task. Please try again.',
        isError: true,
      );
    }
  }

  /// Resolves the concrete start/due dates from the form, applying recurring
  /// day logic (PRD FR-TK-06/07/08, BR-REC-03/04). Returns null when the
  /// non-recurring due date precedes the start date.
  ({DateTime start, DateTime due})? _resolveDates() {
    if (!_recurring) {
      if (_dueDate.isBefore(_startDate)) return null;
      return (start: _startDate, due: _dueDate);
    }
    switch (_recurringPattern) {
      case TaskRecurrence.daily:
        final today = _dateOnly(DateTime.now());
        return (start: today, due: today);
      case TaskRecurrence.weekly:
        final start = _nextWeekday(_startDay);
        var due = _nextWeekday(_dueDay);
        if (due.isBefore(start)) due = due.add(const Duration(days: 7));
        return (start: start, due: due);
      case TaskRecurrence.monthly:
        final start = _monthlyDate(_startMonthDay);
        // dueDay < startDay rolls into next month (PRD BR-REC-03).
        final due = _dueMonthDay < _startMonthDay
            ? _monthlyDate(_dueMonthDay, monthOffset: 1)
            : _monthlyDate(_dueMonthDay);
        return (start: start, due: due);
    }
  }

  String? _recurringDayValue({required bool isStart}) {
    if (!_recurring) return null;
    switch (_recurringPattern) {
      case TaskRecurrence.daily:
        return null;
      case TaskRecurrence.weekly:
        return isStart ? _startDay : _dueDay;
      case TaskRecurrence.monthly:
        return (isStart ? _startMonthDay : _dueMonthDay).toString();
    }
  }

  // ------------------------------------------------------ field helpers

  Widget _dateTimeRow({
    required DateTime date,
    required TimeOfDay time,
    required ValueChanged<DateTime> onDate,
    required ValueChanged<TimeOfDay> onTime,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _fieldTile(
            icon: Icons.calendar_today_outlined,
            text: DateFormat('EEE, MMM d').format(date),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime(DateTime.now().year + 3),
              );
              if (picked != null) onDate(_dateOnly(picked));
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _fieldTile(
            icon: Icons.access_time,
            text: time.format(context),
            onTap: () async {
              final picked =
                  await showTimePicker(context: context, initialTime: time);
              if (picked != null) onTime(picked);
            },
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
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

  // ------------------------------------------------------------ helpers

  DateTime _nextWeekday(String dayName) {
    final target = _weekdays.indexOf(dayName.toUpperCase()) + 1; // 1..7
    final now = _dateOnly(DateTime.now());
    if (target < 1) return now;
    var diff = (target - now.weekday) % 7;
    if (diff < 0) diff += 7;
    return now.add(Duration(days: diff));
  }

  DateTime _monthlyDate(int day, {int monthOffset = 0}) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month + monthOffset, 1);
    final lastDay = DateTime(base.year, base.month + 1, 0).day;
    final clamped = day.clamp(1, lastDay);
    return DateTime(base.year, base.month, clamped);
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

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}

/// Searchable assignee picker. Multi-select in add mode (one task per
/// assignee, PRD FR-TK-03); single-select in edit mode (PRD FR-TK-04). Only
/// ACTIVE staff are passed in by the caller.
class _AssigneeSheet extends StatefulWidget {
  const _AssigneeSheet({
    required this.options,
    required this.initialSelection,
    required this.isLoading,
    required this.singleSelect,
  });

  final List<({String code, String name})> options;
  final Map<String, String> initialSelection;
  final bool isLoading;
  final bool singleSelect;

  @override
  State<_AssigneeSheet> createState() => _AssigneeSheetState();
}

class _AssigneeSheetState extends State<_AssigneeSheet> {
  late final Map<String, String> _selection = Map.of(widget.initialSelection);
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) =>
            _query.isEmpty ||
            o.name.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.singleSelect ? 'Select assignee' : 'Select assignees',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search staff…',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Colors.grey[500]),
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
                              'No active staff found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final staff = filtered[index];
                              final checked =
                                  _selection.containsKey(staff.code);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                activeColor: AppColors.themeColor,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                title: Text(
                                  staff.name.isNotEmpty
                                      ? staff.name
                                      : staff.code,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                                onChanged: (_) {
                                  setState(() {
                                    if (widget.singleSelect) {
                                      _selection
                                        ..clear()
                                        ..[staff.code] = staff.name;
                                    } else if (checked) {
                                      _selection.remove(staff.code);
                                    } else {
                                      _selection[staff.code] = staff.name;
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
                      onPressed: () => Navigator.pop(context, _selection),
                      child: Text(
                        widget.singleSelect
                            ? 'Done'
                            : 'Done (${_selection.length})',
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
