import 'package:isar/isar.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';

part 'task_collection.g.dart';

@collection
class TaskCollection {
  Id get isarId => fastHash(code);

  @Index(unique: true, replace: true)
  late String code;
  late String title;
  late String description;
  late String assigneeCode;
  late String assigneeName;

  @Index()
  late String status;
  late String priority;
  late DateTime startDate;
  late String startTime;

  @Index()
  late DateTime dueDate;
  late String dueTime;
  late double effort;
  late bool recurring;
  String? recurringPattern;
  DateTime? recurringEndDate;
  String? startDay;
  String? dueDay;
  String? attachmentName;
  String? attachmentUrl;
  String? attachmentType;
  late String createdBy;
  late String createdByName;
  late String schoolCode;
  late DateTime createdAt;
  late DateTime updatedAt;

  TaskCollection();

  factory TaskCollection.fromEntity(Task task) {
    return TaskCollection()
      ..code = task.code
      ..title = task.title
      ..description = task.description
      ..assigneeCode = task.assigneeCode
      ..assigneeName = task.assigneeName
      ..status = task.status.value
      ..priority = task.priority.value
      ..startDate = task.startDate
      ..startTime = task.startTime
      ..dueDate = task.dueDate
      ..dueTime = task.dueTime
      ..effort = task.effort
      ..recurring = task.recurring
      ..recurringPattern = task.recurringPattern?.value
      ..recurringEndDate = task.recurringEndDate
      ..startDay = task.startDay
      ..dueDay = task.dueDay
      ..attachmentName = task.attachmentName
      ..attachmentUrl = task.attachmentUrl
      ..attachmentType = task.attachmentType
      ..createdBy = task.createdBy
      ..createdByName = task.createdByName
      ..schoolCode = task.schoolCode
      ..createdAt = task.createdAt
      ..updatedAt = task.updatedAt;
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
}
