import 'dart:convert';
import 'package:equatable/equatable.dart';
import '../../../../core/util/typedefs.dart';
import '../../../../domain/features/Student-Module/entities/Student-Entity.dart';

class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.lastModified,
    required super.lastModifiedBy,
    required super.schoolId,
    required super.id,
    required super.date,
    required super.description,
    required super.activityNote,
    required super.hasStaffOnly,
    required super.isDiaperCreamApplied,
    required super.time,
    required super.hasParentNotify,
    required super.activityRefValue1,
    required super.activityRefValue2,
    required super.activityRefValue3,
    required super.activityTypeId,
    required super.staffId,
    required super.status,
    required super.activityStatus,
    required super.photoUuid,
    required super.roomId,
    required super.students,
    required super.absent,
    required super.attendance,
  });

  ActivityModel copyWith({
    String? lastModified,
    String? lastModifiedBy,
    int? schoolId,
    int? id,
    String? date,
    String? description,
    String? activityNote,
    bool? hasStaffOnly,
    bool? isDiaperCreamApplied,
    String? time,
    bool? hasParentNotify,
    String? activityRefValue1,
    String? activityRefValue2,
    String? activityRefValue3,
    int? activityTypeId,
    int? staffId,
    String? status,
    String? activityStatus,
    String? photoUuid,
    int? roomId,
    List<int>? students,
    bool? absent,
    int? attendance,
  }) {
    return ActivityModel(
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      schoolId: schoolId ?? this.schoolId,
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      activityNote: activityNote ?? this.activityNote,
      hasStaffOnly: hasStaffOnly ?? this.hasStaffOnly,
      isDiaperCreamApplied: isDiaperCreamApplied ?? this.isDiaperCreamApplied,
      time: time ?? this.time,
      hasParentNotify: hasParentNotify ?? this.hasParentNotify,
      activityRefValue1: activityRefValue1 ?? this.activityRefValue1,
      activityRefValue2: activityRefValue2 ?? this.activityRefValue2,
      activityRefValue3: activityRefValue3 ?? this.activityRefValue3,
      activityTypeId: activityTypeId ?? this.activityTypeId,
      staffId: staffId ?? this.staffId,
      status: status ?? this.status,
      activityStatus: activityStatus ?? this.activityStatus,
      photoUuid: photoUuid ?? this.photoUuid,
      roomId: roomId ?? this.roomId,
      students: students ?? this.students,
      absent: absent ?? this.absent,
      attendance: attendance ?? this.attendance,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'lastModified': lastModified,
      'lastModifiedBy': lastModifiedBy,
      'schoolId': schoolId,
      'id': id,
      'date': date,
      'description': description,
      'activityNote': activityNote,
      'hasStaffOnly': hasStaffOnly,
      'isDiaperCreamApplied': isDiaperCreamApplied,
      'time': time,
      'hasParentNotify': hasParentNotify,
      'activityRefValue1': activityRefValue1,
      'activityRefValue2': activityRefValue2,
      'activityRefValue3': activityRefValue3,
      'activityTypeId': activityTypeId,
      'staffId': staffId,
      'status': status,
      'activityStatus': activityStatus,
      'photoUuid': photoUuid,
      'roomId': roomId,
      'students': students,
      'absent': absent,
      'attendance': attendance,
    };
  }

  factory ActivityModel.fromMap(DataMap map) {
    return ActivityModel(
      lastModified: map['lastModified'] as String? ?? '',
      lastModifiedBy: map['lastModifiedBy'] as String? ?? '',
      schoolId: map['schoolId'] as int? ?? 0,
      id: map['id'] as int? ?? 0,
      date: map['date'] as String? ?? '',
      description: map['description'] as String? ?? '',
      activityNote: map['activityNote'] as String? ?? '',
      hasStaffOnly: map['hasStaffOnly'] as bool? ?? false,
      isDiaperCreamApplied: map['isDiaperCreamApplied'] as bool? ?? false,
      time: map['time'] as String? ?? '',
      hasParentNotify: map['hasParentNotify'] as bool? ?? false,
      activityRefValue1: map['activityRefValue1'] as String? ?? '',
      activityRefValue2: map['activityRefValue2'] as String? ?? '',
      activityRefValue3: map['activityRefValue3'] as String? ?? '',
      activityTypeId: map['activityTypeId'] as int? ?? 0,
      staffId: map['staffId'] as int? ?? 0,
      status: map['status'] as String? ?? '',
      activityStatus: map['activityStatus'] as String? ?? '',
      photoUuid: map['photoUuid'] as String?,
      roomId: map['roomId'] as int? ?? 0,
      students: (map['students'] as List<dynamic>?)?.cast<int>() ?? [],
      absent: map['absent'] as bool? ?? false,
      attendance: map['attendance'] as int? ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ActivityModel.fromJson(String source) =>
      ActivityModel.fromMap(json.decode(source) as DataMap);

  @override
  bool get stringify => true;

  static const empty = ActivityModel(
    lastModified: '',
    lastModifiedBy: '',
    schoolId: 0,
    id: 0,
    date: '',
    description: '',
    activityNote: '',
    hasStaffOnly: false,
    isDiaperCreamApplied: false,
    time: '',
    hasParentNotify: false,
    activityRefValue1: '',
    activityRefValue2: '',
    activityRefValue3: '',
    activityTypeId: 0,
    staffId: 0,
    status: '',
    activityStatus: '',
    photoUuid: null,
    roomId: 0,
    students: [],
    absent: false,
    attendance: 0,
  );

  static const demo = ActivityModel(
    lastModified: '2025-09-18',
    lastModifiedBy: 'Teacher Jane',
    schoolId: 1,
    id: 1,
    date: '2025-09-18',
    description: 'Art Class',
    activityNote: 'Created a watercolor painting',
    hasStaffOnly: false,
    isDiaperCreamApplied: false,
    time: '10:00 AM',
    hasParentNotify: true,
    activityRefValue1: 'Painting',
    activityRefValue2: 'Watercolor',
    activityRefValue3: 'Beginner',
    activityTypeId: 1,
    staffId: 101,
    status: 'Completed',
    activityStatus: 'Active',
    photoUuid: 'photo-uuid-act1',
    roomId: 101,
    students: [1, 2],
    absent: false,
    attendance: 10,
  );

  static const demoList = [demo];
}
