import 'package:bloc/bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';

/// Turns a classroom CODE into its display NAME for the staff profile screen
/// and its Profile tab.
///
/// Both used to call [GetClassroomByCodeUseCase] (and, in the screen's case,
/// [GetActiveClassroomsUseCase] plus a [StorageService] read for the school
/// code) straight from their `State` — a view reaching past its cubit into
/// use cases and storage. The two lookup strategies differ, so both are kept
/// verbatim here rather than merged: changing which endpoints a screen hits is
/// not a refactor.
///
/// Stateless by design (`Cubit<void>`): callers already hold the resolved names
/// in their own widget state and only need the fetch.
class StaffClassroomNameCubit extends Cubit<void> {
  StaffClassroomNameCubit({
    required GetClassroomByCodeUseCase getClassroomByCodeUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StorageService storageService,
  }) : _getClassroomByCodeUseCase = getClassroomByCodeUseCase,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _storageService = storageService,
       super(null);

  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StorageService _storageService;

  /// Direct by-code lookup. Returns the trimmed name, or null when the backend
  /// has no name for it. Errors propagate — callers keep showing the raw code.
  Future<String?> fetchNameByCode(String code) async {
    final details = await _getClassroomByCodeUseCase(code: code);
    final name = details.name.trim();
    return name.isEmpty ? null : name;
  }

  /// Active-classrooms list first (fast, backend-cached), falling back to the
  /// by-code lookup — which works even for a classroom that is not active.
  Future<String?> resolveNameForActiveSchool(String code) async {
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isNotEmpty) {
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      for (final classroom in classrooms) {
        if (classroom.code.trim() == code) {
          final name = classroom.name.trim();
          // A match with a blank name stops the list search but still falls
          // through to the by-code lookup, exactly as before.
          if (name.isNotEmpty) return name;
          break;
        }
      }
    }
    return fetchNameByCode(code);
  }
}
