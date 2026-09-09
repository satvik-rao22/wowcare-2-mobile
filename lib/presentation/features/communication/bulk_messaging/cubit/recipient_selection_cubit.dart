import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/cubit/recipient_selection_state.dart';

/// Holds the bulk-messaging recipient picker's selection + filter state
/// (Mandate 2, Bucket A → cubit), replacing the screen's `setState` fields.
///
/// Cross-cubit orchestration (paging `StaffCubit`/`StudentCubit` for
/// "Select All", pushing filters to those cubits) stays in the view; this
/// cubit only owns the picker's own selections and hands their results back.
class RecipientSelectionCubit extends Cubit<RecipientSelectionState> {
  RecipientSelectionCubit() : super(const RecipientSelectionState());

  void setCurrentStaffCode(String code) =>
      emit(state.copyWith(currentStaffCode: code));

  /// Set the loaded tag options + name→code map, pruning any selected tag no
  /// longer offered.
  void setTagData(List<String> options, Map<String, String> nameToCode) {
    emit(
      state.copyWith(
        tagOptions: options,
        tagNameToCode: nameToCode,
        selectedTags: state.selectedTags
            .where(options.contains)
            .toList(growable: false),
      ),
    );
  }

  void setClassrooms(List<String> classrooms) =>
      emit(state.copyWith(selectedClassrooms: classrooms));

  void setDesignations(List<String> designations) =>
      emit(state.copyWith(selectedDesignations: designations));

  void setTags(List<String> tags) => emit(state.copyWith(selectedTags: tags));

  /// Change the status filter. Clears the picked recipients — a status switch
  /// changes which roster is shown, so old picks no longer apply.
  void setStatus(String? status) {
    emit(
      state.copyWith(
        selectedStatus: status,
        clearStatus: status == null,
        selectedStaffCodes: const {},
        selectedStudentCodes: const {},
      ),
    );
  }

  /// "Clear all" chip — resets classroom/designation/tag filters, restores the
  /// default Active status, and drops every pick.
  void clearAll() {
    emit(
      state.copyWith(
        selectedClassrooms: const [],
        selectedDesignations: const [],
        selectedTags: const [],
        selectedStatus: 'Active',
        selectedStaffCodes: const {},
        selectedStudentCodes: const {},
      ),
    );
  }

  void setSelectingAll(bool value) =>
      emit(state.copyWith(isSelectingAll: value));

  /// Replace the staff selection (used by "Select All" / "clear all" for the
  /// staff picker).
  void setStaffSelection(Set<String> codes) =>
      emit(state.copyWith(selectedStaffCodes: {...codes}));

  /// Replace the student selection.
  void setStudentSelection(Set<String> codes) =>
      emit(state.copyWith(selectedStudentCodes: {...codes}));

  /// Toggle one staff recipient on/off.
  void toggleStaff(String code, bool selected) {
    final next = {...state.selectedStaffCodes};
    selected ? next.add(code) : next.remove(code);
    emit(state.copyWith(selectedStaffCodes: next));
  }

  /// Toggle one student recipient on/off.
  void toggleStudent(String code, bool selected) {
    final next = {...state.selectedStudentCodes};
    selected ? next.add(code) : next.remove(code);
    emit(state.copyWith(selectedStudentCodes: next));
  }
}
