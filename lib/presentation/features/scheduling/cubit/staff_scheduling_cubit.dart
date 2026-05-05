import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import '../model/staff_model.dart';
import 'staff_scheduling_state.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';

import 'package:intl/intl.dart';

class StaffSchedulingCubit extends Cubit<StaffSchedulingState> {
  final StaffSchedulingRepository _repository;
  final StorageService _storageService;

  StaffSchedulingCubit(this._repository, this._storageService)
    : super(StaffSchedulingInitial()) {
    // Default to daily view and current date
    loadInitialData(date: DateTime.now(), isDaily: true);
  }

  void loadInitialData({DateTime? date, bool isDaily = true}) async {
    final targetDate = date ?? DateTime.now();

    emit(
      StaffSchedulingLoaded(
        expandAll: false,
        staffList: [],
        staffShifts: const [],
        isDailyView: isDaily,
        selectedDate: targetDate,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      List<StaffShiftEntity> shifts = [];
      List<Map<String, dynamic>> classroomsRaw = [];

      String dateFrom;
      String dateTo;

      if (isDaily) {
        dateFrom = DateFormat('yyyy-MM-dd').format(targetDate);
        dateTo = dateFrom;
      } else {
        // Find Monday of the week
        final int daysToSubtract = targetDate.weekday - DateTime.monday;
        final DateTime monday = targetDate.subtract(
          Duration(days: daysToSubtract),
        );
        final DateTime sunday = monday.add(const Duration(days: 6));
        dateFrom = DateFormat('yyyy-MM-dd').format(monday);
        dateTo = DateFormat('yyyy-MM-dd').format(sunday);
      }

      try {
        shifts = await _repository.getStaffShifts(
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
      } catch (e) {
        print("Error fetching shifts: $e");
      }

      try {
        classroomsRaw = await _repository.getAllClassrooms(schoolCode);
      } catch (e) {
        print("Error fetching classrooms: $e");
      }

      if (state is StaffSchedulingLoaded) {
        emit(
          (state as StaffSchedulingLoaded).copyWith(
            staffShifts: shifts,
            allClassrooms: classroomsRaw,
          ),
        );
      }
    } catch (e) {
      print("Unexpected error in loadInitialData: $e");
    }
  }

  void changeDateAndMode({required DateTime date, required bool isDaily}) {
    if (state is StaffSchedulingLoaded) {
      emit(
        (state as StaffSchedulingLoaded).copyWith(
          selectedDate: date,
          isDailyView: isDaily,
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
