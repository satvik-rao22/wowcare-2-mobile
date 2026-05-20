// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import '../../../../../app/di/di.dart';
// import '../../../../../core/storage/storage_service.dart';
// import '../../../../../core/util/storage_keys.dart';
// import '../../../../../domain/features/classroom/entities/classroom.dart';
// import '../../../../../domain/features/classroom/repositories/classroom_repository.dart';
// import '../../../../../domain/features/staff/entities/staff_member.dart';
// import '../../../../../domain/features/staff/repositories/staff_repository.dart';
// import '../../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
// import 'staff_schedule_state.dart';

// class StaffScheduleCubit extends Cubit<StaffScheduleState> {
//   final StaffRepository staffRepository;

//   final ClassroomRepository classroomRepository;

//   final StaffSchedulingRepository staffSchedulingRepository;

//   final StorageService storage;
//   final ClassroomRepository _classroomRepository =
//       serviceLocator<ClassroomRepository>();
//   final StaffRepository _staffRepository = serviceLocator<StaffRepository>();
//   final StaffSchedulingRepository _staffSchedulingRepository =
//       serviceLocator<StaffSchedulingRepository>();
//   final StorageService _storage = serviceLocator<StorageService>();

//   StaffScheduleCubit({
//     required this.staffRepository,
//     required this.classroomRepository,
//     required this.staffSchedulingRepository,
//     required this.storage,
//   }) : super(const StaffScheduleState());

//   Future<void> loadStaffList() async {
//     emit(state.copyWith(isLoadingStaff: true, staffError: null));

//     try {
//       final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';

//       final results = await Future.wait([
//         staffRepository.getStaffListBySchool(schoolCode: schoolCode),

//         classroomRepository.getActiveClassrooms(
//           schoolCode: schoolCode,
//           onlyTypeClassroom: true,
//         ),
//       ]);

//       final staff = results[0] as List<StaffMember>;
//       final classrooms = results[1] as List<Classroom>;

//       final Map<String, String> classroomMap = {
//         for (final c in classrooms)
//           if (c.code.isNotEmpty) c.code.toString(): c.name.toString(),
//       };

//       emit(
//         state.copyWith(
//           isLoadingStaff: false,
//           staffList: staff,
//           classroomMap: classroomMap,
//         ),
//       );

//       if (staff.isNotEmpty) {
//         loadStaffSchedule(staff.first);
//       }
//     } catch (e) {
//       emit(
//         state.copyWith(
//           isLoadingStaff: false,
//           staffError: 'Failed to load staff list',
//         ),
//       );
//     }
//   }

//   Future<void> loadStaffSchedule(StaffMember staff) async {
//     emit(
//       state.copyWith(
//         isLoadingSchedule: true,
//         scheduleError: null,
//         selectedStaff: staff,
//       ),
//     );

//     try {
//       final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';

//       final organizationCode =
//           await storage.getString(StorageKeys.organizationCode) ?? '';

//       final profile = await staffRepository.getStaffProfile(
//         staffCode: staff.code,
//         forEditStaff: true,
//       );

//       final now = DateTime.now();

//       final dateFrom = DateFormat('yyyy-MM-dd').format(now);

//       final dateTo = DateFormat(
//         'yyyy-MM-dd',
//       ).format(now.add(const Duration(days: 6)));

//       final shifts = await staffSchedulingRepository.getStaffShifts(
//         classroomCode: profile.primaryClassroomCode,
//         dateFrom: dateFrom,
//         dateTo: dateTo,
//         schoolCode: schoolCode,
//         organizationCode: organizationCode,
//       );

//       emit(
//         state.copyWith(
//           isLoadingSchedule: false,
//           selectedProfile: profile,
//           shifts: shifts,
//         ),
//       );
//     } catch (e) {
//       emit(
//         state.copyWith(
//           isLoadingSchedule: false,
//           scheduleError: 'Failed to load schedule',
//         ),
//       );
//     }
//   }
// }

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/storage_keys.dart';

import '../../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../../domain/features/classroom/repositories/classroom_repository.dart';

import '../../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../../domain/features/staff/repositories/staff_repository.dart';

import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';

import 'staff_schedule_state.dart';

class StaffScheduleCubit extends Cubit<StaffScheduleState> {
  final StaffRepository staffRepository;

  final ClassroomRepository classroomRepository;

  final StaffSchedulingRepository staffSchedulingRepository;

  final StorageService storage;

  StaffScheduleCubit({
    required this.staffRepository,
    required this.classroomRepository,
    required this.staffSchedulingRepository,
    required this.storage,
  }) : super(const StaffScheduleState());

  /// =========================================================
  /// LOAD STAFF LIST
  /// =========================================================

  Future<void> loadStaffList() async {
    emit(state.copyWith(isLoadingStaff: true, staffError: null));

    try {
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';

      final results = await Future.wait([
        /// STAFF LIST
        staffRepository.getStaffListBySchool(schoolCode: schoolCode),

        /// CLASSROOMS
        classroomRepository.getActiveClassrooms(
          schoolCode: schoolCode,
          onlyTypeClassroom: true,
        ),
      ]);

      /// STAFF
      final List<StaffMember> staff = results[0] as List<StaffMember>;

      /// CLASSROOMS
      final List<Classroom> classrooms = results[1] as List<Classroom>;

      /// CLASSROOM MAP
      final Map<String, String> classroomMap = {
        for (final c in classrooms)
          if (c.code.isNotEmpty) c.code.toString(): c.name.toString(),
      };

      emit(
        state.copyWith(
          isLoadingStaff: false,
          staffError: null,
          staffList: staff,
          classroomMap: classroomMap,
        ),
      );

      /// AUTO SELECT FIRST STAFF
      if (staff.isNotEmpty) {
        await loadStaffSchedule(staff.first);
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingStaff: false,
          staffError: 'Failed to load staff list.\nPlease try again.',
          staffList: const [],
        ),
      );
    }
  }

  /// =========================================================
  /// LOAD STAFF PROFILE + SCHEDULE
  /// =========================================================

  Future<void> loadStaffSchedule(
    StaffMember staff, {
    DateTime? selectedDate,
    String? publishStatus,
  }) async {
    emit(
      state.copyWith(
        isLoadingSchedule: true,
        scheduleError: null,
        selectedStaff: staff,
        shifts: const [],
      ),
    );

    try {
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';

      final organizationCode =
          await storage.getString(StorageKeys.organizationCode) ?? '';

      /// PROFILE
      final profile = await staffRepository.getStaffProfile(
        staffCode: staff.code,
        forEditStaff: true,
      );

      final now = selectedDate ?? DateTime.now();

      /// WEEK START
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - DateTime.monday));

      /// WEEK END
      final weekEnd = weekStart.add(const Duration(days: 6));

      final dateFrom = DateFormat('yyyy-MM-dd').format(weekStart);

      final dateTo = DateFormat('yyyy-MM-dd').format(weekEnd);

      /// CLASSROOM CODE
      final classroomCode = profile.primaryClassroomCode.isNotEmpty
          ? profile.primaryClassroomCode
          : (staff.primaryClassroomOrFirstAllowed.isNotEmpty
                ? staff.primaryClassroomOrFirstAllowed
                : null);

      /// SHIFT STATUS
      String? shiftStatus;

      if (publishStatus != null) {
        shiftStatus = publishStatus == 'Published'
            ? 'PUBLISHED'
            : 'UNPUBLISHED';
      }

      /// SHIFTS
      final List<StaffShiftEntity> allShifts = await staffSchedulingRepository
          .getStaffShifts(
            classroomCode: classroomCode,
            dateFrom: dateFrom,
            dateTo: dateTo,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
            shiftStatus: shiftStatus,
          );

      /// FILTER STAFF SHIFTS
      final List<StaffShiftEntity> staffShifts =
          allShifts
              .where((s) => s.staffCode == staff.code)
              .toList(growable: false)
            ..sort((a, b) {
              final dateCompare = a.shiftDate.compareTo(b.shiftDate);

              if (dateCompare != 0) {
                return dateCompare;
              }

              return a.startTime.compareTo(b.startTime);
            });

      emit(
        state.copyWith(
          isLoadingSchedule: false,
          scheduleError: null,
          selectedStaff: staff,
          selectedProfile: profile,
          shifts: staffShifts,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingSchedule: false,
          scheduleError: 'Failed to load schedule.\nPlease try again.',
          shifts: const [],
        ),
      );
    }
  }

  /// =========================================================
  /// REFRESH
  /// =========================================================

  Future<void> refresh({DateTime? selectedDate, String? publishStatus}) async {
    await loadStaffList();

    final selectedStaff = state.selectedStaff;

    if (selectedStaff != null) {
      await loadStaffSchedule(
        selectedStaff,
        selectedDate: selectedDate,
        publishStatus: publishStatus,
      );
    }
  }

  /// =========================================================
  /// CLEAR
  /// =========================================================

  void clear() {
    emit(const StaffScheduleState());
  }
}
