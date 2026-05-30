import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/student/usecases/get_tag_names_for_school_usecase.dart';

part 'reports_state.dart';

/// Owns the lookup data (classroom / student / staff / tag names) the report
/// forms need, so the reports screen no longer juggles these lists in
/// `setState`.
///
/// The classroom/student/staff names are fed in from their respective cubits
/// via [setClassroomNames] / [setStudentNames] / [setStaffNames]; tag names are
/// loaded directly here since no dedicated cubit owns them.
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({
    required StorageService storageService,
    required GetTagNamesForSchoolUseCase getTagNamesForSchoolUseCase,
  })  : _storageService = storageService,
        _getTagNamesForSchoolUseCase = getTagNamesForSchoolUseCase,
        super(const ReportsState.initial());

  final StorageService _storageService;
  final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase;

  /// Loads the school's tag names. Tags are optional metadata, so failures are
  /// swallowed and the rest of the screen keeps working.
  Future<void> loadTags() async {
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;
      final tags = await _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
      if (isClosed) return;
      emit(state.copyWith(tagNames: tags));
    } catch (_) {
      // Tags are optional; ignore failures.
    }
  }

  void setClassroomNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(classroomNames: names));
  }

  void setStudentNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(studentNames: names));
  }

  void setStaffNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(staffNames: names));
  }
}
