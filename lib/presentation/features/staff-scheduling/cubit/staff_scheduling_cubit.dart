import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/staff_model.dart';
import 'staff_scheduling_state.dart';

class StaffSchedulingCubit extends Cubit<StaffSchedulingState> {
  StaffSchedulingCubit() : super(StaffSchedulingInitial()) {
    loadInitialData();
  }

  void loadInitialData() {
    emit(StaffSchedulingLoaded(expandAll: false, staffList: _dummyData()));
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

  List<StaffModel> _dummyData() {
    return [
      StaffModel(
        name: "Vivek Pawar",
        image: "https://i.pravatar.cc/150?img=1",
        workedHours: 45,
        totalHours: 55,
        shift: "07:00 AM - 05:00 PM",
      ),
      StaffModel(
        name: "Divya Patil",
        image: "https://i.pravatar.cc/150?img=2",
        workedHours: 40,
        totalHours: 50,
        shift: "09:00 AM - 06:00 PM",
      ),
      StaffModel(
        name: "Preshita Koli",
        image: "https://i.pravatar.cc/150?img=2",
        workedHours: 40,
        totalHours: 50,
        shift: "09:00 AM - 06:00 PM",
      ),
      StaffModel(
        name: "Prathames Jaipal",
        image: "https://i.pravatar.cc/150?img=2",
        workedHours: 40,
        totalHours: 50,
        shift: "09:00 AM - 06:00 PM",
      ),
    ];
  }
}
