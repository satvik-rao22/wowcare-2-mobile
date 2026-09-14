import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_models.g.dart';

/// Coerces a loosely-typed JSON bool (bool / 0|1 / "true"|"yes"|"false"|"no").
bool? _photoPermissionFromJson(dynamic value) {
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

class StudentListItemModel extends Equatable {
  const StudentListItemModel({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.profilePhotoUrl,
    this.profilePhotoAssetCode,
    this.classroom = '',
    this.classroomCode = '',
    this.hasGuardian = true,
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

  /// The classroom's actual CODE (`CLS_...`), straight from
  /// `classroom.code` in this same API response — kept separate from
  /// [classroom] (the display NAME) rather than folding one into the
  /// other, so callers that need the code (e.g. scoping a Room Chat
  /// creation) don't have to re-resolve it by matching the name against a
  /// separately-loaded classroom list.
  final String classroomCode;

  /// Whether this student has at least one guardian linked, straight from
  /// the list API's own `hasGuardian` field. Defaults to true (don't
  /// disable) when the field is missing so an endpoint that doesn't send it
  /// fails open rather than disabling every student. Web disables selecting
  /// a student without a guardian when starting a new conversation — this
  /// is what that check is based on.
  final bool hasGuardian;
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
    // Prefer a flat top-level 'classroomCode' (round-tripped from our own
    // [toJson]/cache) over re-deriving it from 'classroom', since a cached
    // blob's 'classroom' is already flattened to just the display name by
    // the time it's written — the nested {name, code} shape only exists on
    // a fresh API response.
    String classroomCode = json['classroomCode']?.toString().trim() ?? '';
    if (classroomRaw is String) {
      classroomCodeOrName = classroomRaw;
    } else if (classroomRaw is Map) {
      final name = classroomRaw['name']?.toString().trim() ?? '';
      final code = classroomRaw['code']?.toString().trim() ?? '';
      if (classroomCode.isEmpty) classroomCode = code;
      classroomCodeOrName = name.isNotEmpty ? name : code;
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
      classroomCode: classroomCode,
      hasGuardian: json['hasGuardian'] as bool? ?? true,
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
      'classroomCode': classroomCode,
      'hasGuardian': hasGuardian,
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
    classroomCode,
    hasGuardian,
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
  List<Object?> get props => [
    items,
    page,
    size,
    totalPages,
    totalElements,
    hasMore,
  ];

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

@JsonSerializable(includeIfNull: false)
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

  /// Null-safe wrapper around the generated fromJson (the caller may pass null).
  factory StudentImportantDatesModel.fromJson(Map<String, dynamic>? json) =>
      json == null
          ? const StudentImportantDatesModel()
          : _$StudentImportantDatesModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentImportantDatesModelToJson(this);

  @override
  List<Object?> get props => [
    enrollDate,
    schoolStartDate,
    currentClassroomStartDate,
    upcomingMoveDate,
    schoolLeavingDate,
  ];
}

@JsonSerializable(includeIfNull: false)
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

  /// Coerced from a loosely-typed JSON bool via [_photoPermissionFromJson].
  @JsonKey(fromJson: _photoPermissionFromJson)
  final bool? photoPermission;

  /// Null-safe wrapper around the generated fromJson.
  factory StudentHealthModel.fromJson(Map<String, dynamic>? json) => json == null
      ? const StudentHealthModel()
      : _$StudentHealthModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentHealthModelToJson(this);

  @override
  List<Object?> get props => [
    allergy,
    medications,
    dietRestrictions,
    photoPermission,
  ];
}

@JsonSerializable(includeIfNull: false)
class StudentPhysicalExamModel extends Equatable {
  const StudentPhysicalExamModel({
    required this.code,
    this.examDate,
    this.status,
    this.notes,
  });

  @JsonKey(defaultValue: '')
  final String code;

  /// ISO date string `YYYY-MM-DD` (per backend contract).
  final String? examDate;

  /// e.g. `COMPLETED`, `DUE`.
  final String? status;
  final String? notes;

  factory StudentPhysicalExamModel.fromJson(Map<String, dynamic> json) =>
      _$StudentPhysicalExamModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentPhysicalExamModelToJson(this);

  @override
  List<Object?> get props => [code, examDate, status, notes];
}

@JsonSerializable(includeIfNull: false)
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

  @JsonKey(defaultValue: '')
  final String code;
  @JsonKey(defaultValue: '')
  final String studentCode;
  @JsonKey(defaultValue: '')
  final String vaccineName;
  @JsonKey(defaultValue: '')
  final String vaccineDoseCode;
  @JsonKey(defaultValue: 0)
  final int doseNumber;
  final String? dueDate;
  final String? administeredDate;
  @JsonKey(defaultValue: '')
  final String status;
  final String? exemptionReason;
  final String? notes;

  factory StudentImmunizationModel.fromJson(Map<String, dynamic> json) =>
      _$StudentImmunizationModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentImmunizationModelToJson(this);

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
    this.profilePhotoUrl,
    this.profilePhotoAssetCode,
    this.displayNameOverride,
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

  /// Direct profile-photo URL, if the backend returns one.
  final String? profilePhotoUrl;

  /// Document-MS asset code for the profile photo, when the backend returns a
  /// code instead of a ready URL (resolved to a URL by [DocumentImageWidget]).
  final String? profilePhotoAssetCode;

  /// Set by [fromJson] only when [firstName]/[lastName] are both empty but a
  /// display name is available from a fallback field (top-level `fullName`/
  /// `name`, or a nested `user` object) — a malformed-but-real guardian
  /// record. Never overrides a genuine firstName+lastName, so it's purely
  /// additive; [firstName]/[lastName] themselves stay exactly what the
  /// backend sent for any consumer that needs the structured name parts
  /// (e.g. pre-filling an edit-guardian form).
  final String? displayNameOverride;

  String get fullName {
    final structured = '$firstName $lastName'.trim();
    if (structured.isNotEmpty) return structured;
    return displayNameOverride ?? '';
  }

  factory StudentGuardianModel.fromJson(Map<String, dynamic> json) {
    String? firstNonEmpty(List<String> keys, [Map<String, dynamic>? source]) {
      final map = source ?? json;
      for (final k in keys) {
        final v = (map[k] as Object?)?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return null;
    }

    // Fallback display-name resolution for a malformed guardian record whose
    // top-level firstName/lastName are both empty — mirrors the pre-MVVM-
    // migration View helper this replaced: top-level fullName/name, then the
    // same pair nested under a `user` object.
    String? resolveDisplayNameOverride() {
      // Cache round-trip: toJson() persists the already-resolved override
      // under this key, and the raw API response never uses this exact key
      // name, so checking it first is safe and avoids re-deriving (and
      // avoids losing it, since a cached payload won't carry the original
      // fullName/name/user fields toJson() doesn't persist).
      final cached = firstNonEmpty(const ['displayNameOverride']);
      if (cached != null) return cached;
      final direct = firstNonEmpty(const ['fullName', 'name']);
      if (direct != null) return direct;
      final user = json['user'];
      if (user is Map<String, dynamic>) {
        final uFirst = firstNonEmpty(const ['firstName', 'first_name'], user);
        final uLast = firstNonEmpty(const ['lastName', 'last_name'], user);
        final uCombined = '${uFirst ?? ''} ${uLast ?? ''}'.trim();
        if (uCombined.isNotEmpty) return uCombined;
        return firstNonEmpty(const ['fullName', 'name'], user);
      }
      return null;
    }

    return StudentGuardianModel(
      // The per-student guardian endpoint returns the code under `code`, while
      // some other guardian endpoints use `guardianCode`. Accept either so the
      // edit/delete flows always have a non-empty code to work with.
      guardianCode: (json['guardianCode'] as String?)?.trim().isNotEmpty == true
          ? (json['guardianCode'] as String)
          : (json['code'] as String? ?? ''),
      userCode: json['userCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      clockPin: json['clockPin'] as String?,
      relationToStudent: json['relationToStudent'] as String? ?? '',
      primaryContact: json['primaryContact'] as bool? ?? false,
      legalCustody: json['legalCustody'] as bool? ?? false,
      profilePhotoUrl: firstNonEmpty(const [
        'profilePhotoUrl',
        'photoUrl',
        'profileImageUrl',
        'imageUrl',
      ]),
      profilePhotoAssetCode: firstNonEmpty(const [
        'profilePhotoAssetCode',
        'photoAssetCode',
        'mediaAssetCode',
      ]),
      displayNameOverride: resolveDisplayNameOverride(),
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
      'profilePhotoUrl': profilePhotoUrl,
      'profilePhotoAssetCode': profilePhotoAssetCode,
      'displayNameOverride': displayNameOverride,
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
    profilePhotoUrl,
    profilePhotoAssetCode,
    displayNameOverride,
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
    this.classroomCode,
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

  /// The classroom's actual CODE (`CLS_...`) — see
  /// [StudentListItemModel.classroomCode] for why this is kept separate
  /// from [classroom] (the display name) instead of derived from it.
  final String? classroomCode;
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
    String? classroomCode = data['classroomCode'] as String?;
    if (classroomRaw is String) {
      classroomName = classroomRaw;
    } else if (classroomRaw is Map) {
      final name = classroomRaw['name'];
      final code = classroomRaw['code']?.toString();
      classroomCode ??= code;
      classroomName = (name?.toString().trim().isNotEmpty ?? false)
          ? name.toString()
          : (code ?? '');
    }

    return StudentProfileModel(
      code: data['code'] as String? ?? '',
      schoolCode: data['schoolCode'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      status: data['status'] as String? ?? '',
      classroom: classroomName,
      classroomCode: classroomCode,
      dob: data['dob'] as String?,
      notes: data['notes'] as String?,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      // `fte` arrives as a number (e.g. 1.0) from the API but is stored as a
      // string here; coerce rather than cast so a double/int doesn't crash.
      fte: data['fte']?.toString(),
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
      if (classroomCode != null) 'classroomCode': classroomCode,
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
    classroomCode,
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
