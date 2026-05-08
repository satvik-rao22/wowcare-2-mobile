import 'package:equatable/equatable.dart';

class StaffListItemModel extends Equatable {
  const StaffListItemModel({
    required this.code,
    required this.name,
    required this.primaryClassroomCode,
    required this.allowedClassroomCodes,
    required this.designation,
    required this.phoneNumber,
    required this.status,
    required this.email,
    this.profilePhotoAssetCode,
    this.workSchedules = const <StaffProfileWorkScheduleModel>[],
    this.breakSchedules = const <StaffProfileBreakScheduleModel>[],
  });

  final String code;
  final String name;
  /// Classroom code (from API field `primaryClassroom`).
  final String primaryClassroomCode;
  /// Classroom codes (from API field `allowedClassrooms`).
  final List<String> allowedClassroomCodes;
  final String designation;
  final String phoneNumber;
  final String status;
  final String email;
  final String? profilePhotoAssetCode;
  /// Optional work schedules returned by staff list API.
  final List<StaffProfileWorkScheduleModel> workSchedules;
  /// Optional break schedules returned by staff list API.
  final List<StaffProfileBreakScheduleModel> breakSchedules;

  factory StaffListItemModel.fromJson(Map<String, dynamic> json) {
    String _extractClassroomCode(dynamic value) {
      // New backend shape: { "code": "...", "name": "..." }
      if (value is Map<String, dynamic>) {
        return value['code']?.toString() ?? '';
      }
      // Legacy: "CLS_..."
      return value?.toString() ?? '';
    }

    // Backend contract (new):
    // - `primaryClassroom`: {code,name} or nulls
    // - `allowedClassrooms`: [{code,name}, ...]
    // Legacy fallback (old):
    // - `primaryClassroomCode`: "CLS_..."
    // - `classroomCodes`: ["CLS_...", ...]
    final primaryClassroomCode = _extractClassroomCode(json['primaryClassroom']);

    final allowed = (json['allowedClassrooms'] as List<dynamic>?)
            ?.map(_extractClassroomCode)
            .where((c) => c.isNotEmpty)
            .toList() ??
        (json['classroomCodes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((c) => c.isNotEmpty)
            .toList() ??
        const <String>[];

    // Optional schedule arrays on list API
    final workSchedulesJson =
        json['workSchedules'] as List<dynamic>? ?? const <dynamic>[];
    final breakSchedulesJson =
        json['breakSchedules'] as List<dynamic>? ?? const <dynamic>[];

    return StaffListItemModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      primaryClassroomCode: primaryClassroomCode.isNotEmpty
          ? primaryClassroomCode
          : (json['primaryClassroomCode'] as String?) ?? '',
      allowedClassroomCodes: allowed,
      designation: json['designation'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePhotoAssetCode: json['profilePhotoAssetCode'] as String?,
      workSchedules: workSchedulesJson
          .whereType<Map<String, dynamic>>()
          .map(StaffProfileWorkScheduleModel.fromJson)
          .toList(),
      breakSchedules: breakSchedulesJson
          .whereType<Map<String, dynamic>>()
          .map(StaffProfileBreakScheduleModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'primaryClassroom': primaryClassroomCode,
      'allowedClassrooms': allowedClassroomCodes,
      'designation': designation,
      'phoneNumber': phoneNumber,
      'status': status,
      'email': email,
      if (profilePhotoAssetCode != null)
        'profilePhotoAssetCode': profilePhotoAssetCode,
      'workSchedules': workSchedules.map((e) => e.toJson()).toList(),
      'breakSchedules': breakSchedules.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props =>
      [
        code,
        name,
        primaryClassroomCode,
        allowedClassroomCodes,
        designation,
        phoneNumber,
        status,
        email,
        profilePhotoAssetCode,
        workSchedules,
        breakSchedules,
      ];
}

class StaffPageModel extends Equatable {
  const StaffPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffListItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];

  factory StaffPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map((e) => StaffListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Prefer totalPages; fallback to totalElements when totalPages is 0 or missing
    final hasMore = totalPages > 0
        ? (pageNumber + 1 < totalPages)
        : (totalElements > 0 &&
            pageSize > 0 &&
            (pageNumber + 1) * pageSize < totalElements);

    // ignore: avoid_print
    print('[StaffPageModel] fromJson: page=$pageNumber, size=$pageSize, '
        'totalPages=$totalPages, totalElements=$totalElements, '
        'itemsOnPage=${items.length}, hasMore=$hasMore');

    return StaffPageModel(
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

  factory StaffPageModel.fromCacheJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return StaffPageModel(
      items: itemsJson
          .map((e) => StaffListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class StaffProfileAddressModel extends Equatable {
  const StaffProfileAddressModel({
    this.street = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
  });

  final String street;
  final String line2;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  factory StaffProfileAddressModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StaffProfileAddressModel();
    return StaffProfileAddressModel(
      street: json['addressStreet'] as String? ?? '',
      line2: json['addressLine2'] as String? ?? '',
      city: json['addressCity'] as String? ?? '',
      state: json['addressState'] as String? ?? '',
      zipCode: json['addressZipCode'] as String? ?? '',
      country: json['addressCountry'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressStreet': street,
      'addressLine2': line2,
      'addressCity': city,
      'addressState': state,
      'addressZipCode': zipCode,
      'addressCountry': country,
    };
  }

  String get formattedAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (line2.isNotEmpty) parts.add(line2);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipCode.isNotEmpty) parts.add(zipCode);
    if (country.isNotEmpty) parts.add(country);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  @override
  List<Object?> get props => [street, line2, city, state, zipCode, country];
}

class StaffProfileTimeModel extends Equatable {
  const StaffProfileTimeModel({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.nano = 0,
  });

  final int hour;
  final int minute;
  final int second;
  final int nano;

  /// Parses time from string format "HH:mm:ss" or "HH:mm:ss.SSSSSSSSS"
  factory StaffProfileTimeModel.fromJson(dynamic json) {
    if (json == null) return const StaffProfileTimeModel(hour: 0, minute: 0);
    
    // If it's already a Map (object format), parse it
    if (json is Map<String, dynamic>) {
      return StaffProfileTimeModel(
        hour: json['hour'] as int? ?? 0,
        minute: json['minute'] as int? ?? 0,
        second: json['second'] as int? ?? 0,
        nano: json['nano'] as int? ?? 0,
      );
    }
    
    // If it's a string, parse "HH:mm:ss" format
    if (json is String) {
      try {
        final parts = json.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final second = parts.length >= 3 ? (int.tryParse(parts[2].split('.').first) ?? 0) : 0;
          final nano = parts.length >= 3 && parts[2].contains('.')
              ? (int.tryParse(parts[2].split('.').last.padRight(9, '0').substring(0, 9)) ?? 0)
              : 0;
          return StaffProfileTimeModel(
            hour: hour,
            minute: minute,
            second: second,
            nano: nano,
          );
        }
      } catch (e) {
        // If parsing fails, return default
      }
    }
    
    return const StaffProfileTimeModel(hour: 0, minute: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'second': second,
      'nano': nano,
    };
  }

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute$period';
  }

  @override
  List<Object?> get props => [hour, minute, second, nano];
}

class StaffProfileWorkScheduleModel extends Equatable {
  const StaffProfileWorkScheduleModel({
    required this.dayOfWeek,
    required this.workStartTime,
    required this.workEndTime,
  });

  final String dayOfWeek;
  final StaffProfileTimeModel workStartTime;
  final StaffProfileTimeModel workEndTime;

  factory StaffProfileWorkScheduleModel.fromJson(Map<String, dynamic> json) {
    return StaffProfileWorkScheduleModel(
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      workStartTime: StaffProfileTimeModel.fromJson(json['workStartTime']),
      workEndTime: StaffProfileTimeModel.fromJson(json['workEndTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'workStartTime': workStartTime.toJson(),
      'workEndTime': workEndTime.toJson(),
    };
  }

  String get formattedTime {
    return '${workStartTime.formattedTime} - ${workEndTime.formattedTime}';
  }

  @override
  List<Object?> get props => [dayOfWeek, workStartTime, workEndTime];
}

class StaffProfileBreakScheduleModel extends Equatable {
  const StaffProfileBreakScheduleModel({
    required this.dayOfWeek,
    required this.breakType,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  final String dayOfWeek;
  final String breakType;
  final StaffProfileTimeModel breakStartTime;
  final StaffProfileTimeModel breakEndTime;

  factory StaffProfileBreakScheduleModel.fromJson(Map<String, dynamic> json) {
    return StaffProfileBreakScheduleModel(
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      breakType: json['breakType'] as String? ?? '',
      breakStartTime: StaffProfileTimeModel.fromJson(json['breakStartTime']),
      breakEndTime: StaffProfileTimeModel.fromJson(json['breakEndTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'breakType': breakType,
      'breakStartTime': breakStartTime.toJson(),
      'breakEndTime': breakEndTime.toJson(),
    };
  }

  String get formattedTime {
    return '${breakStartTime.formattedTime} - ${breakEndTime.formattedTime}';
  }

  @override
  List<Object?> get props => [dayOfWeek, breakType, breakStartTime, breakEndTime];
}

class StaffProfileModel extends Equatable {
  const StaffProfileModel({
    required this.staffCode,
    required this.userCode,
    required this.organizationCode,
    required this.schoolCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoUrl = '',
    this.birthDate = '',
    required this.staffType,
    required this.status,
    required this.designation,
    this.jobTag = '',
    this.clockPin = '',
    this.primaryClassroomCode = '',
    required this.allowedClassroomCodes,
    required this.address,
    required this.workSchedules,
    required this.breakSchedules,
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String staffCode;
  final String userCode;
  final String organizationCode;
  final String schoolCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String profilePhotoUrl;
  final String birthDate;
  final String staffType;
  final String status;
  final String designation;
  final String jobTag;
  final String clockPin;
  final String primaryClassroomCode;
  final List<String> allowedClassroomCodes;
  final StaffProfileAddressModel address;
  final List<StaffProfileWorkScheduleModel> workSchedules;
  final List<StaffProfileBreakScheduleModel> breakSchedules;
  final String createdAt;
  final String updatedAt;

  factory StaffProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    // Backend variants:
    // - Newer: address is nested under `address`
    // - Legacy/current UAT: address fields are top-level: addressStreet, addressCity, ...
    final nestedAddress = data['address'] as Map<String, dynamic>?;
    final addressJson = nestedAddress ??
        <String, dynamic>{
          'addressStreet': data['addressStreet'],
          'addressLine2': data['addressLine2'],
          'addressCity': data['addressCity'],
          'addressState': data['addressState'],
          'addressZipCode': data['addressZipCode'],
          'addressCountry': data['addressCountry'],
        };
    final workSchedulesJson = data['workSchedules'] as List<dynamic>? ?? const [];
    final breakSchedulesJson = data['breakSchedules'] as List<dynamic>? ?? const [];

    String _extractClassroomCode(dynamic value) {
      // New backend shape: { "code": "...", "name": "..." }
      if (value is Map<String, dynamic>) {
        return value['code']?.toString() ?? '';
      }
      // Legacy: "CLS_..."
      return value?.toString() ?? '';
    }

    final primaryFromObject = _extractClassroomCode(data['primaryClassroom']);
    final primaryClassroomCode = primaryFromObject.isNotEmpty
        ? primaryFromObject
        : (data['primaryClassroomCode'] as String? ?? '');

    // New backend shape:
    // - allowedClassrooms: [{code,name}, ...]
    // Legacy fallback:
    // - allowedClassroomCodes: ["CLS_...", ...]
    final allowedCodes = (data['allowedClassrooms'] as List<dynamic>?)
            ?.map(_extractClassroomCode)
            .where((c) => c.trim().isNotEmpty)
            .toList() ??
        (data['allowedClassroomCodes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((c) => c.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    return StaffProfileModel(
      staffCode: (data['staffCode'] ?? data['code'] ?? '').toString(),
      userCode: data['userCode'] as String? ?? '',
      organizationCode: data['organizationCode'] as String? ?? '',
      schoolCode: data['schoolCode'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      fullName: (data['fullName'] as String?) ??
          '${(data['firstName'] ?? '').toString()} ${(data['lastName'] ?? '').toString()}'
              .trim(),
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      profilePhotoUrl: data['profilePhotoUrl'] as String? ?? '',
      birthDate: data['birthDate'] as String? ?? '',
      staffType: data['staffType'] as String? ?? '',
      status: data['status'] as String? ?? '',
      designation: data['designation'] as String? ?? '',
      jobTag: data['jobTag'] as String? ?? '',
      clockPin: data['clockPin'] as String? ?? '',
      primaryClassroomCode: primaryClassroomCode,
      allowedClassroomCodes: allowedCodes,
      address: StaffProfileAddressModel.fromJson(addressJson),
      workSchedules: workSchedulesJson
          .map((e) => StaffProfileWorkScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      breakSchedules: breakSchedulesJson
          .map((e) => StaffProfileBreakScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: data['createdAt'] as String? ?? '',
      updatedAt: data['updatedAt'] as String? ?? '',
    );
  }

  factory StaffProfileModel.fromCacheJson(Map<String, dynamic> json) {
    // Cache variants:
    // - Current: nested `address`
    // - Legacy: address fields at top-level
    final nestedAddress = json['address'] as Map<String, dynamic>?;
    final addressJson = nestedAddress ??
        <String, dynamic>{
          'addressStreet': json['addressStreet'],
          'addressLine2': json['addressLine2'],
          'addressCity': json['addressCity'],
          'addressState': json['addressState'],
          'addressZipCode': json['addressZipCode'],
          'addressCountry': json['addressCountry'],
        };
    final workSchedulesJson = json['workSchedules'] as List<dynamic>? ?? const [];
    final breakSchedulesJson = json['breakSchedules'] as List<dynamic>? ?? const [];

    String _extractClassroomCode(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['code']?.toString() ?? '';
      }
      return value?.toString() ?? '';
    }

    final allowedCodes = (json['allowedClassrooms'] as List<dynamic>?)
            ?.map(_extractClassroomCode)
            .where((c) => c.trim().isNotEmpty)
            .toList() ??
        (json['allowedClassroomCodes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((c) => c.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    return StaffProfileModel(
      staffCode: (json['staffCode'] ?? json['code'] ?? '').toString(),
      userCode: json['userCode'] as String? ?? '',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      fullName: (json['fullName'] as String?) ??
          '${(json['firstName'] ?? '').toString()} ${(json['lastName'] ?? '').toString()}'
              .trim(),
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      staffType: json['staffType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      jobTag: json['jobTag'] as String? ?? '',
      clockPin: json['clockPin'] as String? ?? '',
      primaryClassroomCode: json['primaryClassroomCode'] as String? ?? '',
      allowedClassroomCodes: allowedCodes,
      address: StaffProfileAddressModel.fromJson(addressJson),
      workSchedules: workSchedulesJson
          .map((e) => StaffProfileWorkScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      breakSchedules: breakSchedulesJson
          .map((e) => StaffProfileBreakScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'userCode': userCode,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePhotoUrl': profilePhotoUrl,
      'birthDate': birthDate,
      'staffType': staffType,
      'status': status,
      'designation': designation,
      'jobTag': jobTag,
      'clockPin': clockPin,
      'primaryClassroomCode': primaryClassroomCode,
      'allowedClassroomCodes': allowedClassroomCodes,
      'address': address.toJson(),
      'workSchedules': workSchedules.map((e) => e.toJson()).toList(),
      'breakSchedules': breakSchedules.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        staffCode,
        userCode,
        organizationCode,
        schoolCode,
        firstName,
        lastName,
        fullName,
        email,
        phoneNumber,
        profilePhotoUrl,
        birthDate,
        staffType,
        status,
        designation,
        jobTag,
        clockPin,
        primaryClassroomCode,
        allowedClassroomCodes,
        address,
        workSchedules,
        breakSchedules,
        createdAt,
        updatedAt,
      ];
}


