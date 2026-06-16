import 'package:equatable/equatable.dart';

/// Workflow column a task sits in. Stored/transported as the uppercase
/// [value] string so backend integration only has to agree on codes
/// (PRD §15.4 `status` ENUM: To Do | In Progress | Completed).
enum TaskStatus {
  toDo('TO_DO'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED');

  const TaskStatus(this.value);

  final String value;

  String get label {
    switch (this) {
      case TaskStatus.toDo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  static TaskStatus fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase().replaceAll(' ', '_');
    return TaskStatus.values.firstWhere(
      (s) => s.value == normalized,
      orElse: () => TaskStatus.toDo,
    );
  }
}

/// Task urgency (PRD §15.4 `priority` ENUM). Default Medium.
enum TaskPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const TaskPriority(this.value);

  final String value;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  static TaskPriority fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    return TaskPriority.values.firstWhere(
      (p) => p.value == normalized,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Repeat cadence for recurring tasks (PRD §11.1 Cycle).
enum TaskRecurrence {
  daily('DAILY'),
  weekly('WEEKLY'),
  monthly('MONTHLY');

  const TaskRecurrence(this.value);

  final String value;

  String get label {
    switch (this) {
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekly:
        return 'Weekly';
      case TaskRecurrence.monthly:
        return 'Monthly';
    }
  }

  static TaskRecurrence? fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    for (final pattern in TaskRecurrence.values) {
      if (pattern.value == normalized) return pattern;
    }
    return null;
  }
}

/// A unit of work assigned to a single staff member (PRD §15.4 `tasks`).
///
/// The assignee is denormalized ([assigneeCode] + [assigneeName]) so cards
/// and lists render without a lookup against the Staff module — the same
/// pattern used by `EventAttendee`. Multi-assignee creation produces one
/// [Task] per assignee (PRD BR-TASK-01), so the entity itself stays single.
class Task extends Equatable {
  const Task({
    required this.code,
    required this.title,
    this.description = '',
    this.assigneeCode = '',
    this.assigneeName = '',
    this.status = TaskStatus.toDo,
    this.priority = TaskPriority.medium,
    required this.startDate,
    this.startTime = '09:00',
    required this.dueDate,
    this.dueTime = '17:00',
    this.effort = 0,
    this.recurring = false,
    this.recurringPattern,
    this.recurringEndDate,
    this.startDay,
    this.dueDay,
    this.attachmentName,
    this.attachmentUrl,
    this.attachmentType,
    this.createdBy = '',
    this.createdByName = '',
    this.schoolCode = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String code;
  final String title;
  final String description;

  /// Single staff assignee (PRD §15.4 `assignee_id`). Denormalized name
  /// keeps cards lookup-free.
  final String assigneeCode;
  final String assigneeName;

  final TaskStatus status;
  final TaskPriority priority;

  /// Calendar day the task starts; time-of-day lives in [startTime] as
  /// `HH:mm` (defaults 09:00 per PRD FR-TK-09).
  final DateTime startDate;
  final String startTime;

  /// Calendar day the task is due; time-of-day lives in [dueTime] as
  /// `HH:mm` (defaults 17:00 per PRD FR-TK-09). Overdue is derived from
  /// [dueDate] + [dueTime].
  final DateTime dueDate;
  final String dueTime;

  /// Estimated hours (PRD §15.4 `effort`, stored as a float; 0 default).
  final double effort;

  final bool recurring;
  final TaskRecurrence? recurringPattern;

  /// Optional "Until Date" for the recurring series (PRD §11.1).
  final DateTime? recurringEndDate;

  /// Weekly recurrence: day name (e.g. `MONDAY`). Monthly recurrence:
  /// day-of-month as a string (`1`–`30`). Null for non-recurring/daily
  /// (PRD §11.1 Start/Due Day).
  final String? startDay;
  final String? dueDay;

  final String? attachmentName;
  final String? attachmentUrl;
  final String? attachmentType;

  /// Staff code of the creator (PRD audit log). Distinct from [assigneeCode];
  /// an admin can create a task assigned to someone else.
  final String createdBy;
  final String createdByName;

  /// Owning school (PRD §15.4 `school_id`, row-level security key). Kept for
  /// forward-compatibility with the backend even though local mock data is
  /// single-school.
  final String schoolCode;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Combined due moment from [dueDate] and [dueTime] (`HH:mm`).
  DateTime get dueAt {
    final parts = dueTime.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) ?? 17 : 17;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(dueDate.year, dueDate.month, dueDate.day, hour, minute);
  }

  /// Overdue when the due moment has passed and the task isn't completed
  /// (PRD FR-TK-18).
  bool isOverdueAt(DateTime now) =>
      status != TaskStatus.completed && dueAt.isBefore(now);

  bool get isOverdue => isOverdueAt(DateTime.now());

  Task copyWith({
    String? code,
    String? title,
    String? description,
    String? assigneeCode,
    String? assigneeName,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? startDate,
    String? startTime,
    DateTime? dueDate,
    String? dueTime,
    double? effort,
    bool? recurring,
    TaskRecurrence? Function()? recurringPattern,
    DateTime? Function()? recurringEndDate,
    String? Function()? startDay,
    String? Function()? dueDay,
    String? Function()? attachmentName,
    String? Function()? attachmentUrl,
    String? Function()? attachmentType,
    String? createdBy,
    String? createdByName,
    String? schoolCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeCode: assigneeCode ?? this.assigneeCode,
      assigneeName: assigneeName ?? this.assigneeName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      effort: effort ?? this.effort,
      recurring: recurring ?? this.recurring,
      recurringPattern: recurringPattern != null
          ? recurringPattern()
          : this.recurringPattern,
      recurringEndDate: recurringEndDate != null
          ? recurringEndDate()
          : this.recurringEndDate,
      startDay: startDay != null ? startDay() : this.startDay,
      dueDay: dueDay != null ? dueDay() : this.dueDay,
      attachmentName:
          attachmentName != null ? attachmentName() : this.attachmentName,
      attachmentUrl:
          attachmentUrl != null ? attachmentUrl() : this.attachmentUrl,
      attachmentType:
          attachmentType != null ? attachmentType() : this.attachmentType,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      schoolCode: schoolCode ?? this.schoolCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        code,
        title,
        description,
        assigneeCode,
        assigneeName,
        status,
        priority,
        startDate,
        startTime,
        dueDate,
        dueTime,
        effort,
        recurring,
        recurringPattern,
        recurringEndDate,
        startDay,
        dueDay,
        attachmentName,
        attachmentUrl,
        attachmentType,
        createdBy,
        createdByName,
        schoolCode,
        createdAt,
        updatedAt,
      ];
}
