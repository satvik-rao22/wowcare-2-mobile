import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/check_invoice_recipients_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student.dart' as domain;
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';

import 'package:wowcare/presentation/features/billing/model/student_models.dart';

part 'select_students_state.dart';

/// Owns the billing select-students screen: loads ACTIVE students via the
/// student-overview API (default `firstName,asc` sort), populates the classroom
/// and tag filters from their APIs, and applies them server-side. Search is
/// client-side over the loaded page. Pure ViewModel — the screen only reads
/// [state] and calls these intents.
class SelectStudentsCubit extends Cubit<SelectStudentsState> {
  SelectStudentsCubit({
    required GetStudentPageUseCase getStudentPage,
    required GetActiveClassroomsUseCase getActiveClassrooms,
    required GetTagNameCodeMapForSchoolUseCase getTagNameCodeMap,
    required CheckInvoiceRecipientsUseCase checkRecipients,
    required StorageService storage,
  })  : _getStudentPage = getStudentPage,
        _getActiveClassrooms = getActiveClassrooms,
        _getTagNameCodeMap = getTagNameCodeMap,
        _checkRecipients = checkRecipients,
        _storage = storage,
        super(const SelectStudentsState.initial());

  final GetStudentPageUseCase _getStudentPage;
  final GetActiveClassroomsUseCase _getActiveClassrooms;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMap;
  final CheckInvoiceRecipientsUseCase _checkRecipients;
  final StorageService _storage;

  String _schoolCode = '';

  static const int _pageSize = 300;

  /// Monotonic fetch generation. Bumped whenever the student query changes (a
  /// filter setter that refetches, or a re-[initialize]) so a slower in-flight
  /// [_fetchStudents] response for an older filter can't overwrite a newer one.
  int _generation = 0;

  /// Loads filter options (classrooms + tags) then the ACTIVE student list.
  Future<void> initialize() async {
    _generation++;
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      _schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

      final List<Classroom> classrooms =
          await _getActiveClassrooms(schoolCode: _schoolCode);
      final Map<String, String> tagNameToCode =
          await _getTagNameCodeMap(schoolCode: _schoolCode);

      final classroomNameToCode = <String, String>{
        for (final c in classrooms)
          if (c.name.trim().isNotEmpty) c.name.trim(): c.code.trim(),
      };

      if (isClosed) return;
      emit(state.copyWith(
        classroomNames: classroomNameToCode.keys.toList(),
        classroomNameToCode: classroomNameToCode,
        tagNames: tagNameToCode.keys.toList()..sort(),
        tagNameToCode: tagNameToCode,
      ));

      await _fetchStudents();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  /// Re-fetches ACTIVE students for the current classroom/tag selection.
  Future<void> _fetchStudents() async {
    // Capture the current generation; an older filter's response is discarded
    // if a newer setter bumped the generation while this request was in flight.
    final gen = _generation;
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final classroomCodes = state.selectedClassroomNames
          .map((n) => state.classroomNameToCode[n])
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toList();
      final tagCodes = state.selectedTagNames
          .map((n) => state.tagNameToCode[n])
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toList();

      final result = await _getStudentPage(
        schoolCode: _schoolCode,
        status: state.selectedStatus.trim().toUpperCase(),
        classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
        tagCodes: tagCodes.isEmpty ? null : tagCodes,
        page: 0,
        size: _pageSize,
      );
      final all = result.items.map(_toBillingStudent).toList();

      // Drop any selections that are no longer in the filtered result.
      final presentCodes = all.map((s) => s.code).toSet();
      final keptSelection =
          state.selectedStudentCodes.where(presentCodes.contains).toSet();

      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        students: all,
        selectedStudentCodes: keptSelection,
        isLoading: false,
      ));
    } catch (e) {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  Student _toBillingStudent(domain.Student s) {
    final room = s.classroom.trim().isNotEmpty
        ? s.classroom.trim()
        : (s.primaryClassroomName ?? '').trim();
    return Student(
      code: s.code,
      fullName: s.fullName,
      photoUuid: s.code,
      photoAssetCode: s.profilePhotoAssetCode,
      roomName: room.isEmpty ? null : room,
      dob: s.dob,
      ageLabel: Student.ageLabelFromDob(s.dob),
      tags: <Tag>[
        for (var i = 0; i < s.tags.length; i++) Tag(id: i + 1, name: s.tags[i]),
      ],
    );
  }

  // ── Intents ────────────────────────────────────────────────────────────────

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  Future<void> setClassrooms(List<String> names) async {
    // A new filter supersedes any in-flight fetch for the previous selection.
    _generation++;
    emit(state.copyWith(selectedClassroomNames: names));
    await _fetchStudents();
  }

  Future<void> setTags(List<String> names) async {
    _generation++;
    emit(state.copyWith(selectedTagNames: names));
    await _fetchStudents();
  }

  /// Single-select status filter. Keeps the last picked value, falling back to
  /// 'Active' when cleared, then re-fetches.
  Future<void> setStatus(List<String> names) async {
    final status = names.isEmpty ? 'Active' : names.last;
    if (status == state.selectedStatus) return;
    _generation++;
    emit(state.copyWith(selectedStatus: status));
    await _fetchStudents();
  }

  Future<void> clearAll() async {
    _generation++;
    emit(state.copyWith(
      searchQuery: '',
      selectedClassroomNames: const <String>[],
      selectedTagNames: const <String>[],
      selectedStatus: 'Active',
      selectedStudentCodes: const <String>{},
    ));
    await _fetchStudents();
  }

  void toggleStudent(String code) {
    final codes = Set<String>.from(state.selectedStudentCodes);
    if (!codes.add(code)) codes.remove(code);
    emit(state.copyWith(selectedStudentCodes: codes));
  }

  void setStudentSelected(String code, bool selected) {
    final codes = Set<String>.from(state.selectedStudentCodes);
    if (selected) {
      codes.add(code);
    } else {
      codes.remove(code);
    }
    emit(state.copyWith(selectedStudentCodes: codes));
  }

  /// Selects/clears every code in [codes] (the currently visible rows).
  void setAllSelected(Iterable<String> codes, bool selected) {
    final set = Set<String>.from(state.selectedStudentCodes);
    if (selected) {
      set.addAll(codes);
    } else {
      set.removeAll(codes);
    }
    emit(state.copyWith(selectedStudentCodes: set));
  }

  List<Student> get selectedStudents => state.students
      .where((s) => state.selectedStudentCodes.contains(s.code))
      .toList();

  /// Runs on "Next": confirms every selected student can actually receive an
  /// invoice (has a family/billing profile). Returns null on failure —
  /// [state.errorMessage] carries the reason and the caller should not
  /// navigate forward.
  Future<CheckRecipientsResultEntity?> checkRecipients(
    List<String> studentCodes,
  ) async {
    emit(state.copyWith(isCheckingRecipients: true, errorMessage: null));
    try {
      final result = await _checkRecipients(
        schoolCode: _schoolCode,
        studentCodes: studentCodes,
      );
      if (isClosed) return null;
      emit(state.copyWith(isCheckingRecipients: false));
      return result;
    } catch (e) {
      if (isClosed) return null;
      emit(state.copyWith(
        isCheckingRecipients: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return null;
    }
  }
}
