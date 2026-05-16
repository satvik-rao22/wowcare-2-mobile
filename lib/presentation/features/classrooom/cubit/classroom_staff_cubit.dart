import 'package:bloc/bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';
import '../../../../domain/features/staff_classroom/usecases/get_staff_classrooms_usecase.dart';
import 'classroom_staff_state.dart';

class ClassroomStaffCubit extends Cubit<ClassroomStaffState> {
  ClassroomStaffCubit({
    required GetStaffClassroomsUseCase getStaffClassroomsUseCase,
    required StorageService storageService,
  }) : _getStaffClassroomsUseCase = getStaffClassroomsUseCase,
       _storageService = storageService,
       super(const ClassroomStaffState.initial());

  final GetStaffClassroomsUseCase _getStaffClassroomsUseCase;
  final StorageService _storageService;

  String? _lastSuccessfulStaffListKey;

  static String staffListRequestKey({
    required String classroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) {
    final st =
        List<String>.from(status ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final des =
        List<String>.from(designation ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    return [
      classroomCode.trim(),
      's=${(search ?? '').trim().toLowerCase()}',
      'st=${st.join(',')}',
      'des=${des.join(',')}',
    ].join('|');
  }

  Future<void> loadInitial({
    required String classroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) async {
    if (state.isLoading) return;

    final key = staffListRequestKey(
      classroomCode: classroomCode,
      search: search,
      status: status,
      designation: designation,
    );
    final preserve =
        key == _lastSuccessfulStaffListKey && state.staff.isNotEmpty;

    emit(
      state.copyWith(
        staff: preserve ? state.staff : [],
        isLoading: !preserve,
        isRefreshing: false,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final items = await _getStaffClassroomsUseCase(
        schoolCode: schoolCode,
        primaryClassroomCodes: [classroomCode],
        search: search,
        status: status,
        designation: designation,
        refresh: false,
      );

      if (isClosed) return;
      _lastSuccessfulStaffListKey = key;
      emit(
        state.copyWith(
          staff: items,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
          lastClassroomCode: classroomCode,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: e.toString(),
          lastClassroomCode: classroomCode,
        ),
      );
    }
  }

  Future<void> refresh({
    required String classroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) async {
    if (state.isRefreshing) return;

    final key = staffListRequestKey(
      classroomCode: classroomCode,
      search: search,
      status: status,
      designation: designation,
    );

    emit(
      state.copyWith(
        isRefreshing: true,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final items = await _getStaffClassroomsUseCase(
        schoolCode: schoolCode,
        primaryClassroomCodes: [classroomCode],
        search: search,
        status: status,
        designation: designation,
        refresh: true,
      );

      if (isClosed) return;
      _lastSuccessfulStaffListKey = key;
      emit(
        state.copyWith(
          staff: items,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
          lastClassroomCode: classroomCode,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: e.toString(),
          lastClassroomCode: classroomCode,
        ),
      );
    }
  }

  static List<StaffClassroomItem> applyClientFilters(
    List<StaffClassroomItem> staff, {
    String? searchText,
    List<String>? designation,
  }) {
    final q = (searchText ?? '').trim().toLowerCase();
    final des = (designation ?? [])
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    return staff.where((s) {
      if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q)) return false;
      if (des.isNotEmpty && !des.contains(s.designation.toUpperCase())) {
        return false;
      }
      return true;
    }).toList();
  }
}
