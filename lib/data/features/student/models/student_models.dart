import 'package:equatable/equatable.dart';

class StudentListItemModel extends Equatable {
  const StudentListItemModel({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.profilePhotoUrl,
    this.profilePhotoAssetCode,
    this.classroom = '',
    this.dob = '',
    this.movementDate = '',
    this.tags = const <String>[],
    this.schedule = const <String>[],
    this.scheduleByDay = const <String, String>{},
  });

  final String code;
  final String firstName;
  final String lastName;
  final String status;
  final String? profilePhotoUrl;
  final String? profilePhotoAssetCode;
  final String classroom;
  final String dob;
  final String movementDate;
  final List<String> tags;
  /// Convenience list of abbreviated weekdays derived from `regularSchedules`,
  /// e.g. ["Mon", "Tue"]. Used by UI schedule chips.
  final List<String> schedule;
  /// Day-of-week (MONDAY, TUESDAY, ...) -> "start - end".
  final Map<String, String> scheduleByDay;

  String get fullName => '$firstName $lastName'.trim();

  factory StudentListItemModel.fromJson(Map<String, dynamic> json) {
    final classroomRaw = json['classroom'];
    String classroomCodeOrName = '';
    if (classroomRaw is String) {
      classroomCodeOrName = classroomRaw;
    } else if (classroomRaw is Map) {
      final name = classroomRaw['name']?.toString().trim() ?? '';
      final code = classroomRaw['code'];
      classroomCodeOrName = name.isNotEmpty
          ? name
          : (code?.toString().trim() ?? '');
    }

    final rawTags = json['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is String) {
          final v = t.trim();
          if (v.isNotEmpty) tags.add(v);
        } else if (t is Map) {
          // Support shapes like { name: "Peanut Allergy", code: "TAG_..." }
          final name = (t['name'] ?? '').toString().trim();
          if (name.isNotEmpty) tags.add(name);
        }
      }
    }

    String _timeToLabel(dynamic t) {
      if (t == null) return '';
      if (t is String) {
        final raw = t.trim();
        if (raw.isEmpty) return '';
        final chunks = raw.split(':');
        if (chunks.length >= 2) {
          final h = int.tryParse(chunks[0]) ?? 0;
          final m = int.tryParse(chunks[1]) ?? 0;
          final dt = DateTime(2000, 1, 1, h, m);
          final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final minute = dt.minute.toString().padLeft(2, '0');
          final period = dt.hour >= 12 ? 'PM' : 'AM';
          return '$hour12:$minute $period';
        }
        return raw;
      }
      if (t is Map) {
        final h = int.tryParse('${t['hour'] ?? 0}') ?? 0;
        final m = int.tryParse('${t['minute'] ?? 0}') ?? 0;
        final dt = DateTime(2000, 1, 1, h, m);
        final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour12:$minute $period';
      }
      return '';
    }

    // Map regularSchedules -> ["Mon", "Tue", ...] and time range map.
    final scheduleDays = <String>[];
    final scheduleByDay = <String, String>{};
    final rawSchedules = json['regularSchedules'];
    if (rawSchedules is List) {
      for (final item in rawSchedules) {
        if (item is! Map) continue;
        final dow = (item['dayOfWeek'] ?? '').toString().toUpperCase().trim();
        String? label;
        switch (dow) {
          case 'MONDAY':
            label = 'Mon';
            break;
          case 'TUESDAY':
            label = 'Tue';
            break;
          case 'WEDNESDAY':
            label = 'Wed';
            break;
          case 'THURSDAY':
            label = 'Thu';
            break;
          case 'FRIDAY':
            label = 'Fri';
            break;
          case 'SATURDAY':
            label = 'Sat';
            break;
          case 'SUNDAY':
            label = 'Sun';
            break;
          default:
            label = null;
        }
        if (label != null && !scheduleDays.contains(label)) {
          scheduleDays.add(label);
        }
        final startLabel = _timeToLabel(item['startTime']);
        final endLabel = _timeToLabel(item['endTime']);
        if (dow.isNotEmpty && startLabel.isNotEmpty && endLabel.isNotEmpty) {
          scheduleByDay[dow] = '$startLabel - $endLabel';
        }
      }
    }

    final rawStudentId = json['code'] ?? json['studentCode'];
    return StudentListItemModel(
      code: rawStudentId == null ? '' : rawStudentId.toString().trim(),
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      profilePhotoAssetCode: json['profilePhotoAssetCode'] as String?,
      classroom: classroomCodeOrName,
      dob: json['dob'] as String? ?? '',
      movementDate: json['movementDate'] as String? ?? '',
      tags: tags,
      schedule: scheduleDays,
      scheduleByDay: scheduleByDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'firstName': firstName,
      'lastName': lastName,
      'status': status,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (profilePhotoAssetCode != null)
        'profilePhotoAssetCode': profilePhotoAssetCode,
      'classroom': classroom,
      'dob': dob,
      'movementDate': movementDate,
      'tags': tags,
      'schedule': schedule,
      'scheduleByDay': scheduleByDay,
    };
  }

  @override
  List<Object?> get props => [
        code,
        firstName,
        lastName,
        status,
        profilePhotoUrl,
        profilePhotoAssetCode,
        classroom,
        dob,
        movementDate,
        tags,
        schedule,
      ];
}

class StudentPageModel extends Equatable {
  const StudentPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentListItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];

  factory StudentPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map((e) => StudentListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final hasMore = pageNumber + 1 < totalPages;

    return StudentPageModel(
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
      'items': items.map((e) => e.toJson()).toList(),
      'page': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'hasMore': hasMore,
    };
  }

  factory StudentPageModel.fromCacheJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return StudentPageModel(
      items: itemsJson
          .map((e) => StudentListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class StudentImportantDatesModel extends Equatable {
  const StudentImportantDatesModel({
    this.enrollDate,
    this.schoolStartDate,
    this.currentClassroomStartDate,
    this.upcomingMoveDate,
    this.schoolLeavingDate,
  });

  final String? enrollDate;
  final String? schoolStartDate;
  final String? currentClassroomStartDate;
  final String? upcomingMoveDate;
  final String? schoolLeavingDate;

  factory StudentImportantDatesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const StudentImportantDatesModel();
    }
    return StudentImportantDatesModel(
      enrollDate: json['enrollDate'] as String?,
      schoolStartDate: json['schoolStartDate'] as String?,
      currentClassroomStartDate: json['currentClassroomStartDate'] as String?,
      upcomingMoveDate: json['upcomingMoveDate'] as String?,
      schoolLeavingDate: json['schoolLeavingDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (enrollDate != null) 'enrollDate': enrollDate,
      if (schoolStartDate != null) 'schoolStartDate': schoolStartDate,
      if (currentClassroomStartDate != null)
        'currentClassroomStartDate': currentClassroomStartDate,
      if (upcomingMoveDate != null) 'upcomingMoveDate': upcomingMoveDate,
      if (schoolLeavingDate != null) 'schoolLeavingDate': schoolLeavingDate,
    };
  }

  @override
  List<Object?> get props => [
        enrollDate,
        schoolStartDate,
        currentClassroomStartDate,
        upcomingMoveDate,
        schoolLeavingDate,
      ];
}

class StudentHealthModel extends Equatable {
  const StudentHealthModel({
    this.allergy,
    this.medications,
    this.dietRestrictions,
    this.photoPermission,
  });

  final String? allergy;
  final String? medications;
  final String? dietRestrictions;
  final bool? photoPermission;

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  factory StudentHealthModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const StudentHealthModel();
    }
    return StudentHealthModel(
      allergy: json['allergy'] as String?,
      medications: json['medications'] as String?,
      dietRestrictions: json['dietRestrictions'] as String?,
      photoPermission: _asBool(json['photoPermission']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (allergy != null) 'allergy': allergy,
      if (medications != null) 'medications': medications,
      if (dietRestrictions != null) 'dietRestrictions': dietRestrictions,
      if (photoPermission != null) 'photoPermission': photoPermission,
    };
  }

  @override
  List<Object?> get props => [
        allergy,
        medications,
        dietRestrictions,
        photoPermission,
      ];
}

class StudentPhysicalExamModel extends Equatable {
  const StudentPhysicalExamModel({
    required this.code,
    this.examDate,
    this.status,
    this.notes,
  });

  final String code;
  /// ISO date string `YYYY-MM-DD` (per backend contract).
  final String? examDate;
  /// e.g. `COMPLETED`, `DUE`.
  final String? status;
  final String? notes;

  factory StudentPhysicalExamModel.fromJson(Map<String, dynamic> json) {
    return StudentPhysicalExamModel(
      code: json['code'] as String? ?? '',
      examDate: json['examDate'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      if (examDate != null) 'examDate': examDate,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  List<Object?> get props => [code, examDate, status, notes];
}

class StudentImmunizationModel extends Equatable {
  const StudentImmunizationModel({
    required this.code,
    required this.studentCode,
    required this.vaccineName,
    required this.vaccineDoseCode,
    required this.doseNumber,
    this.dueDate,
    this.administeredDate,
    required this.status,
    this.exemptionReason,
    this.notes,
  });

  final String code;
  final String studentCode;
  final String vaccineName;
  final String vaccineDoseCode;
  final int doseNumber;
  final String? dueDate;
  final String? administeredDate;
  final String status;
  final String? exemptionReason;
  final String? notes;

  factory StudentImmunizationModel.fromJson(Map<String, dynamic> json) {
    return StudentImmunizationModel(
      code: json['code'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      vaccineName: json['vaccineName'] as String? ?? '',
      vaccineDoseCode: json['vaccineDoseCode'] as String? ?? '',
      doseNumber: json['doseNumber'] as int? ?? 0,
      dueDate: json['dueDate'] as String?,
      administeredDate: json['administeredDate'] as String?,
      status: json['status'] as String? ?? '',
      exemptionReason: json['exemptionReason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'studentCode': studentCode,
      'vaccineName': vaccineName,
      'vaccineDoseCode': vaccineDoseCode,
      'doseNumber': doseNumber,
      if (dueDate != null) 'dueDate': dueDate,
      if (administeredDate != null) 'administeredDate': administeredDate,
      'status': status,
      if (exemptionReason != null) 'exemptionReason': exemptionReason,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        code,
        studentCode,
        vaccineName,
        vaccineDoseCode,
        doseNumber,
        dueDate,
        administeredDate,
        status,
        exemptionReason,
        notes,
      ];
}

class StudentGuardianModel extends Equatable {
  const StudentGuardianModel({
    required this.guardianCode,
    required this.userCode,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    this.clockPin,
    required this.relationToStudent,
    required this.primaryContact,
    required this.legalCustody,
  });

  final String guardianCode;
  final String userCode;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final String? clockPin;
  final String relationToStudent;
  final bool primaryContact;
  final bool legalCustody;

  String get fullName => '$firstName $lastName'.trim();

  factory StudentGuardianModel.fromJson(Map<String, dynamic> json) {
    return StudentGuardianModel(
      guardianCode: json['guardianCode'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      clockPin: json['clockPin'] as String?,
      relationToStudent: json['relationToStudent'] as String? ?? '',
      primaryContact: json['primaryContact'] as bool? ?? false,
      legalCustody: json['legalCustody'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guardianCode': guardianCode,
      'userCode': userCode,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'email': email,
      'clockPin': clockPin,
      'relationToStudent': relationToStudent,
      'primaryContact': primaryContact,
      'legalCustody': legalCustody,
    };
  }

  @override
  List<Object?> get props => [
        guardianCode,
        userCode,
        firstName,
        lastName,
        mobile,
        email,
        clockPin,
        relationToStudent,
        primaryContact,
        legalCustody,
      ];
}

class StudentProfileModel extends Equatable {
  const StudentProfileModel({
    required this.code,
    required this.schoolCode,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.classroom,
    this.dob,
    this.notes,
    this.profilePhotoUrl,
    this.fte,
    this.gender,
    this.legalCustodians = const [],
    this.subsidy = false,
    this.address,
    this.tags = const [],
    this.siblings = const [],
    this.importantDates,
    this.regularSchedules = const [],
  });

  final String code;
  final String schoolCode;
  final String firstName;
  final String lastName;
  final String status;
  final String? classroom;
  final String? dob;
  final String? notes;
  final String? profilePhotoUrl;
  final String? fte;
  final String? gender;
  final List<dynamic> legalCustodians;
  final bool subsidy;
  final Map<String, dynamic>? address;
  /// Raw tags array from profile API. Each item is typically a map with
  /// { code, name, defaultTag }.
  final List<dynamic> tags;
  final List<dynamic> siblings;
  final StudentImportantDatesModel? importantDates;
  final List<dynamic> regularSchedules;

  String get fullName => '$firstName $lastName'.trim();

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    // Accept both the wire envelope `{success, message, data: {...}}` and the
    // flat shape produced by [toJson] (used when re-hydrating from cache).
    final rawData = json['data'];
    final data = rawData is Map<String, dynamic> ? rawData : json;
    final importantDatesJson = data['importantDates'] as Map<String, dynamic>?;

    // Classroom can come as a plain string or as an object { code, name }.
    final classroomRaw = data['classroom'];
    String? classroomName;
    if (classroomRaw is String) {
      classroomName = classroomRaw;
    } else if (classroomRaw is Map) {
      final name = classroomRaw['name'];
      final code = classroomRaw['code'];
      classroomName = (name?.toString().trim().isNotEmpty ?? false)
          ? name.toString()
          : (code?.toString() ?? '');
    }

    return StudentProfileModel(
      code: data['code'] as String? ?? '',
      schoolCode: data['schoolCode'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      status: data['status'] as String? ?? '',
      classroom: classroomName,
      dob: data['dob'] as String?,
      notes: data['notes'] as String?,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      fte: data['fte'] as String?,
      gender: data['gender'] as String?,
      legalCustodians: data['legalCustodians'] as List<dynamic>? ?? const [],
      subsidy: data['subsidy'] as bool? ?? false,
      address: data['address'] as Map<String, dynamic>?,
      tags: data['tags'] as List<dynamic>? ?? const [],
      siblings: data['siblings'] as List<dynamic>? ?? const [],
      importantDates: StudentImportantDatesModel.fromJson(importantDatesJson),
      regularSchedules: data['regularSchedules'] as List<dynamic>? ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'schoolCode': schoolCode,
      'firstName': firstName,
      'lastName': lastName,
      'status': status,
      if (classroom != null) 'classroom': classroom,
      if (dob != null) 'dob': dob,
      if (notes != null) 'notes': notes,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (fte != null) 'fte': fte,
      if (gender != null) 'gender': gender,
      'legalCustodians': legalCustodians,
      'subsidy': subsidy,
      if (address != null) 'address': address,
      'tags': tags,
      'siblings': siblings,
      if (importantDates != null) 'importantDates': importantDates!.toJson(),
      'regularSchedules': regularSchedules,
    };
  }

  @override
  List<Object?> get props => [
        code,
        schoolCode,
        firstName,
        lastName,
        status,
        classroom,
        dob,
        notes,
        profilePhotoUrl,
        fte,
        gender,
        legalCustodians,
        subsidy,
        address,
        tags,
        siblings,
        importantDates,
        regularSchedules,
      ];
}

