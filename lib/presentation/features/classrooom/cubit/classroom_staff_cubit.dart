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
  })  : _getStaffClassroomsUseCase = getStaffClassroomsUseCase,
        _storageService = storageService,
        super(const ClassroomStaffState.initial());

  final GetStaffClassroomsUseCase _getStaffClassroomsUseCase;
  final StorageService _storageService;

  Future<void> loadInitial({
    required String classroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) async {
    if (state.isLoading) return;

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final items = await _getStaffClassroomsUseCase(
        schoolCode: schoolCode,
        classCodes: [classroomCode],
        search: search,
        status: status,
        designation: designation,
        refresh: false,
      );

      if (isClosed) return;
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
        classCodes: [classroomCode],
        search: search,
        status: status,
        designation: designation,
        refresh: true,
      );

      if (isClosed) return;
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

