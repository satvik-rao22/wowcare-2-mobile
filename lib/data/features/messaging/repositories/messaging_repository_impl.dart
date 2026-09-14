import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../core/utils/attendance_classroom_scope.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/messaging/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_data_source.dart';
import '../../staff/models/staff_models.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteDataSource _remoteDataSource;
  final StaffRepository _staffRepository;
  final StorageService _storageService;

  MessagingRepositoryImpl({
    required MessagingRemoteDataSource remoteDataSource,
    required StaffRepository staffRepository,
    required StorageService storageService,
  }) : _remoteDataSource = remoteDataSource,
       _staffRepository = staffRepository,
       _storageService = storageService;

  @override
  Future<StaffPage> getFilteredStaff({
    required String organizationCode,
    required String schoolCode,
    required int page,
    required int size,
    String? status,
    String? designation,
    String? search,
    String? classCode,
  }) async {
    List<String>? effectiveClassCodes;
    final isScoped = await isAttendanceScopedStaffPersona(
      storage: _storageService,
    );
    if (isScoped) {
      final allowedCodes = await resolveAttendanceAllowedClassroomCodes(
        storage: _storageService,
      );
      if (classCode != null && classCode.isNotEmpty) {
        if (allowedCodes.contains(classCode.trim())) {
          effectiveClassCodes = [classCode.trim()];
        } else {
          return StaffPage(
            items: const [],
            page: page,
            size: size,
            totalPages: 0,
            totalElements: 0,
            hasMore: false,
          );
        }
      } else {
        effectiveClassCodes = allowedCodes;
      }
    } else {
      if (classCode != null && classCode.isNotEmpty) {
        effectiveClassCodes = [classCode.trim()];
      }
    }

    if (isScoped &&
        (effectiveClassCodes == null || effectiveClassCodes.isEmpty)) {
      return StaffPage(
        items: [],
        page: page,
        size: size,
        totalPages: 0,
        totalElements: 0,
        hasMore: false,
      );
    }

    final staffPageModel = await _remoteDataSource.getFilteredStaff(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      page: page,
      size: size,
      status: status,
      designation: designation,
      search: search,
      classCodes: effectiveClassCodes,
    );

    return _mapPageModelToEntity(staffPageModel);
  }

  @override
  Future<StaffPage> getStaffFromConversationsByStatus({
    required String organizationCode,
    required String schoolCode,
    required int page,
    required int size,
    required String staffStatus,
    String? designation,
    String? search,
    String? classCode,
  }) async {
    final conversationsResponse = await _remoteDataSource
        .getConversationsByStaffStatus(
          page: page,
          size: size,
          staffStatus: staffStatus,
        );

    final conversations = conversationsResponse.data?.content ?? [];

    final allStaff = await _staffRepository.getAllStaff(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      statuses: const ['ACTIVE', 'UPCOMING', 'INACTIVE'],
    );

    final Map<String, StaffMember> staffMap = {
      for (var s in allStaff) s.code: s,
    };

    final currentUserCode =
        (await _storageService.getString(StorageKeys.userCode))?.trim() ?? '';

    final isScoped = await isAttendanceScopedStaffPersona(
      storage: _storageService,
    );
    final allowedCodes = isScoped
        ? await resolveAttendanceAllowedClassroomCodes(storage: _storageService)
        : null;
    final allowedSet = allowedCodes?.map((e) => e.trim()).toSet();

    final List<StaffMember> matchedStaff = [];
    for (final conv in conversations) {
      if (conv.participants.isEmpty) continue;

      final otherParticipant = conv.participants.firstWhere(
        (p) => p.userCode != currentUserCode,
        orElse: () => conv.participants.first,
      );

      final userCode = otherParticipant.userCode;
      if (userCode == currentUserCode) continue;

      StaffMember staff;
      if (staffMap.containsKey(userCode)) {
        staff = staffMap[userCode]!;
      } else {
        staff = StaffMember(
          code: userCode,
          name: otherParticipant.userName,
          primaryClassroomCode: '',
          allowedClassroomCodes: const [],
          designation: otherParticipant.role,
          phoneNumber: '',
          status: staffStatus,
          email: '',
        );
      }

      if (allowedSet != null) {
        final matchesAllowedClass =
            (staff.primaryClassroomCode.isNotEmpty &&
                allowedSet.contains(staff.primaryClassroomCode.trim())) ||
            staff.allowedClassroomCodes.any(
              (code) => allowedSet.contains(code.trim()),
            );
        if (!matchesAllowedClass) {
          continue;
        }
      }

      // Apply designation, classroom, and search filters locally if provided
      if (designation != null && designation.trim().isNotEmpty) {
        if (staff.designation.trim().toUpperCase() !=
            designation.trim().toUpperCase()) {
          continue;
        }
      }

      if (classCode != null && classCode.trim().isNotEmpty) {
        final matchesClassroom =
            staff.primaryClassroomCode == classCode.trim() ||
            staff.allowedClassroomCodes.contains(classCode.trim());
        if (!matchesClassroom) {
          continue;
        }
      }

      if (search != null && search.trim().isNotEmpty) {
        final nameMatches = staff.name.toLowerCase().contains(
          search.trim().toLowerCase(),
        );
        final emailMatches = staff.email.toLowerCase().contains(
          search.trim().toLowerCase(),
        );
        if (!nameMatches && !emailMatches) {
          continue;
        }
      }

      matchedStaff.add(staff);
    }

    final int totalPages = conversationsResponse.data?.totalPages ?? 0;
    final int totalElements = conversationsResponse.data?.totalElements ?? 0;
    final bool hasMore = totalPages > 0
        ? (page + 1 < totalPages)
        : (totalElements > 0 && size > 0 && (page + 1) * size < totalElements);

    return StaffPage(
      items: matchedStaff,
      page: page,
      size: size,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  StaffPage _mapPageModelToEntity(StaffPageModel model) {
    final items = model.items.map(_mapStaffListItemToEntity).toList();
    return StaffPage(
      items: items,
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  StaffMember _mapStaffListItemToEntity(StaffListItemModel m) {
    String formatTimeOfDay(int hour, int minute) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute$period';
    }

    String formatRange(
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
    ) {
      final start = formatTimeOfDay(startHour, startMinute);
      final end = formatTimeOfDay(endHour, endMinute);
      return '$start - $end';
    }

    final workByDay = <String, String>{};
    for (final ws in m.workSchedules) {
      if (ws.dayOfWeek.isEmpty) continue;
      workByDay[ws.dayOfWeek] = formatRange(
        ws.workStartTime.hour,
        ws.workStartTime.minute,
        ws.workEndTime.hour,
        ws.workEndTime.minute,
      );
    }

    final breakByDay = <String, String>{};
    for (final bs in m.breakSchedules) {
      if (bs.dayOfWeek.isEmpty) continue;
      breakByDay[bs.dayOfWeek] = formatRange(
        bs.breakStartTime.hour,
        bs.breakStartTime.minute,
        bs.breakEndTime.hour,
        bs.breakEndTime.minute,
      );
    }

    return StaffMember(
      code: m.code,
      name: m.name,
      primaryClassroomCode: m.primaryClassroomCode,
      primaryClassroomName: m.primaryClassroomName,
      allowedClassroomCodes: m.allowedClassroomCodes,
      allowedClassroomNameByCode: m.allowedClassroomNameByCode,
      designation: m.designation,
      phoneNumber: m.phoneNumber,
      profilePhotoAssetCode: m.profilePhotoAssetCode,
      status: m.status,
      email: m.email,
      workScheduleByDay: workByDay,
      breakScheduleByDay: breakByDay,
    );
  }
}
