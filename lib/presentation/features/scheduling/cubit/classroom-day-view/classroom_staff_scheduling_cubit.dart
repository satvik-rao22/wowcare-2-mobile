import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../app/di/di.dart';
import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../../domain/features/staff_scheduling/usecases/get_staff_shifts_usecase.dart';
import '../../../../../domain/features/staff_scheduling/usecases/get_all_classrooms_usecase.dart';
import 'classroom_staff_scheduling_state.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/storage_keys.dart';
import 'package:intl/intl.dart';

class StaffSchedulingCubit extends Cubit<StaffSchedulingState> {
  final GetStaffShiftsUseCase _getStaffShifts;
  final GetAllClassroomsUseCase _getAllClassrooms;
  final StorageService _storageService;
  final StorageService _storage = serviceLocator<StorageService>();
  StaffSchedulingCubit(this._getStaffShifts, this._getAllClassrooms, this._storageService)
    : super(StaffSchedulingInitial()) {
    // Default to daily view and current date
    loadInitialData(date: DateTime.now(), isDaily: true);
  }

  void loadInitialData({DateTime? date, bool isDaily = false}) async {
    final targetDate = date ?? DateTime.now();

    emit(
      StaffSchedulingLoaded(
        expandAll: false,
        staffList: [],
        staffShifts: const [],
        isDailyView: isDaily,
        selectedDate: targetDate,
        isLoadingShifts: true, // Set loading to true when starting to load data
      ),
    );

    try {
      final schoolCode = await _storage.getString(StorageKeys.schoolCode) ?? '';
      final organizationCode =
          await _storage.getString(StorageKeys.organizationCode) ?? '';

      List<StaffShiftEntity> shifts = [];
      List<Map<String, dynamic>> classroomsRaw = [];

      String dateFrom;
      String dateTo;

      if (isDaily) {
        dateFrom = DateFormat('yyyy-MM-dd').format(targetDate);
        dateTo = dateFrom;
      } else {
        final selectedDate = DateFormat('yyyy-MM-dd').format(targetDate);

        dateFrom = selectedDate;
        dateTo = selectedDate;
      }

      try {
        shifts = await _getStaffShifts(
          dateFrom: dateFrom,
          dateTo: dateTo,
          schoolCode: schoolCode,
          organizationCode: organizationCode,
        );
      } catch (e) {
        print("Error fetching shifts: $e");
      }

      try {
        classroomsRaw = await _getAllClassrooms(schoolCode);
      } catch (e) {
        print("Error fetching classrooms: $e");
      }

      if (state is StaffSchedulingLoaded) {
        emit(
          (state as StaffSchedulingLoaded).copyWith(
            staffShifts: shifts,
            allClassrooms: classroomsRaw,
            isLoadingShifts: false,
          ),
        );
      }
    } catch (e) {
      print("Unexpected error in loadInitialData: $e");

      emit(
        StaffSchedulingLoaded(
          expandAll: false,
          staffList: [],
          staffShifts: const [],
          isDailyView: isDaily,
          selectedDate: targetDate,
          isLoadingShifts: false,
          allClassrooms: const [],
        ),
      );
    }
  }

  void changeDateAndMode({required DateTime date, required bool isDaily}) {
    if (state is StaffSchedulingLoaded) {
      emit(
        (state as StaffSchedulingLoaded).copyWith(
          selectedDate: date,
          isDailyView: isDaily,
          isLoadingShifts: false,
        ),
      );
    }
    loadInitialData(date: date, isDaily: isDaily);
  }

  void toggleCard(String id) {
    final current = state as StaffSchedulingLoaded;

    final updated = Map<String, bool>.from(current.expandedMap);
    updated[id] = !(updated[id] ?? false);

    emit(current.copyWith(expandedMap: updated));
  }

  void toggleMessage(String id, int index) {
    final current = state as StaffSchedulingLoaded;

    final updated = Map<String, int?>.from(current.activeMessageMap);

    if (updated[id] == index) {
      updated[id] = null;
    } else {
      updated[id] = index;
    }

    emit(current.copyWith(activeMessageMap: updated));
  }

  void closeMessage(String id) {
    final current = state as StaffSchedulingLoaded;

    final updated = Map<String, int?>.from(current.activeMessageMap);
    updated[id] = null;

    emit(current.copyWith(activeMessageMap: updated));
  }

  void toggleExpandAll() {
    final current = state as StaffSchedulingLoaded;
    emit(current.copyWith(expandAll: !current.expandAll));
  }

  void updateClassroom(String value) {
    final current = state as StaffSchedulingLoaded;
    emit(current.copyWith(selectedClassroom: value));
  }

  void updatePublish(String value) {
    final current = state as StaffSchedulingLoaded;
    emit(current.copyWith(selectedPublish: value));
  }
}
