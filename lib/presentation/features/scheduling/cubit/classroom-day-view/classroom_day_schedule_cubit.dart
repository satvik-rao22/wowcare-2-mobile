import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import 'classroom_day_schedule_state.dart';

class ClassroomScheduleCubit extends Cubit<ClassroomScheduleState> {
  final StaffSchedulingRepository _repository;
  final StorageService _storageService;

  ClassroomScheduleCubit(this._repository, this._storageService)
    : super(ClassroomScheduleInitial());

  // Future<void> fetchSchedules({
  //   required String classroomCode,
  //   required String date,
  //   required String schoolCode,
  // }) async {
  //   emit(
  //     ClassroomScheduleLoaded(
  //       shifts: const [],
  //       classrooms: const [],
  //       date: date,
  //       isLoadingShifts: true,
  //     ),
  //   );

  //   try {
  //     final storedSchoolCode =
  //         await _storageService.getString(StorageKeys.schoolCode) ?? '';

  //     final organizationCode =
  //         await _storageService.getString(StorageKeys.organizationCode) ?? '';

  //     final classroomResponse = await _repository.getAllClassrooms(
  //       storedSchoolCode,
  //     );

  //     final shifts = await _repository.getStaffShifts(
  //       classroomCode: classroomCode,
  //       dateFrom: date,
  //       dateTo: date,
  //       schoolCode: storedSchoolCode,
  //       organizationCode: organizationCode,
  //     );

  //     final classrooms = classroomResponse.map((e) {
  //       return ClassroomEntity(
  //         classroomCode: e['classroomCode'] ?? '',
  //         name: e['classroomName'] ?? e['name'] ?? '',
  //         schoolCode: e['schoolCode'] ?? '',
  //       );
  //     }).toList();

  //     emit(
  //       ClassroomScheduleLoaded(
  //         shifts: shifts,
  //         classrooms: classrooms,
  //         date: date,
  //         isLoadingShifts: false,
  //       ),
  //     );
  //   } catch (e) {
  //     emit(ClassroomScheduleError(e.toString()));
  //   }
  // }

  Future<void> fetchSchedules({
    required String classroomCode,
    required String date,
    required String schoolCode,
  }) async {
    emit(
      ClassroomScheduleLoaded(
        shifts: const [],
        classrooms: const [],
        date: date,
        isLoadingShifts: true,
      ),
    );

    try {
      final storedSchoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final organizationCode =
          await _storageService.getString(StorageKeys.organizationCode) ?? '';

      final classroomResponse = await _repository.getAllClassrooms(
        storedSchoolCode,
      );

      final shifts = await _repository.getStaffShifts(
        classroomCode: classroomCode,
        dateFrom: date,
        dateTo: date,
        schoolCode: storedSchoolCode,
        organizationCode: organizationCode,
      );

      final classrooms = classroomResponse.map((e) {
        return ClassroomEntity(
          classroomCode: e['classroomCode'] ?? '',
          name: e['classroomName'] ?? e['name'] ?? '',
          schoolCode: e['schoolCode'] ?? '',
        );
      }).toList();

      /// SHOW SHIMMER IF DATA EMPTY
      if (shifts.isEmpty) {
        emit(
          ClassroomScheduleLoaded(
            shifts: const [],
            classrooms: classrooms,
            date: date,
            isLoadingShifts: true,
          ),
        );

        return;
      }

      emit(
        ClassroomScheduleLoaded(
          shifts: shifts,
          classrooms: classrooms,
          date: date,
          isLoadingShifts: false,
        ),
      );
    } catch (e) {
      /// KEEP SHIMMER ON ERROR
      emit(
        ClassroomScheduleLoaded(
          shifts: const [],
          classrooms: const [],
          date: date,
          isLoadingShifts: true,
        ),
      );
    }
  }
}
