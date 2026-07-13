import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.code,
    required this.name,
    this.userCode = '',
    required this.primaryClassroomCode,
    this.primaryClassroomName = '',
    required this.allowedClassroomCodes,
    this.allowedClassroomNameByCode = const <String, String>{},
    required this.designation,
    required this.phoneNumber,
    this.profileImage,
    this.profilePhotoAssetCode,
    required this.status,
    required this.email,
    this.workScheduleByDay = const <String, String>{},
    this.breakScheduleByDay = const <String, String>{},
  });

  final String code;
  final String name;
  /// User account code (USR_*) — the participant identifier for messaging.
  final String userCode;
  final String? profileImage;
  final String? profilePhotoAssetCode;
  final String primaryClassroomCode;
  /// Human-readable primary classroom from staff list API (`primaryClassroom.name`).
  final String primaryClassroomName;
  final List<String> allowedClassroomCodes;
  /// Optional names from staff list API for each allowed classroom code.
  final Map<String, String> allowedClassroomNameByCode;
  final String designation;
  final String phoneNumber;
  final String status;
  final String email;
  /// Map of dayOfWeek (e.g. MONDAY) -> "start - end" (e.g. "12:05PM - 7:04PM").
  final Map<String, String> workScheduleByDay;
  /// Map of dayOfWeek (e.g. MONDAY) -> "start - end" for break, if any.
  final Map<String, String> breakScheduleByDay;

  /// Backward-compatible alias for older UI code.
  List<String> get classroomCodes => allowedClassroomCodes;

  /// Backward-compatible alias for older UI code.
  String get primaryClassroom => primaryClassroomOrFirstAllowed;

  /// Fallback helper when primary classroom isn't set but allowed classrooms exist.
  String get primaryClassroomOrFirstAllowed =>
      primaryClassroomCode.isNotEmpty
          ? primaryClassroomCode
          : (allowedClassroomCodes.isNotEmpty ? allowedClassroomCodes.first : '');

  @override
  List<Object?> get props =>
      [
        code,
        name,
        userCode,
        primaryClassroomCode,
        primaryClassroomName,
        allowedClassroomCodes,
        allowedClassroomNameByCode,
        designation,
        phoneNumber,
        status,
        email,
        profilePhotoAssetCode,
        workScheduleByDay,
        breakScheduleByDay,
      ];
}

class StaffPage extends Equatable {
  const StaffPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffMember> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}


