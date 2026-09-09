import 'package:equatable/equatable.dart';

/// One grouped activity card from `GET /api/v2/activities/{cardGroupCode}`.
class ActivityDetail extends Equatable {
  const ActivityDetail({
    required this.code,
    required this.activityTypeCode,
    required this.activityTypeName,
    required this.activityDateIso,
    required this.description,
    required this.parameterValues,
    required this.attachments,
    required this.createdBy,
    this.staffCode = '',
    this.studentCode,
    this.classroomCode,
    this.schoolCode,
    this.organizationCode,
    this.studentFirstName = '',
    this.studentMiddleName,
    this.studentLastName = '',
    this.approvalStatus,
  });

  final String code;
  final String activityTypeCode;
  final String activityTypeName;
  final String activityDateIso;
  final String description;
  final List<Map<String, dynamic>> parameterValues;
  final List<Map<String, dynamic>> attachments;
  final String createdBy;
  final String staffCode;
  final String? studentCode;
  final String? classroomCode;
  final String? schoolCode;
  final String? organizationCode;
  final String studentFirstName;
  final String? studentMiddleName;
  final String studentLastName;
  final String? approvalStatus;

  @override
  List<Object?> get props => [
        code,
        activityTypeCode,
        activityTypeName,
        activityDateIso,
        description,
        parameterValues,
        attachments,
        createdBy,
        staffCode,
        studentCode,
        classroomCode,
        approvalStatus,
      ];
}
