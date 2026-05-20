import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/staff_scheduling/usecases/get_staff_shifts_usecase.dart';
import '../../../../../domain/features/staff_scheduling/usecases/get_all_classrooms_usecase.dart';
import 'classroom_day_schedule_state.dart';

class ClassroomScheduleCubit extends Cubit<ClassroomScheduleState> {
  final GetStaffShiftsUseCase _getStaffShifts;
  final GetAllClassroomsUseCase _getAllClassrooms;
  final StorageService _storageService;

  ClassroomScheduleCubit(this._getStaffShifts, this._getAllClassrooms, this._storageService)
    : super(ClassroomScheduleInitial());

  Future<void> fetchAllSchedules({required String date}) async {
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

      final classroomResponse = await _getAllClassrooms(storedSchoolCode);

      final shifts = await _getStaffShifts(
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
      }).where((c) => c.classroomCode.trim().isNotEmpty).toList();

      classrooms.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      emit(
        ClassroomScheduleLoaded(
          shifts: shifts,
          classrooms: classrooms,
          date: date,
          isLoadingShifts: false,
        ),
      );
    } catch (e) {
      emit(ClassroomScheduleError(e.toString()));
    }
  }

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

      final classroomResponse = await _getAllClassrooms(storedSchoolCode);

      final shifts = await _getStaffShifts(
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
