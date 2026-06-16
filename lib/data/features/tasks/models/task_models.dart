import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';

/// JSON-serializable task DTO. The shape mirrors what the future tasks API
/// is expected to return (ISO-8601 dates, uppercase enum codes), so the mock
/// seed file and a remote datasource can share this model untouched.
class TaskModel extends Equatable {
  const TaskModel({
    required this.code,
    required this.title,
    this.description = '',
    this.assigneeCode = '',
    this.assigneeName = '',
    this.status = 'TO_DO',
    this.priority = 'MEDIUM',
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

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      code: (json['code'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      assigneeCode: (json['assigneeCode'] ?? '').toString().trim(),
      assigneeName: (json['assigneeName'] ?? '').toString(),
      status: (json['status'] ?? 'TO_DO').toString(),
      priority: (json['priority'] ?? 'MEDIUM').toString(),
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      startTime: (json['startTime'] ?? '09:00').toString(),
      dueDate: _parseDate(json['dueDate']) ?? DateTime.now(),
      dueTime: (json['dueTime'] ?? '17:00').toString(),
      effort: _parseDouble(json['effort']),
      recurring: json['recurring'] == true,
      recurringPattern: json['recurringPattern']?.toString(),
      recurringEndDate: _parseDate(json['recurringEndDate']),
      startDay: json['startDay']?.toString(),
      dueDay: json['dueDay']?.toString(),
      attachmentName: json['attachmentName']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      attachmentType: json['attachmentType']?.toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? '').toString(),
      schoolCode: (json['schoolCode'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      code: task.code,
      title: task.title,
      description: task.description,
      assigneeCode: task.assigneeCode,
      assigneeName: task.assigneeName,
      status: task.status.value,
      priority: task.priority.value,
      startDate: task.startDate,
      startTime: task.startTime,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      effort: task.effort,
      recurring: task.recurring,
      recurringPattern: task.recurringPattern?.value,
      recurringEndDate: task.recurringEndDate,
      startDay: task.startDay,
      dueDay: task.dueDay,
      attachmentName: task.attachmentName,
      attachmentUrl: task.attachmentUrl,
      attachmentType: task.attachmentType,
      createdBy: task.createdBy,
      createdByName: task.createdByName,
      schoolCode: task.schoolCode,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }

  final String code;
  final String title;
  final String description;
  final String assigneeCode;
  final String assigneeName;
  final String status;
  final String priority;
  final DateTime startDate;
  final String startTime;
  final DateTime dueDate;
  final String dueTime;
  final double effort;
  final bool recurring;
  final String? recurringPattern;
  final DateTime? recurringEndDate;
  final String? startDay;
  final String? dueDay;
  final String? attachmentName;
  final String? attachmentUrl;
  final String? attachmentType;
  final String createdBy;
  final String createdByName;
  final String schoolCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'title': title,
      'description': description,
      'assigneeCode': assigneeCode,
      'assigneeName': assigneeName,
      'status': status,
      'priority': priority,
      'startDate': startDate.toIso8601String(),
      'startTime': startTime,
      'dueDate': dueDate.toIso8601String(),
      'dueTime': dueTime,
      'effort': effort,
      'recurring': recurring,
      'recurringPattern': recurringPattern,
      'recurringEndDate': recurringEndDate?.toIso8601String(),
      'startDay': startDay,
      'dueDay': dueDay,
      'attachmentName': attachmentName,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'schoolCode': schoolCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Task toEntity() {
    return Task(
      code: code,
      title: title,
      description: description,
      assigneeCode: assigneeCode,
      assigneeName: assigneeName,
      status: TaskStatus.fromValue(status),
      priority: TaskPriority.fromValue(priority),
      startDate: startDate,
      startTime: startTime,
      dueDate: dueDate,
      dueTime: dueTime,
      effort: effort,
      recurring: recurring,
      recurringPattern: TaskRecurrence.fromValue(recurringPattern),
      recurringEndDate: recurringEndDate,
      startDay: startDay,
      dueDay: dueDay,
      attachmentName: attachmentName,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      createdBy: createdBy,
      createdByName: createdByName,
      schoolCode: schoolCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static double _parseDouble(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }

  @override
  List<Object?> get props => [code, title, status, priority, dueDate, updatedAt];
}
