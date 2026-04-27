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

  factory ActivityDetail.fromApiData(Map<String, dynamic> json) {
    final params = <Map<String, dynamic>>[];
    final rawPv = json['parameterValues'];
    if (rawPv is List<dynamic>) {
      for (final p in rawPv) {
        if (p is Map<String, dynamic>) params.add(p);
      }
    }
    final atts = <Map<String, dynamic>>[];
    final rawAtt = json['attachments'];
    if (rawAtt is List<dynamic>) {
      for (final a in rawAtt) {
        if (a is Map<String, dynamic>) atts.add(a);
      }
    }
    final singleAttachment = json['attachment'];
    if (singleAttachment is Map<String, dynamic>) {
      atts.add(singleAttachment);
    }

    String? studentCode;
    String studentFirstName = '';
    String? studentMiddleName;
    String studentLastName = '';
    final rawStudents = json['students'];
    if (rawStudents is List && rawStudents.isNotEmpty) {
      final first = rawStudents.first;
      if (first is Map<String, dynamic>) {
        studentCode = (first['studentCode'] as String?)?.trim().isEmpty == true
            ? null
            : first['studentCode']?.toString();
        studentFirstName = (first['firstName'] ?? '').toString();
        studentMiddleName = first['middleName']?.toString();
        studentLastName = (first['lastName'] ?? '').toString();
      }
    }

    final rawApprovalStatus = (json['approvalStatus'] ?? json['status'])
        ?.toString()
        .trim();

    return ActivityDetail(
      code: (json['code'] ?? '').toString(),
      activityTypeCode: (json['activityTypeCode'] ?? '').toString(),
      activityTypeName: (json['activityTypeName'] ?? '').toString(),
      activityDateIso: (json['activityDate'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      parameterValues: params,
      attachments: atts,
      createdBy: (json['createdBy'] ?? '').toString(),
      staffCode: (json['staffCode'] ?? '').toString(),
      studentCode: studentCode ??
          ((json['studentCode'] as String?)?.trim().isEmpty == true
              ? null
              : json['studentCode']?.toString()),
      classroomCode: (json['classroomCode'] as String?)?.trim().isEmpty == true
          ? null
          : json['classroomCode']?.toString(),
      schoolCode: json['schoolCode']?.toString(),
      organizationCode: json['organizationCode']?.toString(),
      studentFirstName: studentFirstName.isNotEmpty
          ? studentFirstName
          : (json['studentFirstName'] ?? '').toString(),
      studentMiddleName: studentMiddleName ?? json['studentMiddleName']?.toString(),
      studentLastName: studentLastName.isNotEmpty
          ? studentLastName
          : (json['studentLastName'] ?? '').toString(),
      approvalStatus: (rawApprovalStatus == null || rawApprovalStatus.isEmpty)
          ? null
          : rawApprovalStatus.toUpperCase(),
    );
  }

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
