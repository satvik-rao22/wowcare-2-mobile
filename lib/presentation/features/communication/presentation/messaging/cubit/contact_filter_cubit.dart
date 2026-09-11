import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/contact_filter_state.dart';

/// Holds a messaging tab's contact filter/search view-state (Mandate 2, Bucket
/// A → cubit), replacing `StaffMessagingTab`'s `setState` fields.
///
/// The tab still orchestrates the roster/conversation cubits (StaffCubit,
/// StudentCubit, CommunicationCubit) and the search request token itself; this
/// cubit only owns the filter/search view-state those drive.
class ContactFilterCubit extends Cubit<ContactFilterState> {
  ContactFilterCubit() : super(const ContactFilterState());

  void setIdentity({String? userCode, String? accountCode}) {
    emit(
      state.copyWith(
        currentUserCode: userCode ?? state.currentUserCode,
        currentAccountCode: accountCode ?? state.currentAccountCode,
      ),
    );
  }

  void setStaffContactCodes(Set<String> codes) =>
      emit(state.copyWith(allContactCodes: {...codes}));

  void setStudentContactNames(Set<String> names) =>
      emit(state.copyWith(allContactNames: {...names}));

  void setTagNameToCode(Map<String, String> map) =>
      emit(state.copyWith(tagNameToCode: map));

  void setSearchResults(List<Conversation>? results) {
    if (results == null) {
      emit(state.copyWith(clearSearchResults: true));
    } else {
      emit(state.copyWith(serverSearchResults: results));
    }
  }

  /// Apply the filter sheet's result wholesale, keeping the unread toggle in
  /// sync with the map's `Unread` entry.
  void setFilters(Map<String, List<String>> filters) {
    emit(
      state.copyWith(
        currentFilters: filters,
        showUnread: (filters['Unread'] ?? const []).isNotEmpty,
      ),
    );
  }

  /// Silently default the Classroom filter to the viewer's primary classroom.
  void setDefaultClassroom(String classroomName) {
    emit(
      state.copyWith(
        currentFilters: {
          ...state.currentFilters,
          'Classroom': [classroomName],
        },
      ),
    );
  }

  /// "Clear all" — reset to the Active-only default, drop the unread toggle
  /// and any active search.
  void clearFilters() {
    emit(
      state.copyWith(
        currentFilters: {
          'Status': ['Active'],
          'Unread': [],
        },
        showUnread: false,
        clearSearchResults: true,
      ),
    );
  }

  /// Toggle "Show only unread", mirrored into `currentFilters['Unread']`.
  void setShowUnread(bool value) {
    emit(
      state.copyWith(
        showUnread: value,
        currentFilters: {
          ...state.currentFilters,
          'Unread': value ? ['true'] : [],
        },
      ),
    );
  }
}
