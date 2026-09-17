import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';
import 'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_scope.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_form_validation.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_schedule_utils.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_timezone.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/widgets/assignee_picker_sheet.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/attachment_picker_field.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';

/// Create/edit form for a task. A single scrollable mobile form replaces the
/// web design's dialog: basics up top, scheduling and recurrence below.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({this.taskCode, this.editScope, super.key});

  static const String routeName = '/dashboard/tasks/form';

  /// When set, the form edits the existing task with this code.
  final String? taskCode;

  /// Which occurrences this edit applies to, already chosen in the scope sheet
  /// the Edit affordance shows (see `askTaskEditScope`). Null for a create, or
  /// for a one-off task that was never asked — both save as
  /// [TaskEditScope.thisOccurrence]. Validated against the actual edit before
  /// the save is sent, since a scope chosen up front may not fit what changed.
  final TaskEditScope? editScope;

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

  /// code -> name for the chosen assignee(s). Add mode allows many (one task
  /// per assignee, PRD BR-TASK-01). Edit mode pre-selects the whole series
  /// roster: the existing assignees ([_lockedAssignees]) can't be removed, but
  /// new ones can be added and each becomes its own task card on save.
  final Map<String, String> _assignees = {};

  /// Assignees already on the series when editing — shown checked and locked in
  /// the picker (can't be unchecked). Empty in add mode.
  final Set<String> _lockedAssignees = {};

  /// Guards [_prefillFromSeries] so a slow series response can't overwrite the
  /// form after it has already been applied once.
  bool _appliedSeriesPrefill = false;

  /// Whether the task being edited belongs to a **recurring** series, as it
  /// stands on the server — distinct from the editable [_recurring], which the
  /// user may have since flipped. Only a recurring series has several
  /// occurrences to disambiguate, so this (not [_recurring]) decides whether the
  /// save asks for an edit scope. The flat assignment card never carries the
  /// recurrence flag, so the truthful value only arrives with [_prefillFromSeries].
  bool _seriesWasRecurring = false;

  /// The owning series as fetched (§2a) — kept so a save can diff against the
  /// *real* pre-edit schedule via [_editBaseline]. Null until it loads.
  TaskSeries? _series;

  /// True when the form was opened for a task this persona may not edit
  /// (PRD §5.2 "Edit Task — staff: own tasks only"). Resolved in [initState],
  /// before any prefill, so a deep link never even loads the task's fields; the
  /// body then renders a no-access notice instead of the form.
  bool _accessDenied = false;

  TaskStatus _status = TaskStatus.toDo;
  TaskPriority _priority = TaskPriority.medium;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = const TimeOfDay(hour: 17, minute: 0);

  /// The school's IANA timezone — every picker's default/bounds and the
  /// UTC<->local conversion for this form's schedule fields. Seeded from the
  /// best-known cached value so the first frame isn't device-local, then
  /// corrected once [_resolveSchoolTimeZone] completes.
  String _schoolTimeZone = TaskTimezone.lastKnownTimeZone;

  bool _recurring = false;
  TaskRecurrence _recurringPattern = TaskRecurrence.monthly;
  DateTime? _recurringEndDate;
  String _startDay = 'MONDAY';
  String _dueDay = 'FRIDAY';
  int _startMonthDay = 1;
  int _dueMonthDay = 25;

  /// Attachments already on the series, loaded in edit mode. Removing one here
  /// only drops it from this list; the change is persisted by the `assetCodes`
  /// full-replace on save.
  List<TaskAttachment> _existingAttachments = const [];
  bool _loadedExistingAttachments = false;

  /// How many attachments the series had when the form opened. Compared against
  /// [_existingAttachments] on save to tell "user removed some" from "user
  /// never touched attachments" — only the former should send `assetCodes`.
  int _attachmentBaselineCount = 0;

  /// False when the series' attachments could not be read. Editing them is then
  /// disabled rather than silently destructive: `assetCodes` is a full replace,
  /// so saving a list assembled from an unreadable set would delete whatever
  /// the server actually holds. Always true when creating — a task that does
  /// not exist yet has nothing to lose.
  bool _attachmentsReadable = true;

  /// Freshly picked local files, uploaded on submit — identical to the event
  /// form, so an abandoned form uploads nothing.
  List<PickedFile> _attachments = const [];

  /// Live per-file upload progress while a save is running; null otherwise.
  AttachmentUploadState? _uploadState;

  bool get _isUploading => _uploadState?.isUploading ?? false;

  // UPLOAD-ON-PICK REMOVED — the task form used to start the upload the moment a
  // file was picked, which needed its own progress/resume bookkeeping:
  //
  //   final Map<String, int> _uploadProgress = {};
  //   final Map<String, String> _uploadedAssetCodes = {};
  //   bool _uploadingAttachment = false;
  //
  // Both forms now upload on submit through AttachmentUploadManager, which
  // reports per-file progress itself via [_uploadState].

  /// True from the moment Create/Save is tapped until that save settles. The
  /// button's own disabled state can't be the only guard: it takes a frame to
  /// apply, and a second entry into the save would POST a duplicate task.
  bool _isSubmitting = false;

  bool get _isEditing => _editing != null;

  /// Assignees picked in edit mode that weren't already on the series — each
  /// becomes its own task card on save.
  int get _addedAssigneeCount =>
      _assignees.keys.where((c) => !_lockedAssignees.contains(c)).length;

  @override
  void initState() {
    super.initState();
    final today = TaskTimezone.today(_schoolTimeZone);
    _startDate = today;
    _dueDate = today;
    final code = widget.taskCode?.trim() ?? '';
    if (code.isNotEmpty) {
      final tasksState = context.read<TasksCubit>().state;
      final task = tasksState.taskByCode(code);
      if (task != null &&
          !TaskAccess.canManageTask(
            roles: context.read<RoleCubit>(),
            task: task,
            userCode: tasksState.currentUserCode,
            staffCode: tasksState.currentStaffCode,
          )) {
        _accessDenied = true;
      } else if (task != null) {
        _prefill(task);
        // The flat card carries neither the start time-of-day nor the
        // recurrence rule (series-only, bridged by taskCode). Without this the
        // form would show a recurring task as a 09:00 one-off and could drop
        // its recurrence on save — so pull the series and correct those fields.
        unawaited(_prefillFromSeries(task.taskCode));
      }
    }
    unawaited(_resolveSchoolTimeZone());
  }

  /// Resolves the school's real timezone (network/storage), correcting the
  /// cached best-guess seeded in [_schoolTimeZone] and re-deriving every
  /// schedule field so pickers/labels reflect the right zone.
  Future<void> _resolveSchoolTimeZone() async {
    final resolved = await TaskTimezone.resolve();
    if (!mounted || resolved == _schoolTimeZone) return;
    setState(() {
      _schoolTimeZone = resolved;
      final editing = _editing;
      if (editing != null) {
        _applySchedule(editing);
      } else {
        final today = TaskTimezone.today(_schoolTimeZone);
        _startDate = today;
        _dueDate = today;
      }
    });
  }

  void _prefill(Task task) {
    _editing = task;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _effortController.text =
        task.effort > 0 ? TaskUiUtils.effortLabel(task.effort).split(' ').first : '';
    // Pre-select the whole series roster, not just this card's assignee, so the
    // picker shows everyone already on the task. Every loaded sibling card of
    // this series (same taskCode) contributes one assignee; all are locked
    // (can't be removed here), and the user may add more.
    for (final sibling in context.read<TasksCubit>().state.tasks) {
      if (task.taskCode.isEmpty || sibling.taskCode != task.taskCode) continue;
      if (sibling.assigneeCode.isEmpty) continue;
      _assignees[sibling.assigneeCode] = sibling.assigneeName.isNotEmpty
          ? sibling.assigneeName
          : sibling.assigneeCode;
      _lockedAssignees.add(sibling.assigneeCode);
    }
    // Guarantee this card's own assignee is present even if the series list
    // hasn't fully loaded.
    if (task.assigneeCode.isNotEmpty) {
      _assignees.putIfAbsent(
        task.assigneeCode,
        () => task.assigneeName.isNotEmpty
            ? task.assigneeName
            : task.assigneeCode,
      );
      _lockedAssignees.add(task.assigneeCode);
    }
    _status = task.status;
    _priority = task.priority;
    _applySchedule(task);
    _recurring = task.recurring;
    _seriesWasRecurring = task.recurring;
    _recurringPattern = task.recurringPattern ?? TaskRecurrence.monthly;
    _recurringEndDate = task.recurringEndDate;
    if (_recurringPattern == TaskRecurrence.weekly) {
      _startDay = (task.startDay ?? _startDay).toUpperCase();
      _dueDay = (task.dueDay ?? _dueDay).toUpperCase();
    } else if (_recurringPattern == TaskRecurrence.monthly) {
      _startMonthDay = int.tryParse(task.startDay ?? '') ?? _startMonthDay;
      _dueMonthDay = int.tryParse(task.dueDay ?? '') ?? _dueMonthDay;
    }
    // Attachments live on the series, not on the assignment card — fetched
    // separately rather than prefilled from [task].
    unawaited(_loadExistingAttachments(task.taskCode));
  }

  /// Converts [task]'s UTC wire start/due date+time into the school-local
  /// wall-clock values the pickers show. Split out from [_prefill] so
  /// [_resolveSchoolTimeZone] can re-derive just the schedule fields once the
  /// real school timezone loads, without re-running the assignee-roster logic.
  void _applySchedule(Task task) {
    final start = TaskTimezone.fromUtcWire(
      utcDate: task.startDate,
      hhmm: task.startTime,
      ianaName: _schoolTimeZone,
    );
    _startDate = start.$1;
    _startTime = start.$2;
    final due = TaskTimezone.fromUtcWire(
      utcDate: task.dueDate,
      hhmm: task.dueTime,
      ianaName: _schoolTimeZone,
    );
    _dueDate = due.$1;
    _dueTime = due.$2;
  }

  /// Corrects the recurrence fields from the owning series, which the flat
  /// assignment card can't provide (the card's own `startTime`/`dueTime`, §5b,
  /// are already correct and pre-filled by [_prefill] — this must not touch
  /// them). Applied once, right after the form opens, so it only overwrites
  /// the placeholder prefill — not any edits the user has since made.
  Future<void> _prefillFromSeries(String seriesCode) async {
    final code = seriesCode.trim();
    if (code.isEmpty || _appliedSeriesPrefill) return;
    final series = await context.read<TasksCubit>().fetchSeriesDetail(code);
    if (!mounted || series == null || _appliedSeriesPrefill) return;
    setState(() {
      _appliedSeriesPrefill = true;
      _series = series;
      _recurring = series.recurring;
      _seriesWasRecurring = series.recurring;
      if (series.recurring && series.recurrencePattern != null) {
        _recurringPattern = series.recurrencePattern!;
        _recurringEndDate = series.recurrenceUntil;
        switch (series.recurrencePattern!) {
          case TaskRecurrence.weekly:
            if (series.recurrenceByDay.isNotEmpty) {
              _startDay = TaskScheduleUtils.weekdayFromAbbr(
                      series.recurrenceByDay.first) ??
                  _startDay;
            }
            // The RRULE only persists the start weekday; recover the due
            // weekday from this occurrence's due date.
            _dueDay = _weekdays[(_dueDate.weekday - 1).clamp(0, 6)];
            break;
          case TaskRecurrence.monthly:
            _startMonthDay = series.recurrenceByMonthday ?? _startMonthDay;
            _dueMonthDay = _dueDate.day;
            break;
          case TaskRecurrence.daily:
            break;
        }
      }
    });
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
    final roles = context.watch<RoleCubit>();
    // Write gate (PRD §5.2): parents may never create a task, and a staff
    // member may only edit their own. Both cases render a notice rather than an
    // editable form, so no save path exists for them at all.
    if (_accessDenied || (!_isEditing && !TaskAccess.canCreateTasks(roles))) {
      return const GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: false,
        body: _TaskFormNoAccess(),
      );
    }
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: Form(
        key: _formKey,
        // Blocks the AppBar back arrow (routed through Navigator.maybePop, see
        // CustomAppBar) as well as the system back gesture/hardware button —
        // an upload or a create/update in flight must not be abandoned
        // mid-flight by a navigation that the widget tree, and the requests
        // already sent to three different hosts, don't actually stop for.
        canPop: !_busy,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          CoreUtils.showTopSnackBar(
            context: context,
            message: _isSubmitting
                ? 'Please wait for the task to finish saving.'
                : 'Please wait for the attachment to finish uploading.',
            isWarning: true,
          );
        },
        child: AbsorbPointer(
          absorbing: _busy,
          child: AnimatedOpacity(
            opacity: _busy ? 0.6 : 1,
            duration: const Duration(milliseconds: 150),
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
              _label('Task Name', required: true),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration('E.g. Schedule Origami activity'),
                // The save-button gate listens to this controller directly
                // (see [_saveButton]), so no full-form rebuild per keystroke.
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
              _label('Assignee', required: true),
              _assigneePicker(),
              const SizedBox(height: 14),
              _label('Priority'),
              _prioritySelector(),
              const SizedBox(height: 14),
              _label('Status'),
              _statusSelector(),
              const SizedBox(height: 14),
              // A task's type is fixed at creation: the edit form never lets a
              // one-off become recurring (or vice versa), so the toggle is
              // hidden and only the existing type's schedule fields are shown.
              if (!_isEditing)
                _switchTile(
                  title: 'Recurring task',
                  value: _recurring,
                  onChanged: (value) => setState(() => _recurring = value),
                ),
              if (_recurring) ...[
                if (!_isEditing) const SizedBox(height: 8),
                _recurrenceFields(),
              ] else ...[
                if (!_isEditing) const SizedBox(height: 14),
                _label('Start'),
                _dateTimeRow(
                  date: _startDate,
                  time: _startTime,
                  onDate: (d) => setState(() {
                    _startDate = d;
                    // Keep the window non-negative: pull the due date up to the
                    // new start when the start moves past it.
                    if (_dueDate.isBefore(_startDate)) _dueDate = _startDate;
                  }),
                  onTime: (t) => setState(() => _startTime = t),
                ),
                const SizedBox(height: 14),
                _label('Due'),
                _dateTimeRow(
                  date: _dueDate,
                  time: _dueTime,
                  // Disallow picking a due date earlier than the start date.
                  firstDate: _startDate,
                  onDate: (d) => setState(() => _dueDate = d),
                  onTime: (t) => setState(() => _dueTime = t),
                ),
                // Catches a same-day due time earlier than the start time,
                // which the date-only picker limit can't prevent.
                if (!TaskFormValidation.isNonNegativeRange(
                  startDate: _startDate,
                  startTime: _startTime,
                  dueDate: _dueDate,
                  dueTime: _dueTime,
                ))
                  _fieldError('Due must be on or after the start time.'),
              ],
              const SizedBox(height: 14),
              _label('Estimated Effort'),
              TextFormField(
                controller: _effortController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  // Digits-only already blocks a leading '-'; also reject a
                  // second '.' so "1.2.3" can never be entered.
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      '.'.allMatches(newValue.text).length > 1
                          ? oldValue
                          : newValue),
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                // Save-button gate listens to this controller directly.
                validator: (value) => TaskFormValidation.isEffortValid(value ?? '')
                    ? null
                    : 'Enter a valid number of hours',
                decoration: _inputDecoration('in hours'),
              ),
              const SizedBox(height: 14),
              _label('Attachment'),
              _attachmentSection(),
              const SizedBox(height: 22),
              _saveButton(),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  /// True while a save is running or a file is uploading — the whole form
  /// disables itself for this span (see [build]'s `AbsorbPointer`/`PopScope`),
  /// not just the save button, so nothing else can mutate the draft or leave
  /// the screen while a request is on the wire.
  bool get _busy => _isSubmitting || _isUploading;

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
            // Edit mode: adding assignees spins up one new task each; existing
            // assignees are locked and left untouched.
            if (_isEditing && _addedAssigneeCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(
                  '$_addedAssigneeCount new '
                  '${_addedAssigneeCount == 1 ? 'task' : 'tasks'} will be '
                  'created for the added '
                  '${_addedAssigneeCount == 1 ? 'assignee' : 'assignees'}',
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
      builder: (_) => AssigneePickerSheet(
        options: options,
        initialSelection: Map.of(_assignees),
        isLoading: isLoading,
        // Edit mode locks the existing series roster (can't be removed here);
        // add mode has nothing locked. Both allow multi-select.
        lockedCodes: Set.of(_lockedAssignees),
        // Badges the signed-in user's own row (both modes). Uses the cubit's
        // identity codes so "me" here means exactly what it means to the read
        // boundary; empty until identity resolves, which simply omits the badge.
        selfCodes: context.read<TasksCubit>().state.identityCodes,
      ),
    );
    if (result != null) {
      setState(() {
        final previous = Map.of(_assignees);
        _assignees
          ..clear()
          ..addAll(result);
        // The picker can't drop locked assignees, but guard against a stale
        // sheet result so a locked assignee is never lost from the roster.
        for (final code in _lockedAssignees) {
          _assignees.putIfAbsent(code, () => previous[code] ?? code);
        }
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
    final derived = _resolveDates();
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
        // The API mandates the RRULE's UNTIL, so an end date is required and
        // can't precede the derived start.
        if (_recurringEndDate == null)
          _fieldError('Select an "Until" end date.')
        else if (derived != null &&
            !TaskFormValidation.isEndOnOrAfterStart(
              start: derived.start,
              until: _recurringEndDate!,
            ))
          _fieldError('End date can\'t be before the start.'),
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
        // Shows which actual calendar days the picked times apply to — the
        // day-of-month/day-of-week pickers alone don't make that obvious, and
        // a start/due time combination that looks "backwards" (e.g. a due
        // time earlier than the start time) is perfectly valid whenever the
        // derived due date falls on a later day than the derived start.
        if (derived != null) _recurrenceWindowPreview(derived),
        // On a same-day derivation (daily, or a weekly/monthly start==due) the
        // due time must be after the start time.
        if (derived != null &&
            !TaskFormValidation.isNonNegativeRange(
              startDate: derived.start,
              startTime: _startTime,
              dueDate: derived.due,
              dueTime: _dueTime,
            ))
          _fieldError('Due time must be after the start time.'),
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
          ? 'Until date *'
          : DateFormat('MMM d, yyyy').format(_recurringEndDate!),
      onTap: () async {
        final today = TaskTimezone.today(_schoolTimeZone);
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _recurringEndDate ?? today.add(const Duration(days: 30)),
          firstDate: today,
          lastDate: DateTime(today.year + 3),
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

  /// Pulls the series' current attachments into the form once, in edit mode.
  /// Silent on failure: an unavailable attachments endpoint must not block
  /// editing the rest of the task.
  Future<void> _loadExistingAttachments(String taskCode) async {
    if (_loadedExistingAttachments || taskCode.trim().isEmpty) return;
    _loadedExistingAttachments = true;
    final cubit = context.read<TasksCubit>();
    await cubit.ensureAttachmentsLoaded(taskCode);
    if (!mounted) return;
    final code = taskCode.trim();
    final loaded =
        cubit.state.attachmentsByTask[code] ?? const <TaskAttachment>[];
    setState(() {
      _existingAttachments = loaded;
      _attachmentBaselineCount = loaded.length;
      _attachmentsReadable = cubit.state.attachmentsAreReadable(code);
    });
  }

  Widget _attachmentSection() {
    if (!_attachmentsReadable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: _tileDecoration(),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "This task's attachments can't be loaded right now, so they "
                'can\u2019t be changed here. Everything else still saves normally.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }
    // Same widget, same service, same submit-time upload as the event form.
    return AttachmentPickerField(
      files: _attachments,
      onChanged: (files) => setState(() => _attachments = files),
      enabled: !_isUploading && !_isSubmitting,
      uploadState: _uploadState,
    );
  }

  // SUPERSEDED — TaskAttachmentPicker plus the upload-on-pick loop it drove.
  // Replaced by AttachmentPickerField (shared with events) and a submit-time
  // upload. `_existingAttachments` is still preserved through
  // [_resolvedAssetCodes] so editing never full-replaces saved files away.
  //
  //   return TaskAttachmentPicker(
  //     existing: _existingAttachments,
  //     pending: _pendingAttachments,
  //     uploadService: context.read<TasksCubit>().imageUploadService,
  //     uploadProgress: _uploadProgress,
  //     uploadedPaths: _uploadedAssetCodes.keys.toSet(),
  //     isUploading: _uploadingAttachment,
  //     enabled: !_uploadingAttachment && !_isSubmitting,
  //     onPendingChanged: (files) {
  //       setState(() => _pendingAttachments = files);
  //       unawaited(_uploadPickedAttachments());
  //     },
  //     onExistingRemoved: (attachment) => setState(() {
  //       _existingAttachments = _existingAttachments
  //           .where((a) => a.assetCode != attachment.assetCode)
  //           .toList();
  //     }),
  //   );
  //
  // List<PickedFile> get _notYetUploaded => ...
  // Future<void> _uploadPickedAttachments() async { ... }
  // Future<bool> _uploadOutstanding() async { ... }

  /// The full `assetCodes` list to persist — kept existing assets first, then
  /// the newly uploaded ones — or null when a held file still isn't in storage.
  ///
  /// Because `assetCodes` is a full replace (§3c), an attachment the user
  /// removed simply doesn't appear in the returned list.
  List<String> _resolvedAssetCodes(List<String> uploadedCodes) {
    return <String>[
      ..._existingAttachments
          .map((a) => a.assetCode)
          .where((code) => code.isNotEmpty),
      ...uploadedCodes,
    ];
  }

  /// The series' complete attachment set after this save, for
  /// [TasksCubit.primeAttachments]. Freshly uploaded rows carry no `ATT_…` code
  /// (only the list endpoint mints those), but they do carry the asset code the
  /// thumbnail resolves its URL from, plus the local name/type/size so the row
  /// reads properly without a re-read.
  List<TaskAttachment> _attachmentsAfterSave(List<PickedFile> uploaded,
      List<String> codes) {
    return <TaskAttachment>[
      ..._existingAttachments.where((a) => a.assetCode.isNotEmpty),
      for (var i = 0; i < uploaded.length && i < codes.length; i++)
        TaskAttachment(
          assetCode: codes[i],
          fileName: uploaded[i].name,
          contentType: uploaded[i].mimeType,
          sizeBytes: uploaded[i].sizeBytes,
          mediaType: uploaded[i].mediaType,
        ),
    ];
  }

  // ------------------------------------------------------------- save

  Widget _saveButton() {
    // Mandatory-field gate (PRD FR-TK-09): title + assignee always, plus a
    // non-negative start→due window. For a recurring task the window is its
    // *derived* one (resolved from the recurrence fields) and it must also
    // carry a valid "Until" end date; effort, when present, must be a valid
    // non-negative number.
    //
    // The title/effort text feed this gate, so rather than `setState(() {})` on
    // every keystroke (which would rebuild the whole form), listen to just the
    // two controllers here and recompute the gate inside this subtree.
    return ListenableBuilder(
      listenable: Listenable.merge([_titleController, _effortController]),
      builder: (context, _) {
        final window = _windowForValidation();
        final canSave = TaskFormValidation.canSubmit(
              title: _titleController.text,
              hasAssignee: _assignees.isNotEmpty,
              recurring: _recurring,
              startDate: window.start,
              startTime: _startTime,
              dueDate: window.due,
              dueTime: _dueTime,
              recurrenceEnd: _recurring ? _recurringEndDate : null,
            ) &&
            TaskFormValidation.isEffortValid(_effortController.text);
        return BlocBuilder<TasksCubit, TasksState>(
          builder: (context, state) {
            // [_busy] already spans the whole create/update request (it's set
            // before cubit.create/update is awaited and cleared after), so
            // `state.isSaving` is only here as a defense-in-depth check —
            // without it a live "Create Task" button during the upload would
            // read as "nothing happened" and invite the taps that create
            // duplicates.
            final busy = _busy || state.isSaving;
            final enabled = canSave && !busy;
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
              child: busy
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
      },
    );
  }

  Future<void> _save() async {
    // The button is disabled while busy, but a queued tap can still land
    // between the tap and the first frame that reflects it — and a second
    // entry here would open its own upload session and POST a duplicate task.
    if (_isSubmitting || _isUploading) return;
    setState(() => _isSubmitting = true);
    try {
      await _submit();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      } else {
        _isSubmitting = false;
      }
    }
  }

  Future<void> _submit() async {
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
    // The form works in school-local wall-clock terms throughout; convert to
    // the UTC date + `HH:mm` the Tasks API wire format expects only now, right
    // before building the draft that gets sent.
    final startUtc = TaskTimezone.toUtcWire(
      date: dates.start,
      time: _startTime,
      ianaName: _schoolTimeZone,
    );
    final dueUtc = TaskTimezone.toUtcWire(
      date: dates.due,
      time: _dueTime,
      ianaName: _schoolTimeZone,
    );
    final base = _editing ??
        Task(
          code: '',
          title: '',
          startDate: startUtc.$1,
          dueDate: dueUtc.$1,
          createdAt: now,
          updatedAt: now,
        );

    final draft = base.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      priority: _priority,
      startDate: startUtc.$1,
      startTime: startUtc.$2,
      dueDate: dueUtc.$1,
      dueTime: dueUtc.$2,
      effort: effort,
      recurring: _recurring,
      recurringPattern: () => _recurring ? _recurringPattern : null,
      recurringEndDate: () => _recurring ? _recurringEndDate : null,
      startDay: () => _recurringDayValue(isStart: true),
      dueDay: () => _recurringDayValue(isStart: false),
    );

    // Validate the scope chosen back on Edit against what actually changed,
    // before anything is persisted or uploaded — a refused combination must
    // leave the task, and the storage bucket, exactly as they were.
    final TaskEditScope scope;
    if (_isEditing) {
      final validated = _validatedEditScope(cubit, draft);
      // Not expressible under the chosen scope: the toast has said why, so stop
      // here without sending anything.
      if (validated == null) return;
      scope = validated;
    } else {
      scope = TaskEditScope.thisOccurrence;
    }

    // Upload the staged files now, on submit — one session, one batched
    // presign, bounded-parallel transfers. Identical to the event form; a failed
    // upload aborts the save so a task is never persisted without its files.
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
    final resolvedAssetCodes = _resolvedAssetCodes(uploadedAssetCodes);

    final bool ok;
    // The series this save wrote attachments onto, and whether it wrote them at
    // all — a create learns its series code from the response.
    String seriesCode = '';
    bool wroteAttachments = false;
    if (_isEditing) {
      // Attachments persist through the series' assetCodes full-replace (§3c).
      // Send the resolved list whenever the user touched attachments at all
      // (added or removed); null otherwise, to leave them untouched.
      // Never write attachments we could not read (see [_attachmentsReadable]).
      final attachmentsChanged = _attachmentsReadable &&
          (_attachments.isNotEmpty ||
              _existingAttachments.length != _attachmentBaselineCount);
      final assetCodes = attachmentsChanged ? resolvedAssetCodes : null;
      seriesCode = _editing?.taskCode.trim() ?? '';
      wroteAttachments = assetCodes != null;
      // The card being edited keeps its own assignee (draft inherits it from
      // _editing). Anything picked that wasn't already on the series is a new
      // assignee; the cubit appends each to the roster so the backend
      // materializes a new task card for them.
      final added = _assignees.entries
          .where((e) => !_lockedAssignees.contains(e.key))
          .map((e) => (code: e.key, name: e.value))
          .toList();
      ok = await cubit.update(
        draft,
        assetCodes: assetCodes,
        addedAssignees: added,
        scope: scope,
        baseline: _editBaseline(),
      );
    } else {
      final assignees = _assignees.entries
          .map((e) => (code: e.key, name: e.value))
          .toList();
      final createdSeriesCode =
          await cubit.create(draft, assignees, assetCodes: resolvedAssetCodes);
      ok = createdSeriesCode != null;
      seriesCode = createdSeriesCode?.trim() ?? '';
      wroteAttachments = true;
    }

    if (!mounted) return;
    if (ok) {
      // The card and detail screens read attachments from the cubit's cache.
      // Prime it with what we just wrote (`assetCodes` is a full replace, so
      // this list *is* the series' set) rather than only asking the server —
      // the Tasks API documents no attachments read endpoint, and without this
      // a just-attached file would be invisible until one appears.
      if (seriesCode.isNotEmpty && wroteAttachments) {
        cubit.primeAttachments(
          seriesCode,
          _attachmentsAfterSave(_attachments, uploadedAssetCodes),
        );
      }
      // Then reconcile in the background: if the read endpoint does exist it
      // replaces the primed rows with the server's (which carry the `ATT_…`
      // codes detach needs); if it doesn't, the primed set survives.
      if (seriesCode.isNotEmpty) {
        unawaited(cubit.refreshAttachments(seriesCode));
      }
      final String message;
      if (_isEditing) {
        final added = _addedAssigneeCount;
        message = added > 0
            ? 'Task updated · $added new ${added == 1 ? 'task' : 'tasks'} '
                'created'
            : 'Task updated';
      } else {
        message = _assignees.length > 1
            ? '${_assignees.length} tasks created'
            : 'Task created';
      }
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
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

  /// The pre-edit task a save is diffed against: the card the form opened with,
  /// plus the owning series' recurrence — which the flat assignment card never
  /// carries, so without it every recurring save would look like a recurrence
  /// change and cascade away future occurrences. Falls back to the bare card
  /// when the series never loaded (which also means the scope sheet is skipped,
  /// so the save stays on the narrow per-assignment endpoint).
  Task? _editBaseline() {
    final editing = _editing;
    if (editing == null) return null;
    final series = _series;
    return series == null
        ? editing
        : TaskScheduleUtils.withSeriesSchedule(editing, series);
  }

  /// How far this save should reach, or null when it must not be sent at all.
  ///
  /// The scope was already chosen when the user tapped Edit ([widget.editScope],
  /// via `askTaskEditScope`), so this normally just hands it back. That choice
  /// was made before anything was edited, though, and two of the three scopes
  /// can't express every edit: §3d needs a changed schedule/repeat pattern to
  /// reanchor, and a repeat-pattern change has no per-occurrence form at all.
  ///
  /// This is the form's last validation gate. When the chosen scope doesn't fit
  /// the edit it returns null after surfacing the reason as a toast — the Save
  /// button stays enabled (the form isn't invalid, the *combination* is), the
  /// request is never sent, and the user's edits are left intact so they can
  /// adjust the form and save again.
  TaskEditScope? _validatedEditScope(TasksCubit cubit, Task draft) {
    final editing = _editing!;
    final chosen = widget.editScope ?? TaskEditScope.thisOccurrence;
    // Compare in school-local terms: the card's occurrence date is a UTC wire
    // date, and "has this occurrence passed?" is a school-calendar question.
    final occurrence = TaskTimezone.fromUtcWire(
      utcDate: editing.startDate,
      hhmm: editing.startTime,
      ianaName: _schoolTimeZone,
    );
    final prompt = TaskEditScopePrompt.forSave(
      seriesIsRecurring: _seriesWasRecurring,
      diff: cubit.diffFor(
        draft,
        hasAddedAssignees: _addedAssigneeCount > 0,
        baseline: _editBaseline(),
      ),
      occurrenceDate: occurrence.$1,
      today: TaskTimezone.today(_schoolTimeZone),
    );
    // A one-off was never asked, so it always saves in place.
    if (!prompt.isRequired) return prompt.scopeWhenNotAsked;
    if (prompt.canUse(chosen)) return chosen;

    CoreUtils.showTopSnackBar(
      context: context,
      message: prompt.saveBlockedMessage(chosen) ??
          "This edit can't be saved for the occurrences you chose.",
      isWarning: true,
    );
    return null;
  }

  /// The start/due window the validation gate reasons about: a one-off's own
  /// dates, or a recurring task's *derived* dates. Never null (unlike
  /// [_resolveDates], which rejects an invalid one-off window) so the gate can
  /// evaluate the range itself and surface the reason inline.
  ({DateTime start, DateTime due}) _windowForValidation() {
    if (!_recurring) return (start: _startDate, due: _dueDate);
    return _resolveDates() ?? (start: _startDate, due: _dueDate);
  }

  /// Shows the concrete calendar dates the recurrence resolves to for its next
  /// occurrence, alongside the picked times — so it's clear which day each
  /// time-of-day actually falls on (a due time that reads "earlier" than the
  /// start time is fine whenever the due date itself is a later day).
  Widget _recurrenceWindowPreview(({DateTime start, DateTime due}) window) {
    final startLabel = DateFormat('EEE, MMM d').format(window.start);
    final dueLabel = DateFormat('EEE, MMM d').format(window.due);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_available_outlined, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Next occurrence: $startLabel, ${_startTime.format(context)} → '
              '$dueLabel, ${_dueTime.format(context)}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  /// A small red field-level error line shown beneath an invalid input.
  Widget _fieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Text(
        message,
        style: const TextStyle(fontSize: 11.5, color: AppColors.errorColor),
      ),
    );
  }

  /// Resolves the concrete start/due dates from the form, applying recurring
  /// day logic (PRD FR-TK-06/07/08, BR-REC-03/04). Returns null when the
  /// non-recurring due date precedes the start date.
  ({DateTime start, DateTime due})? _resolveDates() {
    if (!_recurring) {
      // Reject negative windows at the datetime level, so 16th 00:00 → 15th
      // 23:59 (and same-day due-before-start) are caught, not just date-only.
      if (!TaskFormValidation.isNonNegativeRange(
        startDate: _startDate,
        startTime: _startTime,
        dueDate: _dueDate,
        dueTime: _dueTime,
      )) {
        return null;
      }
      return (start: _startDate, due: _dueDate);
    }
    switch (_recurringPattern) {
      case TaskRecurrence.daily:
        final today = TaskTimezone.today(_schoolTimeZone);
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
    DateTime? firstDate,
  }) {
    final schoolToday = TaskTimezone.today(_schoolTimeZone);
    final effectiveFirst = firstDate ?? DateTime(schoolToday.year - 1);
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
                // initialDate must satisfy firstDate; clamp when the current
                // value predates it (e.g. a due date behind the start).
                initialDate:
                    date.isBefore(effectiveFirst) ? effectiveFirst : date,
                firstDate: effectiveFirst,
                lastDate: DateTime(schoolToday.year + 3),
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
    final now = TaskTimezone.today(_schoolTimeZone);
    if (target < 1) return now;
    var diff = (target - now.weekday) % 7;
    if (diff < 0) diff += 7;
    return now.add(Duration(days: diff));
  }

  DateTime _monthlyDate(int day, {int monthOffset = 0}) {
    final now = TaskTimezone.today(_schoolTimeZone);
    final base = DateTime(now.year, now.month + monthOffset, 1);
    final lastDay = DateTime(base.year, base.month + 1, 0).day;
    final clamped = day.clamp(1, lastDay);
    return DateTime(base.year, base.month, clamped);
  }

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

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

/// Body shown in place of the form when the persona may not create this task or
/// edit this one (PRD §5.2). Shows no task fields at all.
class _TaskFormNoAccess extends StatelessWidget {
  const _TaskFormNoAccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 44, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'You do not have permission to edit this task.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
