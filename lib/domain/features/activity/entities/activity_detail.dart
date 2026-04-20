import 'package:equatable/equatable.dart';

/// One activity from `GET /api/v1/activities/code/{code}` (`data` object).
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
      studentCode: (json['studentCode'] as String?)?.trim().isEmpty == true
          ? null
          : json['studentCode']?.toString(),
      classroomCode: (json['classroomCode'] as String?)?.trim().isEmpty == true
          ? null
          : json['classroomCode']?.toString(),
      schoolCode: json['schoolCode']?.toString(),
      organizationCode: json['organizationCode']?.toString(),
      studentFirstName: (json['studentFirstName'] ?? '').toString(),
      studentMiddleName: json['studentMiddleName']?.toString(),
      studentLastName: (json['studentLastName'] ?? '').toString(),
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
      ];
}
