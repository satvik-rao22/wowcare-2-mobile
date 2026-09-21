import 'package:equatable/equatable.dart';

import 'student_attendance_record_code.dart';

class StudentAttendanceDailyItemModel extends Equatable {
  const StudentAttendanceDailyItemModel({
    this.attendanceRecordCode,
    this.attendanceDate,
    this.studentCode,
    required this.studentName,
    required this.isExpectedToday,
    required this.classroomName,
    this.signedInAt,
    this.signedInTime,
    this.signedInBy,
    this.signedOutAt,
    this.signedOutTime,
    this.signedOutBy,
    this.signedInMethod,
    this.signedOutMethod,
    required this.classroomCode,
    required this.tagCodes,
    required this.tagNames,
    this.duration,
    // Transfer-related fields
    this.isTransfer,
    this.sequenceNumber,
    this.totalSequenceCount,
    this.hasNextTransfer,
    this.isLastSequenceEntry,
    this.fromClassroomCode,
    this.fromClassroomName,
    this.toClassroomCode,
    this.toClassroomName,
    this.transferTime,
    this.nextActionTime,
    this.transferredBy,
    this.transferReason,
    this.notExpectedComment,
  });

  final String studentName;
  final bool isExpectedToday;
  final String classroomName;
  final String? attendanceRecordCode;
  final String? attendanceDate;
  final String? studentCode;
  final String? signedInAt;
  final StudentAttendanceTimeModel? signedInTime;
  final String? signedInBy;
  final String? signedOutAt;
  final StudentAttendanceTimeModel? signedOutTime;
  final String? signedOutBy;
  final String? signedInMethod;
  final String? signedOutMethod;
  final String classroomCode;
  final List<String> tagCodes;
  final List<String> tagNames;
  final String? duration;
  // Transfer-related fields
  final bool? isTransfer;
  final int? sequenceNumber;
  final int? totalSequenceCount;
  final bool? hasNextTransfer;
  final bool? isLastSequenceEntry;
  final String? fromClassroomCode;
  final String? fromClassroomName;
  final String? toClassroomCode;
  final String? toClassroomName;
  final StudentAttendanceTimeModel? transferTime;
  final StudentAttendanceTimeModel? nextActionTime;
  final String? transferredBy;
  final String? transferReason;
  final String? notExpectedComment;

  factory StudentAttendanceDailyItemModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceDailyItemModel(
      attendanceRecordCode: resolveStudentAttendanceRecordCodeForMutations(
        json,
      ),
      attendanceDate: json['attendanceDate'] as String?,
      studentCode: json['studentCode'] as String?,
      studentName: json['studentName'] as String? ?? '',
      isExpectedToday: json['isExpectedToday'] as bool? ?? false,
      classroomName: json['classroomName'] as String? ?? '',
      signedInAt: json['signedInAt'] as String?,
      signedInTime: json['signedInTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['signedInTime'])
          : null,
      signedInBy: (json['signedInBy'] ?? json['signedInByName']) as String?,
      signedOutAt: json['signedOutAt'] as String?,
      signedOutTime: json['signedOutTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['signedOutTime'])
          : null,
      signedOutBy: (json['signedOutBy'] ?? json['signedOutByName']) as String?,
      // Backend exposes how the student was signed in/out (GPS, PIN, QR, APP, etc.)
      signedInMethod: json['signedInMethod'] as String?,
      signedOutMethod: json['signedOutMethod'] as String?,
      classroomCode: json['classroomCode'] as String? ?? '',
      tagCodes:
          (json['tagCodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tagNames:
          (json['tagNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      duration: json['duration'] as String?,
      // Transfer-related fields
      isTransfer: json['isTransfer'] as bool?,
      sequenceNumber: json['sequenceNumber'] as int?,
      totalSequenceCount: json['totalSequenceCount'] as int?,
      hasNextTransfer: json['hasNextTransfer'] as bool?,
      isLastSequenceEntry: json['isLastSequenceEntry'] as bool?,
      fromClassroomCode: json['fromClassroomCode'] as String?,
      fromClassroomName: json['fromClassroomName'] as String?,
      toClassroomCode: json['toClassroomCode'] as String?,
      toClassroomName: json['toClassroomName'] as String?,
      transferTime: json['transferTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['transferTime'])
          : null,
      nextActionTime: json['nextActionTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['nextActionTime'])
          : null,
      transferredBy: json['transferredBy'] as String?,
      transferReason: json['transferReason'] as String?,
      notExpectedComment: json['notExpectedComment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendanceRecordCode': attendanceRecordCode,
      'attendanceDate': attendanceDate,
      'studentCode': studentCode,
      'studentName': studentName,
      'isExpectedToday': isExpectedToday,
      'classroomName': classroomName,
      'signedInAt': signedInAt,
      'signedInTime': signedInTime?.toJson(),
      'signedInBy': signedInBy,
      'signedOutAt': signedOutAt,
      'signedOutTime': signedOutTime?.toJson(),
      'signedOutBy': signedOutBy,
      'signedInMethod': signedInMethod,
      'signedOutMethod': signedOutMethod,
      'classroomCode': classroomCode,
      'tagCodes': tagCodes,
      'tagNames': tagNames,
      'duration': duration,
      // Transfer-related fields
      'isTransfer': isTransfer,
      'sequenceNumber': sequenceNumber,
      'totalSequenceCount': totalSequenceCount,
      'hasNextTransfer': hasNextTransfer,
      'isLastSequenceEntry': isLastSequenceEntry,
      'fromClassroomCode': fromClassroomCode,
      'fromClassroomName': fromClassroomName,
      'toClassroomCode': toClassroomCode,
      'toClassroomName': toClassroomName,
      'transferTime': transferTime?.toJson(),
      'nextActionTime': nextActionTime?.toJson(),
      'transferredBy': transferredBy,
      'transferReason': transferReason,
      'notExpectedComment': notExpectedComment,
    };
  }

  @override
  List<Object?> get props => [
    attendanceRecordCode,
    attendanceDate,
    studentCode,
    studentName,
    isExpectedToday,
    classroomName,
    signedInAt,
    signedInTime,
    signedInBy,
    signedOutAt,
    signedOutTime,
    signedOutBy,
    signedInMethod,
    signedOutMethod,
    classroomCode,
    tagCodes,
    tagNames,
    duration,
    // Transfer-related fields
    isTransfer,
    sequenceNumber,
    totalSequenceCount,
    hasNextTransfer,
    isLastSequenceEntry,
    fromClassroomCode,
    fromClassroomName,
    toClassroomCode,
    toClassroomName,
    transferTime,
    nextActionTime,
    transferredBy,
    transferReason,
    notExpectedComment,
  ];
}

class StudentAttendanceTimeModel extends Equatable {
  const StudentAttendanceTimeModel({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.nano = 0,
  });

  final int hour;
  final int minute;
  final int second;
  final int nano;

  factory StudentAttendanceTimeModel.fromJson(dynamic json) {
    // Backend may return time either as an object {hour,minute,second,nano}
    // or as a string \"HH:mm:ss\" / \"HH:mm:ss.SSS\". Support both.
    if (json is Map<String, dynamic>) {
      return StudentAttendanceTimeModel(
        hour: json['hour'] as int? ?? 0,
        minute: json['minute'] as int? ?? 0,
        second: json['second'] as int? ?? 0,
        nano: json['nano'] as int? ?? 0,
      );
    }

    if (json is String) {
      try {
        final parts = json.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          int second = 0;
          int nano = 0;

          if (parts.length >= 3) {
            final secPart = parts[2];
            if (secPart.contains('.')) {
              final secSplit = secPart.split('.');
              second = int.tryParse(secSplit.first) ?? 0;
              nano =
                  int.tryParse(
                    secSplit.last.padRight(9, '0').substring(0, 9),
                  ) ??
                  0;
            } else {
              second = int.tryParse(secPart) ?? 0;
            }
          }

          return StudentAttendanceTimeModel(
            hour: hour,
            minute: minute,
            second: second,
            nano: nano,
          );
        }
      } catch (_) {
        // fall-through to default
      }
    }

    return const StudentAttendanceTimeModel(hour: 0, minute: 0);
  }

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'minute': minute, 'second': second, 'nano': nano};
  }

  /// Formats time as "HH:mm AM/PM"
  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  List<Object?> get props => [hour, minute, second, nano];
}

class StudentAttendanceDailyPageModel extends Equatable {
  const StudentAttendanceDailyPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentAttendanceDailyItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props => [
    items,
    page,
    size,
    totalPages,
    totalElements,
    hasMore,
  ];

  factory StudentAttendanceDailyPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map(
          (e) => StudentAttendanceDailyItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    final hasMore = pageNumber + 1 < totalPages;

    return StudentAttendanceDailyPageModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': items.map((e) => e.toJson()).toList(),
      'number': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'last': !hasMore,
    };
  }

  factory StudentAttendanceDailyPageModel.fromCacheJson(
    Map<String, dynamic> json,
  ) {
    final itemsJson = json['content'] as List<dynamic>? ?? const [];
    return StudentAttendanceDailyPageModel(
      items: itemsJson
          .map(
            (e) => StudentAttendanceDailyItemModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      page: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class StudentAttendanceCustomItemModel extends Equatable {
  const StudentAttendanceCustomItemModel({
    required this.studentCode,
    required this.studentName,
    required this.isExpectedToday,
    required this.classroomName,
    required this.classroomCode,
    required this.attendedDays,
    required this.attendedTime,
    required this.attendedHours,
    required this.attendedMinutes,
    this.signedInBy,
    this.signedInTime,
    this.signedOutBy,
    this.signedOutTime,
    required this.tagCodes,
    required this.tagNames,
  });

  final String studentCode;
  final String studentName;
  final bool isExpectedToday;
  final String classroomName;
  final String classroomCode;
  final int attendedDays;
  final String attendedTime;
  final int attendedHours;
  final int attendedMinutes;
  final String? signedInBy;
  final String? signedInTime;
  final String? signedOutBy;
  final String? signedOutTime;
  final List<String> tagCodes;
  final List<String> tagNames;

  factory StudentAttendanceCustomItemModel.fromJson(Map<String, dynamic> json) {
    String? _parseTime(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        final hour = value['hour'] as int? ?? 0;
        final minute = value['minute'] as int? ?? 0;
        final second = value['second'] as int? ?? 0;
        final h = hour.toString().padLeft(2, '0');
        final m = minute.toString().padLeft(2, '0');
        final s = second.toString().padLeft(2, '0');
        return '$h:$m:$s';
      }
      return value.toString();
    }

    return StudentAttendanceCustomItemModel(
      studentCode: json['studentCode'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      isExpectedToday: json['isExpectedToday'] as bool? ?? false,
      classroomName: json['classroomName'] as String? ?? '',
      classroomCode: json['classroomCode'] as String? ?? '',
      attendedDays: json['attendedDays'] as int? ?? 0,
      signedInBy: (json['signedInBy'] ?? json['signedInByName']) as String?,
      signedInTime: _parseTime(json['signedInTime']),
      signedOutBy: (json['signedOutBy'] ?? json['signedOutByName']) as String?,
      signedOutTime: _parseTime(json['signedOutTime']),
      tagCodes:
          (json['tagCodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tagNames:
          (json['tagNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      attendedTime: json['attendedTime'] as String? ?? '',
      attendedHours: json['attendedHours'] as int? ?? 0,
      attendedMinutes: json['attendedMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentCode': studentCode,
      'studentName': studentName,
      'isExpectedToday': isExpectedToday,
      'classroomName': classroomName,
      'classroomCode': classroomCode,
      'attendedDays': attendedDays,
      'signedInBy': signedInBy,
      'signedInTime': signedInTime,
      'signedOutBy': signedOutBy,
      'signedOutTime': signedOutTime,
      'tagCodes': tagCodes,
      'tagNames': tagNames,
      'attendedTime': attendedTime,
      'attendedHours': attendedHours,
      'attendedMinutes': attendedMinutes,
    };
  }

  @override
  List<Object?> get props => [
    studentCode,
    studentName,
    isExpectedToday,
    classroomName,
    classroomCode,
    attendedDays,
    attendedTime,
    attendedHours,
    attendedMinutes,
    signedInBy,
    signedInTime,
    signedOutBy,
    signedOutTime,
    tagCodes,
    tagNames,
  ];
}

class StudentAttendanceCustomPageModel extends Equatable {
  const StudentAttendanceCustomPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentAttendanceCustomItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props => [
    items,
    page,
    size,
    totalPages,
    totalElements,
    hasMore,
  ];

  factory StudentAttendanceCustomPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map(
          (e) => StudentAttendanceCustomItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    final hasMore = pageNumber + 1 < totalPages;

    return StudentAttendanceCustomPageModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': items.map((e) => e.toJson()).toList(),
      'number': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'last': !hasMore,
    };
  }

  factory StudentAttendanceCustomPageModel.fromCacheJson(
    Map<String, dynamic> json,
  ) {
    final itemsJson = json['content'] as List<dynamic>? ?? const [];
    return StudentAttendanceCustomPageModel(
      items: itemsJson
          .map(
            (e) => StudentAttendanceCustomItemModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      page: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// One classroom stint within a day for the mark-activity student list
/// (`GET .../student-attendance/view/mark-activity/student-list`).
/// `toTime == null` means the student is still in this classroom.
class StaffAttendanceDailyItemModel extends Equatable {
  const StaffAttendanceDailyItemModel({
    this.attendanceRecordCode,
    required this.staffCode,
    required this.staffName,
    required this.isExpectedToday,
    required this.classroomName,
    required this.classroomCode,
    required this.attendedDays,
    this.signedInBy,
    this.signedInTime,
    this.signedOutBy,
    this.signedOutTime,
    this.signedInMethod,
    this.signedOutMethod,
    required this.designation,
    this.attendedTime,
    this.attendedHours,
    this.attendedMinutes,
    this.isTransfer,
    this.sequenceNumber,
    this.totalSequenceCount,
    this.hasNextTransfer,
    this.isLastSequenceEntry,
    this.fromClassroomCode,
    this.fromClassroomName,
    this.toClassroomCode,
    this.toClassroomName,
    this.transferTime,
    this.nextActionTime,
    this.transferredBy,
    this.transferReason,
    this.notExpectedComment,
  });

  final String? attendanceRecordCode;
  final String staffCode;
  final String staffName;
  final bool isExpectedToday;
  final String classroomName;
  final String classroomCode;
  final int attendedDays;
  final String? signedInBy;
  final StudentAttendanceTimeModel? signedInTime;
  final String? signedOutBy;
  final StudentAttendanceTimeModel? signedOutTime;
  final List<String> designation;
  final String? attendedTime;
  final int? attendedHours;
  final int? attendedMinutes;

  /// Sign-in method code as returned by the API (e.g. GPS, PIN, QR, APP).
  final String? signedInMethod;

  /// Sign-out method code as returned by the API (e.g. GPS, PIN, QR, APP).
  final String? signedOutMethod;
  final bool? isTransfer;
  final int? sequenceNumber;
  final int? totalSequenceCount;
  final bool? hasNextTransfer;
  final bool? isLastSequenceEntry;
  final String? fromClassroomCode;
  final String? fromClassroomName;
  final String? toClassroomCode;
  final String? toClassroomName;
  final StudentAttendanceTimeModel? transferTime;
  final StudentAttendanceTimeModel? nextActionTime;
  final String? transferredBy;
  final String? transferReason;
  final String? notExpectedComment;

  factory StaffAttendanceDailyItemModel.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceDailyItemModel(
      attendanceRecordCode: resolveStaffAttendanceRecordCodeForMutations(json),
      staffCode: json['staffCode'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      isExpectedToday: json['isExpectedToday'] as bool? ?? false,
      classroomName: json['classroomName'] as String? ?? '',
      classroomCode: json['classroomCode'] as String? ?? '',
      attendedDays: json['attendedDays'] as int? ?? 0,
      signedInBy: (json['signedInBy'] ?? json['signedInByName']) as String?,
      signedInTime: json['signedInTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['signedInTime'])
          : null,
      signedOutBy: (json['signedOutBy'] ?? json['signedOutByName']) as String?,
      signedOutTime: json['signedOutTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['signedOutTime'])
          : null,
      signedInMethod: json['signedInMethod'] as String?,
      signedOutMethod: json['signedOutMethod'] as String?,
      designation:
          (json['designation'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      attendedTime: json['attendedTime'] as String?,
      attendedHours: json['attendedHours'] as int?,
      attendedMinutes: json['attendedMinutes'] as int?,
      isTransfer: json['isTransfer'] as bool?,
      sequenceNumber: json['sequenceNumber'] as int?,
      totalSequenceCount: json['totalSequenceCount'] as int?,
      hasNextTransfer: json['hasNextTransfer'] as bool?,
      isLastSequenceEntry: json['isLastSequenceEntry'] as bool?,
      fromClassroomCode: json['fromClassroomCode'] as String?,
      fromClassroomName: json['fromClassroomName'] as String?,
      toClassroomCode: json['toClassroomCode'] as String?,
      toClassroomName: json['toClassroomName'] as String?,
      transferTime: json['transferTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['transferTime'])
          : null,
      nextActionTime: json['nextActionTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['nextActionTime'])
          : null,
      transferredBy: json['transferredBy'] as String?,
      transferReason: json['transferReason'] as String?,
      notExpectedComment: json['notExpectedComment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendanceRecordCode': attendanceRecordCode,
      'staffCode': staffCode,
      'staffName': staffName,
      'isExpectedToday': isExpectedToday,
      'classroomName': classroomName,
      'classroomCode': classroomCode,
      'attendedDays': attendedDays,
      'signedInBy': signedInBy,
      'signedInTime': signedInTime?.toJson(),
      'signedOutBy': signedOutBy,
      'signedOutTime': signedOutTime?.toJson(),
      'signedInMethod': signedInMethod,
      'signedOutMethod': signedOutMethod,
      'designation': designation,
      'attendedTime': attendedTime,
      'attendedHours': attendedHours,
      'attendedMinutes': attendedMinutes,
      'isTransfer': isTransfer,
      'sequenceNumber': sequenceNumber,
      'totalSequenceCount': totalSequenceCount,
      'hasNextTransfer': hasNextTransfer,
      'isLastSequenceEntry': isLastSequenceEntry,
      'fromClassroomCode': fromClassroomCode,
      'fromClassroomName': fromClassroomName,
      'toClassroomCode': toClassroomCode,
      'toClassroomName': toClassroomName,
      'transferTime': transferTime?.toJson(),
      'nextActionTime': nextActionTime?.toJson(),
      'transferredBy': transferredBy,
      'transferReason': transferReason,
      'notExpectedComment': notExpectedComment,
    };
  }

  @override
  List<Object?> get props => [
    attendanceRecordCode,
    staffCode,
    staffName,
    isExpectedToday,
    classroomName,
    classroomCode,
    attendedDays,
    signedInBy,
    signedInTime,
    signedOutBy,
    signedOutTime,
    signedInMethod,
    signedOutMethod,
    designation,
    attendedTime,
    attendedHours,
    attendedMinutes,
    isTransfer,
    sequenceNumber,
    totalSequenceCount,
    hasNextTransfer,
    isLastSequenceEntry,
    fromClassroomCode,
    fromClassroomName,
    toClassroomCode,
    toClassroomName,
    transferTime,
    nextActionTime,
    transferredBy,
    transferReason,
    notExpectedComment,
  ];
}

class StaffAttendanceDailyPageModel extends Equatable {
  const StaffAttendanceDailyPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
    this.attendedDays = 0,
    this.totalAttendedHours = '',
  });

  final List<StaffAttendanceDailyItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;
  final int attendedDays;
  final String totalAttendedHours;

  @override
  List<Object?> get props => [
    items,
    page,
    size,
    totalPages,
    totalElements,
    hasMore,
    attendedDays,
    totalAttendedHours,
  ];

  factory StaffAttendanceDailyPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final aggJson = data['aggregations'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map(
          (e) =>
              StaffAttendanceDailyItemModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    final hasMore = pageNumber + 1 < totalPages;
    final attendedDays = (aggJson['attendedDays'] as int?) ?? 0;
    final totalAttendedHours = (aggJson['totalAttendedTime'] as String?) ?? '';

    return StaffAttendanceDailyPageModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
      attendedDays: attendedDays,
      totalAttendedHours: totalAttendedHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': items.map((e) => e.toJson()).toList(),
      'number': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'last': !hasMore,
    };
  }

  factory StaffAttendanceDailyPageModel.fromCacheJson(
    Map<String, dynamic> json,
  ) {
    final itemsJson = json['content'] as List<dynamic>? ?? const [];
    return StaffAttendanceDailyPageModel(
      items: itemsJson
          .map(
            (e) => StaffAttendanceDailyItemModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      page: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class StaffAttendanceAbsentItemModel extends Equatable {
  const StaffAttendanceAbsentItemModel({
    required this.staffCode,
    required this.staffName,
    required this.classroomCode,
    required this.classroomName,
    required this.absenceDate,
    this.markedAbsentTime,
    required this.markedAbsentByName,
    this.absenceNote,
    this.markAbsentMethod,
    required this.absentDays,
    this.absenceRecordCode,
  });

  final String staffCode;
  final String staffName;
  final String classroomCode;
  final String classroomName;
  final String absenceDate;
  final StudentAttendanceTimeModel? markedAbsentTime;
  final String markedAbsentByName;
  final String? absenceNote;
  final String? markAbsentMethod;
  final int absentDays;

  /// Server identifier for DELETE `/api/v1/staff-absence-records/{code}`.
  final String? absenceRecordCode;

  static String? _parseAbsenceRecordCode(Map<String, dynamic> json) {
    for (final key in ['absenceRecordCode', 'recordCode', 'absenceCode']) {
      final v = json[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    final code = json['code']?.toString().trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }
    return null;
  }

  factory StaffAttendanceAbsentItemModel.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceAbsentItemModel(
      staffCode: json['staffCode'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      classroomCode: json['classroomCode'] as String? ?? '',
      classroomName: json['classroomName'] as String? ?? '',
      absenceDate: json['absenceDate'] as String? ?? '',
      markedAbsentTime: json['markedAbsentTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['markedAbsentTime'])
          : null,
      markedAbsentByName: json['markedAbsentByName'] as String? ?? '',
      absenceNote: json['absenceNote'] as String?,
      markAbsentMethod: json['markAbsentMethod'] as String?,
      absentDays: json['absentDays'] as int? ?? 0,
      absenceRecordCode: _parseAbsenceRecordCode(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'staffName': staffName,
      'classroomCode': classroomCode,
      'classroomName': classroomName,
      'absenceDate': absenceDate,
      'markedAbsentTime': markedAbsentTime?.toJson(),
      'markedAbsentByName': markedAbsentByName,
      'absenceNote': absenceNote,
      'markAbsentMethod': markAbsentMethod,
      'absentDays': absentDays,
      if (absenceRecordCode != null) 'absenceRecordCode': absenceRecordCode,
    };
  }

  @override
  List<Object?> get props => [
    staffCode,
    staffName,
    classroomCode,
    classroomName,
    absenceDate,
    markedAbsentTime,
    markedAbsentByName,
    absenceNote,
    markAbsentMethod,
    absentDays,
    absenceRecordCode,
  ];
}

class StaffAttendanceAbsentPageModel extends Equatable {
  const StaffAttendanceAbsentPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
    this.absentDays = 0,
  });

  final List<StaffAttendanceAbsentItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;
  final int absentDays;

  @override
  List<Object?> get props => [
    items,
    page,
    size,
    totalPages,
    totalElements,
    hasMore,
    absentDays,
  ];

  factory StaffAttendanceAbsentPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final aggJson = data['aggregations'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map(
          (e) => StaffAttendanceAbsentItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    final hasMore = pageNumber + 1 < totalPages;
    final absentDays = (aggJson['absentDays'] as int?) ?? 0;

    return StaffAttendanceAbsentPageModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
      absentDays: absentDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': items.map((e) => e.toJson()).toList(),
      'number': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'last': !hasMore,
    };
  }

  factory StaffAttendanceAbsentPageModel.fromCacheJson(
    Map<String, dynamic> json,
  ) {
    final itemsJson = json['content'] as List<dynamic>? ?? const [];
    return StaffAttendanceAbsentPageModel(
      items: itemsJson
          .map(
            (e) => StaffAttendanceAbsentItemModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      page: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// Student-level absent form list models (for student-absence form endpoint).
class StudentAttendanceAbsentFormItemModel extends Equatable {
  const StudentAttendanceAbsentFormItemModel({
    required this.studentCode,
    required this.studentName,
    required this.classroomCode,
    required this.classroomName,
    required this.absenceDate,
    this.markedAbsentTime,
    this.markedAbsentByName,
    this.absenceNote,
    this.markAbsentMethod,
    this.absentDays = 0,
    this.absenceRecordCode,
  });

  final String studentCode;
  final String studentName;
  final String classroomCode;
  final String classroomName;
  final String absenceDate;
  final StudentAttendanceTimeModel? markedAbsentTime;
  final String? markedAbsentByName;
  final String? absenceNote;
  final String? markAbsentMethod;
  final int absentDays;
  final String? absenceRecordCode;

  static String? _parseAbsenceRecordCode(Map<String, dynamic> json) {
    for (final key in ['absenceRecordCode', 'recordCode', 'absenceCode']) {
      final v = json[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    final code = json['code']?.toString().trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }
    return null;
  }

  factory StudentAttendanceAbsentFormItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentAttendanceAbsentFormItemModel(
      studentCode: json['studentCode'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      classroomCode: json['classroomCode'] as String? ?? '',
      classroomName: json['classroomName'] as String? ?? '',
      absenceDate: json['absenceDate'] as String? ?? '',
      markedAbsentTime: json['markedAbsentTime'] != null
          ? StudentAttendanceTimeModel.fromJson(json['markedAbsentTime'])
          : null,
      markedAbsentByName: json['markedAbsentByName'] as String?,
      absenceNote: json['absenceNote'] as String?,
      markAbsentMethod: json['markAbsentMethod'] as String?,
      absentDays: json['absentDays'] as int? ?? 0,
      absenceRecordCode: _parseAbsenceRecordCode(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentCode': studentCode,
      'studentName': studentName,
      'classroomCode': classroomCode,
      'classroomName': classroomName,
      'absenceDate': absenceDate,
      'markedAbsentTime': markedAbsentTime?.toJson(),
      'markedAbsentByName': markedAbsentByName,
      'absenceNote': absenceNote,
      'markAbsentMethod': markAbsentMethod,
      'absentDays': absentDays,
      if (absenceRecordCode != null) 'absenceRecordCode': absenceRecordCode,
    };
  }

  @override
  List<Object?> get props => [
    studentCode,
    studentName,
    classroomCode,
    classroomName,
    absenceDate,
    markedAbsentTime,
    markedAbsentByName,
    absenceNote,
    markAbsentMethod,
    absentDays,
    absenceRecordCode,
  ];
}

class StudentAttendanceAbsentFormPageModel extends Equatable {
  const StudentAttendanceAbsentFormPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentAttendanceAbsentFormItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props => [
    items,
    page,
    size,
    totalPages,
    totalElements,
    hasMore,
  ];

  factory StudentAttendanceAbsentFormPageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map(
          (e) => StudentAttendanceAbsentFormItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    final hasMore = pageNumber + 1 < totalPages;

    return StudentAttendanceAbsentFormPageModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': items.map((e) => e.toJson()).toList(),
      'number': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'last': !hasMore,
    };
  }
}

/// Expected attendance summary for the daily view "Expected Students" card.
class StudentAttendanceExpectedSummaryModel extends Equatable {
  const StudentAttendanceExpectedSummaryModel({
    required this.expected,
    required this.present,
    required this.absent,
    required this.signOut,
    required this.notMarked,
  });

  final int expected;
  final int present;
  final int absent;
  final int signOut;
  final int notMarked;

  /// Parses the wrapped API response:
  /// {
  ///   "success": true,
  ///   "message": "...",
  ///   "data": {
  ///     "expected": 10,
  ///     "present": 0,
  ///     "absent": 4,
  ///     "signout": 0,
  ///     "notMarked": 6
  ///   },
  ///   ...
  /// }
  factory StudentAttendanceExpectedSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return StudentAttendanceExpectedSummaryModel(
      expected: data['expected'] as int? ?? 0,
      present: data['present'] as int? ?? 0,
      absent: data['absent'] as int? ?? 0,
      signOut: data['signout'] as int? ?? 0,
      notMarked: data['notMarked'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [expected, present, absent, signOut, notMarked];
}

/// Staff expected attendance summary for the daily view "Expected Staff" card.
class StaffAttendanceExpectedSummaryModel extends Equatable {
  const StaffAttendanceExpectedSummaryModel({
    required this.expected,
    required this.present,
    required this.absent,
    required this.signOut,
    required this.notMarked,
  });

  final int expected;
  final int present;
  final int absent;
  final int signOut;
  final int notMarked;

  factory StaffAttendanceExpectedSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return StaffAttendanceExpectedSummaryModel(
      expected: data['expected'] as int? ?? 0,
      present: data['present'] as int? ?? 0,
      absent: data['absent'] as int? ?? 0,
      signOut: data['signout'] as int? ?? 0,
      notMarked: data['notMarked'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [expected, present, absent, signOut, notMarked];
}
